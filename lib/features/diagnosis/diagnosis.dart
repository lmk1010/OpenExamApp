import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/tips/tips.dart';
import 'package:openexam_app/l10n/app_localizations.dart';

/// 弱点诊断。
///
/// 这一页的结论**不依赖 AI**。行测的每个模块该给多少秒、该拿多少正确率、
/// 在卷面上占多大比重，是从 161 套真题里数出来的固定值（见 [tips.dart]）；
/// 拿你的作答记录去比这套基准，本地就能得出「资料分析每题比基准慢 21 秒，
/// 一套卷要多花 7 分钟」这种结论。AI 是加在上面的一层解读，不是结论本身 ——
/// 没配 AI 的人看到的东西一样完整。
///
/// 同一套引擎有两个入口：整段历史（[Diagnosis.fromHistory]）和单次成卷
/// （[Diagnosis.fromReport]）。

enum FindingLevel { good, watch, bad }

/// 一条结论。三段固定：判断、证据、动作 —— 缺了动作的诊断没有用。
class Finding {
  const Finding({
    required this.level,
    required this.title,
    required this.evidence,
    required this.action,
    this.category = '',
  });

  final FindingLevel level;

  /// 结论，一句话。
  final String title;

  /// 支撑它的数字。
  final String evidence;

  /// 接下来做什么。
  final String action;

  /// 归属模块，空表示是全卷层面的。
  final String category;
}

/// 一个模块的实测 vs 基准。
class ModuleLine {
  const ModuleLine({
    required this.category,
    required this.attempts,
    required this.correct,
    required this.seconds,
    required this.benchSeconds,
    required this.targetAccuracy,
  });

  final String category;
  final int attempts;
  final int correct;

  /// 实测平均每题秒数。0 表示没有记到用时。
  final int seconds;
  final int benchSeconds;
  final double targetAccuracy;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  bool get timed => seconds > 0;

  /// 比基准慢多少（秒）。负数是快。
  int get drift => seconds - benchSeconds;
}

/// 每个模块的基准。
///
/// 秒数是 [kTipGroups] 里那套时间分配除以题量得来的，跟「解题技巧」页面上
/// 显示的是同一个数 —— 两处对不上会让人不知道该信哪个。
class Benchmark {
  const Benchmark({
    required this.category,
    required this.seconds,
    required this.target,
    required this.share,
  });

  final String category;

  /// 建议单题秒数。
  final int seconds;

  /// 目标正确率。
  final double target;

  /// 这个模块在卷面上占的题量比重。
  final double share;

  static final Map<String, Benchmark> all = _build();

  static Map<String, Benchmark> _build() {
    // 目标正确率是备考里通行的档位，不是从真题里数出来的 —— 常识靠积累、
    // 数量本来就打算放掉一半，两者的合格线本来就不该跟资料分析一样。
    const targets = <String, double>{
      'changshi': 0.55,
      'yanyu': 0.75,
      'shuliang': 0.50,
      'panduan': 0.75,
      'ziliao': 0.85,
    };
    final total = kTipGroups.fold<int>(0, (s, g) => s + g.anhui.count);
    return {
      for (final g in kTipGroups)
        g.category: Benchmark(
          category: g.category,
          // 数量关系的打法是挑着做，用「13 分钟 ÷ 15 题」当单题基准会
          // 逼着人每题都做。这里用的是单题的止损线：90 秒没思路就该走。
          seconds: g.category == 'shuliang'
              ? 90
              : (g.minutes * 60 / g.anhui.count).round(),
          target: targets[g.category] ?? 0.7,
          share: g.anhui.count / total,
        ),
    };
  }

  static Benchmark? of(String category) => all[category];
}

class Diagnosis {
  const Diagnosis({
    required this.scopeLabel,
    required this.headline,
    required this.modules,
    required this.findings,
    required this.attempts,
    required this.correct,
    this.note = '',
    this.benchmarked = true,
  });

  /// 诊断的是哪一段记录。
  final String scopeLabel;

  /// 一句总结，放在最上面。
  final String headline;

  final List<ModuleLine> modules;
  final List<Finding> findings;
  final int attempts;
  final int correct;

