/// 解题技巧速查。
///
/// 以前这里是每个模块五条通用心法 ——「先找呼应点」「估算优先」，说得都对，
/// 但翻十遍也不会让你多拿一分：它没告诉你这个模块**今年考几道、在卷子第几题、
/// 该花几分钟、内部怎么分**。做题卡住时真正想知道的是这些。
///
/// 所以现在每个模块先给真题数出来的事实，再给考场上的动作，最后才是方法。
/// 数字来自 161 套真题（安徽 2023—2026、国考 2022—2026）逐题统计，
/// 口径见 [kTipsFootnote]。
library;

/// 一条方法。
class Tip {
  const Tip({required this.title, required this.body});

  final String title;
  final String body;
}

/// 考场动作。跟 [Tip] 的区别是它带数字、带时机，是"现在做什么"而不是"怎么想"。
class Play {
  const Play({required this.action, required this.why});

  /// 祈使句，一行说完。
  final String action;

  /// 为什么值得这么做 —— 尽量带上真题里的数。
  final String why;
}

/// 模块内部的一个题型：两张卷各几道、单题给多少秒。
class Breakdown {
  const Breakdown({
    required this.name,
    required this.anhui,
    required this.guokao,
    required this.seconds,
  });

  final String name;
  final int anhui;
  final int guokao;

  /// 建议单题秒数。0 表示这个题型不单独计时。
  final int seconds;
}

/// 一个模块在一张卷上的位置。
class Slot {
  const Slot({
    required this.count,
    required this.from,
    required this.to,
  });

  final int count;
  final int from;
  final int to;

  String get range => '$from–$to';
}

class TipGroup {
  const TipGroup({
    required this.category,
    required this.summary,
    required this.anhui,
    required this.guokao,
    required this.minutes,
    required this.trend,
    this.breakdown = const [],
    this.breakdownNote = '',
    this.hotspots = const [],
    this.pace,
    this.paceLabel,
    required this.plays,
    required this.tips,
  });

  /// Matches the question category keys.
  final String category;

  /// 一句定性。列表和标题都用它。
  final String summary;

  /// 2026 安徽省考里的位置。
  final Slot anhui;

  /// 2026 国考（地市级）里的位置。
  final Slot guokao;

  /// 建议用时（分钟，按安徽卷题量）。
  final int minutes;

  /// 这几年的变化，一句话。
  final String trend;

  final List<Breakdown> breakdown;

  /// 内部结构表下面的一行小字，用来交代口径（比如取的是哪一年）。
  final String breakdownNote;

  /// 高频考点。给内部没有官方题型划分、只能按考点看的模块（数量关系）用。
  /// 来自关键词粗分，只表示相对权重，不是精确占比。
  final List<String> hotspots;

  /// 顶部第四个数的替代值。数量关系不该显示"52 秒一题"—— 那个模块的打法
  /// 是挑着做，平均配速会把人骗进"每题都做"的坑里。
  final String? pace;
  final String? paceLabel;

  final List<Play> plays;
  final List<Tip> tips;

  /// 顶部第四个数：默认是按安徽题量算的单题秒数。
  String get paceValue => pace ?? '${(minutes * 60 / anhui.count).round()}';
  String get paceCaption => paceLabel ?? '秒一题';
}

/// 一张卷的模块排布，用来画卷面地图。
class PaperLayout {
  const PaperLayout({
    required this.label,
    required this.total,
    required this.minutes,
    required this.segments,
  });

  final String label;
  final int total;
  final int minutes;

  /// 按题号顺序排列的 (category, 起, 止)。
  final List<PaperSegment> segments;
}

class PaperSegment {
  const PaperSegment(this.category, this.from, this.to);

  final String category;
  final int from;
  final int to;

  int get count => to - from + 1;
}

