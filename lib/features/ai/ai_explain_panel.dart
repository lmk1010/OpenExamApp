import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/ai/ai_explain_service.dart';
import 'package:openexam_app/features/ai/ai_thinking.dart';

/// 出题人视角的讲解。
///
/// 题库自带的解析常常只是把正确答案又说了一遍，遇到"没意义的解析"就等于没有。
/// 这一栏让配了 AI 的人点一下，听一段真正讲思路的：这题在考什么、几个干扰项
/// 分别拿什么骗人、你选的那个错在哪。
///
/// 讲完落库（[AppDatabase.saveAiExplanation]）—— 同一道题回看多次很常见，
/// 每次都重新问一遍既慢又烧钱。
class AiExplainPanel extends StatefulWidget {
  const AiExplainPanel({
    super.key,
    required this.question,
    this.userAnswer,
  });

  final Question question;

  /// 考生这次选的，用来针对性地说他踩了哪个坑。没作答就是 null。
  final String? userAnswer;

  @override
  State<AiExplainPanel> createState() => _AiExplainPanelState();
}

class _AiExplainPanelState extends State<AiExplainPanel> {
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant AiExplainPanel old) {
    super.didUpdateWidget(old);
    // 翻到下一题时 State 会被复用，重新去认领新那道题的状态
    if (old.question.id != widget.question.id) _init();
  }

  Future<void> _init() async {
    final settings = await AiSettingsStore.load();
    await AiExplainService.instance.hydrate(widget.question.id);
    if (!mounted) return;
    setState(() => _configured = settings.isConfigured);
  }

  void _ask({bool again = false}) {
    final args = (
      question: widget.question,
      userAnswer: widget.userAnswer,
      system: _system,
      prompt: _promptFor(widget.question, widget.userAnswer),
    );
    if (again) {
      AiExplainService.instance.regenerate(
        question: args.question,
        userAnswer: args.userAnswer,
        system: args.system,
        prompt: args.prompt,
      );
    } else {
      AiExplainService.instance.start(
        question: args.question,
        userAnswer: args.userAnswer,
        system: args.system,
        prompt: args.prompt,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return ValueListenableBuilder<AiExplainState>(
      valueListenable: AiExplainService.instance.stateOf(widget.question.id),
      builder: (context, state, _) {
        // 没配 AI 又没讲过，这一栏不该占地方
        if (!_configured && state.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: GlassDecor.panel(t, radius: 18, raised: false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_outlined, size: 15, color: t.brand),
                    SizedBox(width: 6),
                    Text(AppL.of(context).explainTitle,
                        style: text.labelLarge?.copyWith(color: t.brand)),
                    const Spacer(),
                    if (state.text.isNotEmpty && !state.streaming)
                      InkWell(
                        onTap: () => _ask(again: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          child: Text(AppL.of(context).explainRedo,
                              style:
                                  text.bodySmall?.copyWith(color: t.textSoft)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (state.text.isNotEmpty)
                  SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: state.text),
                        // 还在吐字就在末尾留一根闪的光标：一段话停住不动时，
                        // 光看文字分不清是在想还是断了
                        if (state.streaming)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: AiCaret(),
                          ),
                      ],
                    ),
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: t.text,
                      height: 1.75,
                    ),
                  )
                else if (state.streaming) ...[
                  Row(
                    children: [
                      Text(AppL.of(context).explainWorking,
                          style: text.bodySmall?.copyWith(color: t.textSoft)),
                      const SizedBox(width: 5),
                      const AiDots(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AiThinkingSkeleton(),
                ]
                else if (state.error == null) ...[
                  Text(
                    AppL.of(context).explainPitch,
                    style: text.bodySmall?.copyWith(color: t.textSoft),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _ask,
                      child: Text(AppL.of(context).explainAsk),
                    ),
                  ),
                ],
                // 落款要等写完才有模型和时间
                if (state.streaming) ...[
                  SizedBox(height: 10),
                  Text(AppL.of(context).explainBackground,
                      style: text.bodySmall?.copyWith(
                        color: t.textSoft,
                        fontSize: 11.5,
                      )),
                ] else if (state.stamp != null) ...[
                  SizedBox(height: 10),
                  Text(
                    AppL.of(context).explainStamp(state.stamp!),
                    style: text.bodySmall?.copyWith(
                      color: t.textSoft,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 10),
                  Text(state.error!,
                      style: text.bodySmall?.copyWith(color: t.danger)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _ask(again: true),
                    child: Text(AppL.of(context).commonRetry),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 讲题的人设。
///
/// 写得这么具体是因为默认的模型腔在讲题时特别碍事 —— 开头一段"这是一道很好的
/// 题目"，结尾一句"希望对你有帮助"，中间把题干复述一遍，真正有用的就一句话。
const _system = '''
你是给公务员考试考生讲行测题的老师，讲了十几年，带过很多上岸的学生。
现在考生刚做完一道题，来听你讲。

讲法要求：
1. 从出题人的角度切入：这道题设计出来是想考什么能力、想让考生在哪里栽跟头。
2. 正确项凭什么对，要说到点子上，不要只重复答案。
3. 逐个说干扰项是怎么设的 —— 是偷换了范围、混淆了逻辑关系、还是抓了考生的
   语感惯性。考生选错的那个要重点说，直接指出他大概率是怎么想的、错在哪一步。
4. 最后给一句可迁移的判断方法：下次遇到同类题，第一步该看什么。

绝对不要：
- 复述题干和选项原文，考生刚做完，他清楚
- 说"这是一道很好的题""这道题不难"这类评价
- 说"希望对你有帮助""加油""相信你"这类客套和鼓励
- 用 Markdown 标题、加粗、emoji、分点编号堆版面
- 铺垫和总结句，直接开始讲，讲完就停

语气平实、严肃，像坐在旁边给一个成年人讲题。用中文。控制在 400 字以内。
''';

/// 把一道题整理成给模型看的样子。
String _promptFor(Question q, String? userAnswer) {
  final buf = StringBuffer();
  buf.writeln('题型：${q.category}${q.subCategory.isEmpty ? '' : ' · ${q.subCategory}'}');
  if (q.hasMaterial) {
    buf.writeln('材料：${_plain(q.material)}');
  }
  // 逻辑填空的空位在库里是一串空格，原样发过去模型看不出这儿是个空
  buf.writeln('题干：${_plain(q.content).replaceAll(RegExp(r'[ 　]{3,}'), '____')}');
  buf.writeln('选项：');
  for (final o in q.options) {
    buf.writeln('${o.key.toUpperCase()}. ${_plain(o.text)}');
  }
  buf.writeln('正确答案：${q.answer.toUpperCase()}');
  buf.writeln(
    userAnswer == null || userAnswer.isEmpty
        ? '考生未作答。'
        : '考生选的：${userAnswer.toUpperCase()}'
            '${userAnswer.toUpperCase() == q.answer.toUpperCase() ? '（选对了，讲清楚为什么对，以及别的选项错在哪）' : '（选错了，重点讲这个坑）'}',
  );
  final existing = _plain(q.analysis);
  if (existing.isNotEmpty) {
    buf.writeln('题库自带解析（往往很敷衍，你要讲的是它没说清的部分，别照抄）：$existing');
  }
  return buf.toString();
}

String _plain(String raw) => raw
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();