  /// 样本不足之类的提醒。
  final String note;

  /// 这个题库的分类能不能对上基准。
  ///
  /// 基准是按行测五模块定的。换一门考试（医师、教师编、导进来的任意题库），
  /// 分类对不上，[modules] 就是空的 —— 而空的 findings 会让页面显示
  /// 「各模块都在基准附近，没有短板」。那是句假话：一条都没查。
  final bool benchmarked;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  bool get thin => attempts < 30;

  /// 整段作答记录。
  /// [l] 是界面文案。这一层是纯模型、没有 BuildContext，所以由调用方
  /// （诊断页）把它传进来；测试直接 new 一个 AppLZh() 就能继续断言中文。
  factory Diagnosis.fromHistory(AppL l, DiagnosisData d) {
    final modules = <ModuleLine>[];
    for (final s in d.byCategory) {
      final b = Benchmark.of(s.key);
      if (b == null) continue;
      modules.add(ModuleLine(
        category: s.key,
        attempts: s.attempts,
        correct: s.correct,
        seconds: s.avgSeconds,
        benchSeconds: b.seconds,
        targetAccuracy: b.target,
      ));
    }
    modules.sort((a, b) => b.attempts.compareTo(a.attempts));

    final findings = <Finding>[
      ..._moduleFindings(l, modules),
      ..._historyFindings(l, d, modules),
    ];
    _rank(findings);

    return Diagnosis(
      scopeLabel: l.dxScopeAll,
      headline: _headline(l, d.attempts, d.correct, findings),
      modules: modules,
      findings: findings,
      attempts: d.attempts,
      correct: d.correct,
      benchmarked: modules.isNotEmpty,
      note: d.attempts < 30 ? l.dxThinSample(d.attempts) : '',
    );
  }

  /// 单次成卷。[timings] 是逐题用时，[questions] 是这份卷子的题。
  factory Diagnosis.fromReport({
    required AppL l,
    required String title,
    required List<Question> questions,
    required Map<String, String> answers,
    required Map<String, ({bool correct, int seconds})> timings,
    required Duration elapsed,
  }) {
    final byCat = <String, ({int n, int correct, int secs, int timed, int blank})>{};
    for (final q in questions) {
      final b = Benchmark.of(q.category);
      if (b == null) continue;
      final t = timings[q.id];
      final answered = (answers[q.id] ?? '').isNotEmpty;
      final cur = byCat[q.category] ??
          (n: 0, correct: 0, secs: 0, timed: 0, blank: 0);
      byCat[q.category] = (
        n: cur.n + 1,
        correct: cur.correct + ((t?.correct ?? false) ? 1 : 0),
        secs: cur.secs + (t?.seconds ?? 0),
        timed: cur.timed + ((t?.seconds ?? 0) > 0 ? 1 : 0),
        blank: cur.blank + (answered ? 0 : 1),
      );
    }

    final modules = <ModuleLine>[];
    for (final e in byCat.entries) {
      final b = Benchmark.of(e.key)!;
      modules.add(ModuleLine(
        category: e.key,
        attempts: e.value.n,
        correct: e.value.correct,
        seconds: e.value.timed == 0 ? 0 : (e.value.secs / e.value.timed).round(),
        benchSeconds: b.seconds,
        targetAccuracy: b.target,
      ));
    }
    modules.sort((a, b) => b.attempts.compareTo(a.attempts));

    final total = questions.length;
    final correct = modules.fold<int>(0, (s, m) => s + m.correct);
    final findings = <Finding>[
      ..._moduleFindings(l, modules),
      ..._reportFindings(l, byCat, modules, elapsed, total),
    ];
    _rank(findings);

    return Diagnosis(
      scopeLabel: title,
      headline: _headline(l, total, correct, findings),
      modules: modules,
      findings: findings,
      attempts: total,
      correct: correct,
      benchmarked: modules.isNotEmpty,
    );
  }

  // ------------------------------------------------------------------ 规则