/// 2026 年两张卷的真实排布。逐题数出来的，模块在卷面上都是连续区块。
const kPaperLayouts = <PaperLayout>[
  PaperLayout(
    label: '安徽 2026',
    total: 125,
    minutes: 120,
    segments: [
      PaperSegment('changshi', 1, 30),
      PaperSegment('shuliang', 31, 45),
      PaperSegment('yanyu', 46, 70),
      PaperSegment('panduan', 71, 105),
      PaperSegment('ziliao', 106, 125),
    ],
  ),
  PaperLayout(
    label: '国考 2026 地市级',
    total: 130,
    minutes: 120,
    segments: [
      PaperSegment('changshi', 1, 35),
      PaperSegment('yanyu', 36, 65),
      PaperSegment('shuliang', 66, 75),
      PaperSegment('panduan', 76, 110),
      PaperSegment('ziliao', 111, 130),
    ],
  ),
];

const kTipsFootnote = '题量、题号、内部结构来自 161 套真题逐题统计'
    '（安徽 2023—2026、国考 2022—2026）。建议用时是按单题合理耗时倒推的，'
    '不是真题里读出来的 —— 模考几次之后换成你自己的实测值。';

const kTipGroups = <TipGroup>[
  // ------------------------------------------------------------------ 常识
  TipGroup(
    category: 'changshi',
    summary: '一半是近一年的时政，考场上别纠结',
    anhui: Slot(count: 30, from: 1, to: 30),
    guokao: Slot(count: 35, from: 1, to: 35),
    minutes: 8,
    trend: '2025 年起国考 20→35 题、安徽 20→30 题，加出来的几乎全是政治。'
        '它现在是国考第一大模块。',
    breakdown: [
      Breakdown(name: '政治', anhui: 15, guokao: 20, seconds: 0),
      Breakdown(name: '科技', anhui: 7, guokao: 7, seconds: 0),
      Breakdown(name: '人文', anhui: 3, guokao: 3, seconds: 0),
      Breakdown(name: '法律', anhui: 4, guokao: 4, seconds: 0),
      Breakdown(name: '经济', anhui: 1, guokao: 1, seconds: 0),
      Breakdown(name: '地理', anhui: 0, guokao: 0, seconds: 0),
    ],
    breakdownNote: '题材按 2025 年两卷统计 —— 2026 安徽卷题库里缺了 2 道常识题，'
        '用 2025 的分布更准。其余模块用 2026。',
    plays: [
      Play(
        action: '每题 16 秒，一遍过，不回头',
        why: '30 题只给 8 分钟。多想 30 秒不会让你从不会变成会 —— '
            '这个模块的边际收益是全卷最低的。',
      ),
      Play(
        action: '5 秒没方向就选一个、做记号、走人',
        why: '所有放弃的题涂同一个字母。近三年 1543 道单选里 A/B/C/D 各占 '
            '23%–26%，蒙哪个期望都一样，但统一涂能省十几秒。',
      ),
      Play(
        action: '看到「一定、必然、所有、全部」优先怀疑',
        why: '完全不会时唯一还能用的抓手。表述越绝对越可能是错项。',
      ),
    ],
    tips: [
      Tip(
        title: '真题只做近一年的',
        body: '2025—2026 两张卷的政治题里，一多半直接引用当年讲话原文和新出台文件，'
            '带具体年份数据的题两年内从 0 道涨到 36 道。旧常识真题只能告诉你出题角度，'
            '给不了今年的答案 —— 刷五年常识是把时间烧掉。',
      ),
      Tip(
        title: '时政每天 15 分钟',
        body: '题源集中在考前一年的《人民日报》要闻、《求是》文章和新出台的政策文件。'
            '重点是重要会议、全会公报、周年纪念。这是常识里唯一能靠努力拿到的部分。',
      ),
      Tip(
        title: '别为 1—3 道题啃法条',
        body: '常识里的法律题安徽从 2025 年的 4 道掉到 2026 年的 1 道，'
            '国考地市级从 5 道掉到 2 道，题面平均长度也从 47 字缩到 31 字 —— '
            '变成常识性判断了。系统看民法典和行政法是全卷投入产出比最差的一件事。',
      ),
      Tip(
        title: '科技人文靠平时，不专门复习',
        body: '这两块加起来 10 道，范围是整个人类知识，押不中也补不完。'
            '碰上会的就拿，不会的按 16 秒规矩走人。',
      ),
    ],
  ),

  // ------------------------------------------------------------------ 言语
  TipGroup(
    category: 'yanyu',
    summary: '安徽四年 25 题没动过，配比也没动过',
    anhui: Slot(count: 25, from: 46, to: 70),
    guokao: Slot(count: 30, from: 36, to: 65),
    minutes: 23,
    trend: '国考 2025 年起从 40 题砍到 30 题 —— 砍的是提分曲线最平的模块。'
        '安徽 2023—2026 稳定 25 题，子类配比一字未改。',
    breakdown: [
      Breakdown(name: '逻辑填空', anhui: 10, guokao: 15, seconds: 45),
      Breakdown(name: '片段阅读', anhui: 13, guokao: 9, seconds: 60),
      Breakdown(name: '语句表达', anhui: 2, guokao: 6, seconds: 50),
    ],
    plays: [
      Play(
        action: '两空题先看第二空',
        why: '逻辑填空里两空题占 44%（一空 20%、三空及以上 36%）。'
            '第二空的搭配限制通常更死，一步能排掉两个选项。',
      ),
      Play(
        action: '片段阅读先看问法，再回读原文',
        why: '片段阅读题面平均 233 字，是全卷阅读量最大的题型。'
            '通读一遍再找答案，25 题的预算会直接超。',
      ),
      Play(
        action: '一道题读到第三遍还在犹豫就选，不再纠结',
        why: '言语是最容易过度思考的模块。犹豫超过 15 秒，正确率不会再涨。',
      ),
    ],
    tips: [
      Tip(
        title: '逻辑填空：先找呼应点',
        body: '空缺前后一定有提示：解释说明、并列关系、转折对立。先圈出呼应词，'
            '再拿选项去对，别一上来就四个词轮流读一遍凭语感。',
      ),
      Tip(
        title: '逻辑填空：练搭配，不背释义',
        body: '考的从来是「这个词能不能接这个宾语」，不是词义。'
            '两个选项都通顺时看差异的那个字 ——「启示 / 启发」差在「示」是给出、'
            '「发」是引出；再看搭配对象的程度、范围、褒贬。',
      ),
      Tip(
        title: '片段阅读：主旨题找结论句',
        body: '关注「因此、所以、可见、总之」后面的句子，以及转折「但是、然而」'
            '之后的内容。首尾句往往是主旨，中间的例子只是论据。',
      ),
      Tip(
        title: '片段阅读：错项就那四类',
        body: '范围扩大（部分说成全部）、程度加重（可能说成必然）、偷换主体、'
            '无中生有。原文没提的一律排除，别自己补逻辑。',
      ),
      Tip(
        title: '语句排序：先定首句',
        body: '首句一般是背景或话题引入，不会以「这、那、其、因此」这类指代和'
            '总结词开头。定完首句再看指代和关联词串顺序。',
      ),
    ],
  ),

  // ------------------------------------------------------------------ 数量
  TipGroup(
    category: 'shuliang',
    summary: '安徽把它放在第 2 块，就是在赌你不会跳',
    anhui: Slot(count: 15, from: 31, to: 45),
    guokao: Slot(count: 10, from: 66, to: 75),
    minutes: 13,
    trend: '安徽四年恒定 15 题。题面平均字数从 2022 年的 93 字降到 2026 年的 '
        '74 字 —— 题面变短意味着条件更抽象，但也意味着你更早能判断出会不会做。',
    hotspots: ['最值构造', '几何', '排列组合', '概率', '行程', '经济利润'],
    pace: '5–7',
    paceLabel: '道值得做',
    plays: [
      Play(
        action: '开考直接跳到言语，最后再回来',
        why: '安徽把数量放在第 31—45 题。按卷面顺序做，你会在开考第 10 分钟'
            '一头撞进全卷最贵的 15 道题，然后带着崩掉的心态做后面 80 道能拿分的。',
      ),
      Play(
        action: '回来后先扫一遍 15 道，只挑看一眼就知道怎么列式的 5—7 道',
        why: '放弃 8 道只丢 8 分；被它拖垮节奏要丢 30 分。'
            '13 分钟做 6 道，比 25 分钟做 10 道划算得多。',
      ),
      Play(
        action: '单题超 90 秒没思路，立刻停手',
        why: '已经投进去的时间是沉没成本。停手的判断力比解题能力更值钱。',
      ),
    ],
    tips: [
      Tip(
        title: '练的是「做不做」，不是「怎么做」',
        body: '别按考点系统刷。拿整套 15 道题计时扫读，只标记「做 / 不做」，'
            '不解题。判断力练出来了，考场上那 13 分钟才花得值。',
      ),
      Tip(
        title: '整除特性',
        body: '题干出现「平均分、每人几个、比例是几比几」，答案往往能被某个数整除。'
            '先用整除排除两三个选项，很多题不用算完。',
      ),
      Tip(
        title: '代入排除',
        body: '选项是具体数字且题目求某一个量时，直接从中间的选项往回代。'
            '尤其是年龄、盈亏、余数问题，代入比列方程快得多。',
      ),
      Tip(
        title: '工程问题设特值',
        body: '总量未知就把总量设成工作时间的最小公倍数，效率立刻变成整数，'
            '避免通分。行程、浓度问题同理。',
      ),
      Tip(
        title: '最不利原则',
        body: '看到「至少……才能保证」，先假设最倒霉的情况全部发生，再加 1。'
            '这类题几乎是固定套路，也是这几年出现最稳的一类。',
      ),
    ],
  ),

  // ------------------------------------------------------------------ 判断
  TipGroup(
    category: 'panduan',
    summary: '安徽图推只有 5 题，类比却有 10 题',
    anhui: Slot(count: 35, from: 71, to: 105),
    guokao: Slot(count: 35, from: 76, to: 110),
    minutes: 29,
    trend: '安徽 2023—2026 的结构一字未改：5 / 10 / 10 / 10。'
        '国考 2025 年起把类比从 10 题砍到 5 题，安徽没跟进 —— '
        '两张卷在图推和类比上正好相反。',
    breakdown: [
      Breakdown(name: '类比推理', anhui: 10, guokao: 5, seconds: 25),
      Breakdown(name: '定义判断', anhui: 10, guokao: 10, seconds: 55),
      Breakdown(name: '逻辑判断', anhui: 10, guokao: 10, seconds: 45),
      Breakdown(name: '图形推理', anhui: 5, guokao: 10, seconds: 90),
    ],
    plays: [
      Play(
        action: '按类比 → 定义 → 逻辑 → 图推做，不按卷面顺序',
        why: '类比是全卷单位时间产出最高的题型：10 道、每道 25 秒，'
            '4 分钟锁 10 分。先把这笔钱装进口袋。',
      ),
      Play(
        action: '图形推理放最后，每题最多 90 秒',
        why: '安徽只考 5 道，却是全卷单题最耗时的题型 —— 出题人当时间陷阱在用。'
            '超时就弃，5 道题不值得吃掉资料分析的预算。',
      ),
      Play(
        action: '定义判断只读要件，不通读定义',
        why: '10 道题每道 55 秒。把定义拆成主体、行为、条件，'
            '选项挨个比对，有一个要件不符就排除。',
      ),
    ],
    tips: [
      Tip(
        title: '类比推理：造句子',
        body: '用题干两个词造一句话，再把选项套进同一句话。关系一致才是答案。'
            '常见关系就四类：种属、组成、对应、时序 —— 能秒判就够，不用深挖。',
      ),
      Tip(
        title: '定义判断：抓关键要件',
        body: '把定义拆成主体、对象、方式、结果几个要件，逐个比对选项。'
            '只要有一个要件不符就排除，不要凭感觉。',
      ),
      Tip(
        title: '逻辑判断：先翻译再推',
        body: '「如果 A 那么 B」= A→B，逆否等价：非 B→非 A。「只有 A 才 B」= B→A。'
            '优先练翻译推理和真假话，论证削弱加强放后面 —— 前者有确定解法，后者靠语感。',
      ),
      Tip(
        title: '图形推理：先判类型再套规律',
        body: '图形杂乱无明显样式时优先数「面」，其次是交点和线条数。'
            '同一元素在动就看位置（平移、旋转、翻转）；元素相似就看样式'
            '（曲直、对称、笔画数）。',
      ),
      Tip(
        title: '图推按国考卷练，按安徽卷考',
        body: '国考每年 10 道，题源是安徽的两倍，练手用国考卷更划算。'
            '但考场上按安徽的权重给时间 —— 5 道题，7 分半，不给更多。',
      ),
    ],
  ),

  // ------------------------------------------------------------------ 资料
  TipGroup(
    category: 'ziliao',
    summary: '唯一练到位就能拿满的模块，必须做完',
    anhui: Slot(count: 20, from: 106, to: 125),
    guokao: Slot(count: 20, from: 111, to: 130),
    minutes: 27,
    trend: '安徽 2025 年起从 15 题加到 20 题。四年恒定 4 篇材料 × 5 题，'
        '材料平均 335 字，带图表的题占 71%—82% 且逐年不降 —— '
        '"读得快"在贬值，"从图表里定位数据快"在升值。',
    plays: [
      Play(
        action: '必须在第 87 分钟前做完',
        why: '它放在卷子最后，出题人就是靠这个卡时间：前面拖了，这里就做不完。'
            '这是全卷唯一"练到位就一定能拿满"的 20 分，绝不能留给残余时间。',
      ),
      Play(
        action: '先看 5 个设问再回材料找数，不要通读',
        why: '八成的题答案在图表里而不是正文里。带着问题去定位，'
            '一篇 6 分半才够用。',
      ),
      Play(
        action: '做完一篇涂一篇',
        why: '每年都有人因为最后涂不完，丢掉已经做对的分。'
            '涂卡不能留到最后 5 分钟。',
      ),
    ],
    tips: [
      Tip(
        title: '按整篇计时练，不按单题练',
        body: '这个模块考的是一篇 5 题的总时间，不是单题速度。'
            '练的时候就掐 6 分半一篇，超了就分析是定位慢还是算得慢。',
      ),
      Tip(
        title: '增长率与增长量',
        body: '增长量 = 现期 ÷ (1 + 增长率) × 增长率。求增长量时先把增长率化成'
            '最接近的分数（如 33% ≈ 1/3），一步到位。',
      ),
      Tip(
        title: '比重与倍数',
        body: '比重 = 部分 ÷ 整体；比重变化看部分和整体的增长率谁大。'
            '「A 是 B 的几倍」和「A 比 B 多几倍」差一，读题时圈出来。',
      ),
      Tip(
        title: '估算到能分辨选项就停手',
        body: '选项差距大就直接首数字法或截位法，别硬算。差距小于 5% 时再补算一位。'
            '算得比需要的精度更准，是在白送时间。',
      ),
      Tip(
        title: '错题只允许错在知识点',
        body: '每套只允许自己错 1—2 题，且不该是粗心。错了要回去看是公式记错、'
            '算错，还是时间、单位、总量、百分比这四样看错 —— 栽跟头基本都在这四个地方。',
      ),
    ],
  ),
];

TipGroup? tipsFor(String category) {
  for (final g in kTipGroups) {
    if (g.category == category) return g;
  }
  return null;
}