  /// 逐模块：慢不慢、准不准。
  static List<Finding> _moduleFindings(AppL l, List<ModuleLine> modules) {
    final out = <Finding>[];
    for (final m in modules) {
      // 少于 8 题的模块不下结论 —— 三道题的正确率是噪声。
      if (m.attempts < 8) continue;
      final label = categoryLabel(m.category);

      if (m.timed) {
        final ratio = m.seconds / m.benchSeconds;
        if (ratio >= 1.25) {
          final over = m.drift * m.attempts ~/ 60;
          out.add(Finding(
            level: FindingLevel.bad,
            category: m.category,
            title: l.dxSlowTitle(label),
            evidence: l.dxSlowEvidence(
                  m.seconds,
                  m.benchSeconds,
                  ((ratio - 1) * 100).round(),
                ) +
                (over > 0 ? l.dxSlowOverrun(over) : ''),
            action: _paceAction(m.category),
          ));
        } else if (ratio >= 1.1) {
          out.add(Finding(
            level: FindingLevel.watch,
            category: m.category,
            title: l.dxSlightlySlowTitle(label),
            evidence: l.dxPaceEvidence(m.seconds, m.benchSeconds),
            action: l.dxSlightlySlowAction(m.benchSeconds),
          ));
        } else if (ratio <= 0.9 && m.accuracy >= m.targetAccuracy) {
          out.add(Finding(
            level: FindingLevel.good,
            category: m.category,
            title: l.dxFastSteadyTitle(label),
            evidence: l.dxFastSteadyEvidence(
              m.seconds,
              m.benchSeconds,
              _pct(m.accuracy),
            ),
            action: l.dxFastSteadyAction,
          ));
        }
      }

      final gap = m.targetAccuracy - m.accuracy;
      // 比基准快、正确率却塌了 —— 这是赶工，不是"这块不熟"。
      // 两者的处方正好相反：前者要踩刹车，后者要补方法。分不出来的话，
      // 页面会告诉一个正在抢时间的人去"练方法"，越练越快、越快越错。
      final rushing = m.timed &&
          m.seconds <= m.benchSeconds * 0.9 &&
          gap >= 0.1;
      if (rushing) {
        out.add(Finding(
          level: FindingLevel.bad,
          category: m.category,
          title: l.dxRushTitle(label),
          evidence: l.dxRushEvidence(
            m.seconds,
            m.benchSeconds,
            ((1 - m.seconds / m.benchSeconds) * 100).round(),
            _pct(m.accuracy),
            _pct(m.targetAccuracy),
          ),
          action: l.dxRushAction(
            m.benchSeconds,
            _pct(m.targetAccuracy),
            _rushAction(m.category),
          ),
        ));
      } else if (gap >= 0.15) {
        out.add(Finding(
          level: FindingLevel.bad,
          category: m.category,
          title: l.dxAccuracyGapTitle(label),
          evidence: l.dxAccuracyGapEvidence(
            _pct(m.accuracy),
            m.correct,
            m.attempts,
            _pct(m.targetAccuracy),
          ),
          action: _accuracyAction(m.category),
        ));
      } else if (gap >= 0.05) {
        out.add(Finding(
          level: FindingLevel.watch,
          category: m.category,
          title: l.dxAlmostTitle(label),
          evidence: l.dxAlmostEvidence(
            _pct(m.accuracy),
            _pct(m.targetAccuracy),
          ),
          action: l.dxAlmostAction,
        ));
      }
    }
    return out;
  }

  /// 整段历史特有的：时间花在哪、错题消没消、有没有在进步。
  static List<Finding> _historyFindings(
    AppL l,
    DiagnosisData d,
    List<ModuleLine> modules,
  ) {
    final out = <Finding>[];
    if (d.attempts < 20) return out;

    // 时间去哪了。数量关系是最容易吃掉时间又不产分的地方。
    final totalSecs = modules.fold<int>(
      0,
      (s, m) => s + (m.timed ? m.seconds * m.attempts : 0),
    );
    if (totalSecs > 0) {
      for (final m in modules) {
        if (!m.timed || m.attempts < 8) continue;
        final b = Benchmark.of(m.category)!;
        final share = m.seconds * m.attempts / totalSecs;
        if (m.category == 'shuliang' && share > 0.22) {
          out.add(Finding(
            level: FindingLevel.bad,
            category: m.category,
            title: l.dxTimeSinkTitle,
            evidence: l.dxTimeSinkEvidence(_pct(share), _pct(b.share)),
            action: _paceAction('shuliang'),
          ));
        }
        if (m.category == 'changshi' && m.seconds > 28) {
          out.add(Finding(
            level: FindingLevel.bad,
            category: m.category,
            title: l.dxOverthinkTitle,
            evidence: l.dxPaceEvidence(m.seconds, b.seconds),
            action: _paceAction('changshi'),
          ));
        }
      }
    }

    // 练得够不够均衡。
    final done = modules.fold<int>(0, (s, m) => s + m.attempts);
    for (final m in modules) {
      final b = Benchmark.of(m.category)!;
      final share = done == 0 ? 0.0 : m.attempts / done;
      if (m.category == 'ziliao' && share < b.share * 0.6 && done > 100) {
        out.add(Finding(
          level: FindingLevel.watch,
          category: m.category,
          title: l.dxThinPracticeTitle,
          evidence: l.dxThinPracticeEvidence(_pct(share), _pct(b.share)),
          action: _accuracyAction('ziliao'),
        ));
      }
    }

    // 错题有没有真的消掉。
    if (d.wrongTotal >= 10) {
      final repeatShare = d.repeatWrong / d.wrongTotal;
      if (repeatShare >= 0.3) {
        out.add(Finding(
          level: FindingLevel.bad,
          title: l.dxRepeatTitle,
          evidence: l.dxRepeatEvidence(
            d.wrongTotal,
            d.repeatWrong,
            _pct(repeatShare),
          ),
          action: l.dxRepeatAction,
        ));
      }
    }

    // 错因没标，后面所有按错因的复盘都用不了。
    final tagged = d.byReason.entries
        .where((e) => e.key != '_none')
        .fold<int>(0, (s, e) => s + e.value);
    if (d.wrongTotal >= 20 && tagged / d.wrongTotal < 0.4) {
      out.add(Finding(
        level: FindingLevel.watch,
        title: l.dxUntaggedTitle,
        evidence: l.dxUntaggedEvidence(d.wrongTotal, tagged),
        action: l.dxUntaggedAction,
      ));
    }

    // 在不在进步。
    if (d.recent.attempts >= 20 && d.earlier.attempts >= 20) {
      final delta = d.recent.accuracy - d.earlier.accuracy;
      if (delta >= 0.05) {
        out.add(Finding(
          level: FindingLevel.good,
          title: l.dxTrendUpTitle,
          evidence: l.dxTrendEvidence(
            _pct(d.recent.accuracy),
            _pct(d.earlier.accuracy),
          ),
          action: l.dxTrendUpAction,
        ));
      } else if (delta <= -0.05) {
        out.add(Finding(
          level: FindingLevel.watch,
          title: l.dxTrendDownTitle,
          evidence: l.dxTrendEvidence(
            _pct(d.recent.accuracy),
            _pct(d.earlier.accuracy),
          ),
          action: l.dxTrendDownAction,
        ));
      }
    }

    return out;
  }

  /// 单次成卷特有的：有没有做完、时间怎么分的。
  static List<Finding> _reportFindings(
    AppL l,
    Map<String, ({int n, int correct, int secs, int timed, int blank})> byCat,
    List<ModuleLine> modules,
    Duration elapsed,
    int total,
  ) {
    final out = <Finding>[];

    final blank = byCat.values.fold<int>(0, (s, v) => s + v.blank);
    if (blank > 0) {
      // 空在最后一块的，是时间没分好；散在各处的，是主动放弃。
      final tail = byCat['ziliao']?.blank ?? 0;
      out.add(Finding(
        level: blank > total * 0.1 ? FindingLevel.bad : FindingLevel.watch,
        title: tail >= blank * 0.5 && tail > 0
            ? l.dxTailBlankTitle
            : l.dxBlankTitle(blank),
        evidence: tail > 0
            ? l.dxBlankWithTail(blank, tail)
            : l.dxBlankOnly(blank),
        action: tail > 0 ? l.dxTailBlankAction : l.dxBlankAction,
      ));
    }

    // 时间分配：跟基准比，谁超支了。
    final budget = modules.fold<int>(
      0,
      (s, m) => s + m.benchSeconds * m.attempts,
    );
    if (budget > 0 && elapsed.inSeconds > 0) {
      final ratio = elapsed.inSeconds / budget;
      if (ratio >= 1.15) {
        out.add(Finding(
          level: FindingLevel.bad,
          title: l.dxOvertimeTitle,
          evidence: l.dxOvertimeEvidence(
            elapsed.inMinutes,
            (budget / 60).round(),
          ),
          action: l.dxOvertimeAction,
        ));
      } else if (ratio <= 0.85) {
        out.add(Finding(
          level: FindingLevel.good,
          title: l.dxUnderTimeTitle,
          evidence: l.dxUnderTimeEvidence(
            elapsed.inMinutes,
            (budget / 60).round(),
          ),
          action: l.dxUnderTimeAction,
        ));
      }
    }

    return out;
  }

  // ------------------------------------------------------------------ 文案

  // ---- 以下三个是行测专属的处方，**刻意保持中文** ----
  //
  // 它们只在 Benchmark.of(category) 认得的模块上触发，也就是只在行测题库下
  // 出现。「逻辑填空练搭配不背释义」「图推最多 90 秒」这种话翻成英文给谁看
  // 都没用 —— 它是考试内容，不是界面文案，该跟着题库走。

  static String _paceAction(String category) => switch (category) {
        'changshi' => '常识每题 16 秒一遍过，不回头。这个模块多想没有用。',
        'yanyu' => '逻辑填空 45 秒、片段阅读 60 秒卡表。片段阅读先看问法再回读，'
            '别通读。',
        'shuliang' => '90 秒没思路就停手。已经投进去的时间是沉没成本，'
            '停手的判断力比解题能力值钱。',
        'panduan' => '按类比 → 定义 → 逻辑 → 图推的顺序做。类比 25 秒一道，'
            '图推最多 90 秒，超时就弃。',
        'ziliao' => '先看 5 个设问再回材料找数，不要通读；估算到能分辨选项就停手，'
            '别硬算。',
        _ => '按基准秒数卡表练，超时就跳。',
      };

  /// 赶工时该慢在哪一步 —— 每个模块被抢掉的都是不同的那一步。
  static String _rushAction(String category) => switch (category) {
        'changshi' => '常识本来就该快，快还错说明是在猜。'
            '与其猜，不如把不会的直接标记跳过，省下的注意力留给会做的。',
        'yanyu' => '多半是丢了回读那一步：逻辑填空没验第二空的搭配，'
            '片段阅读没回原文核对就凭印象选。这两步各花 10 秒，能换回大半的分。',
        'shuliang' => '数量快而错，通常是列式前没读完条件。'
            '与其快着做十道错八道，不如慢着挑五道全做对。',
        'panduan' => '定义判断没把要件拆完就比选项，逻辑判断没翻译就凭语感 ——'
            '这两处各慢 15 秒，正确率能差出一大截。',
        'ziliao' => '资料分析快而错基本是三件事：看错时间、看错单位、'
            '把"比重"当成"增长率"。每题回头核一眼题干里的这三样。',
        _ => '慢下来的那几秒，花在回头核对题干上。',
      };

  static String _accuracyAction(String category) => switch (category) {
        'changshi' => '常识拉不动就别硬拉：把时间换成每天 15 分钟时政，'
            '真题只做近一年的。旧常识题的答案已经作废了。',
        'yanyu' => '逻辑填空练搭配不背释义；片段阅读的错项就四类 —— 范围扩大、'
            '程度加重、偷换主体、无中生有，逐题对号入座。',
        'shuliang' => '正确率低不一定是坏事，关键看你有没有挑对题。'
            '先练「10 秒判断做不做」，再补最值构造和几何这两类。',
        'panduan' => '定义判断拆主体/行为/条件三要素；逻辑判断先翻译再推，'
            '别用生活经验。',
        'ziliao' => '资料分析错题不该是粗心。逐题分清是公式记错、算错，'
            '还是时间/单位/总量/百分比看错 —— 栽跟头基本都在这四个地方。',
        _ => '按错因分类翻一遍这个模块的错题。',
      };

  static String _headline(
    AppL l,
    int attempts,
    int correct,
    List<Finding> findings,
  ) {
    if (attempts == 0) return l.dxNoRecords;
    final bad = findings.where((f) => f.level == FindingLevel.bad).toList();
    final acc = _pct(correct / attempts);
    if (bad.isEmpty) return l.dxHeadlineClean(attempts, acc);
    // 有模块归属就报模块名，全卷层面的结论直接报它的标题。
    final what = bad.first.category.isEmpty
        ? bad.first.title
        : categoryLabel(bad.first.category);
    return l.dxHeadlineWorst(attempts, acc, what);
  }

  static void _rank(List<Finding> findings) {
    const order = {
      FindingLevel.bad: 0,
      FindingLevel.watch: 1,
      FindingLevel.good: 2,
    };
    findings.sort((a, b) => order[a.level]!.compareTo(order[b.level]!));
  }

  static String _pct(double v) => '${(v * 100).round()}%';

  /// 送给模型的那份摘要。只有聚合数字和结论，没有原始做题记录。
  String toPrompt() {
    final b = StringBuffer()
      ..writeln('诊断对象：$scopeLabel')
      ..writeln('总体：$attempts 题，正确率 ${_pct(accuracy)}')
      ..writeln()
      ..writeln('各模块（实测 vs 真题基准）：');
    for (final m in modules) {
      b.writeln('- ${categoryLabel(m.category)}：'
          '${m.attempts} 题，正确率 ${_pct(m.accuracy)}'
          '（目标 ${_pct(m.targetAccuracy)}）'
          '${m.timed ? '，每题 ${m.seconds} 秒（基准 ${m.benchSeconds} 秒）' : '，无用时记录'}');
    }
    b
      ..writeln()
      ..writeln('本地已经算出的结论：');
    for (final f in findings) {
      final tag = switch (f.level) {
        FindingLevel.bad => '严重',
        FindingLevel.watch => '注意',
        FindingLevel.good => '良好',
      };
      b.writeln('- [$tag] ${f.title} —— ${f.evidence}');
    }
    return b.toString();
  }
}

/// 系统提示。把真题结构写进去，模型才不会给出「多刷题、多总结」这种废话。
const kDiagnosisSystem = '''
你是行测备考教练，面对的是安徽省考和国考的考生。

你已知的真题事实（来自 161 套真题逐题统计，不要跟它冲突）：
- 安徽 2026 卷 125 题 120 分钟：常识 30（第 1—30 题）、数量 15（31—45）、
  言语 25（46—70）、判断 35（71—105）、资料 20（106—125）。
- 国考 2025 年起大改：常识 20→35、言语 40→30、类比推理 10→5。安徽 2025 年起
  常识 20→30、资料 15→20，言语/数量/判断四年未动。
- 安徽判断内部固定为 图推 5 / 定义 10 / 类比 10 / 逻辑 10；国考是图推 10 / 类比 5，
  正好相反。
- 常识里一半是政治，且多为考前一年的讲话原文与新政策，旧题答案已作废；
  法律题两年内从 4 道降到 1 道。
- 资料分析恒定 4 篇 × 5 题，八成题带图表，是唯一「练到位就能拿满」的模块。
- 单题时间基准：常识 16 秒、言语 55 秒、判断 50 秒、资料 81 秒；
  数量关系的打法是挑着做，单题 90 秒止损，全卷只挑 5—7 道。
- 近三年真题 A/B/C/D 各占 23%—26%，没有可蒙的偏向选项。

要求：
1. 用户给你的是**已经算好的统计和结论**，不要重复罗列这些数字，也不要
   重新算一遍。你要做的是把它们串成因果：哪个问题是根，哪些只是它的表现。
2. 给出一周的具体训练安排，写清每天练什么模块、多少题、卡多少秒。
3. 直说，不要客套和鼓励式套话。不确定的地方说不确定。
4. 中文，600 字以内，用小标题分段，不要用 Markdown 表格。
''';
