/// 解题技巧速查 — 行测每个模块的通用方法。内容是备考里公认的那几条，不是
/// 讲义，目的是做题卡住时能十秒内翻到对应的思路。
class Tip {
  const Tip({required this.title, required this.body});

  final String title;
  final String body;
}

class TipGroup {
  const TipGroup({required this.category, required this.summary, required this.tips});

  /// Matches the question category keys.
  final String category;
  final String summary;
  final List<Tip> tips;
}

const kTipGroups = <TipGroup>[
  TipGroup(
    category: 'yanyu',
    summary: '读题干找呼应，别凭语感硬选',
    tips: [
      Tip(
        title: '逻辑填空：先找呼应点',
        body: '空缺前后一定有提示：解释说明、并列关系、转折对立。先圈出呼应词，'
            '再拿选项去对，别一上来就四个词轮流读一遍凭语感。',
      ),
      Tip(
        title: '逻辑填空：辨析词语差异',
        body: '两个选项都通顺时，看差异的那个字。比如「启示 / 启发」差在「示」是给出，'
            '「发」是引出。搭配对象也要看：程度、范围、褒贬。',
      ),
      Tip(
        title: '片段阅读：主旨题找结论句',
        body: '关注「因此、所以、可见、总之」后面的句子，以及转折「但是、然而」之后的内容。'
            '首尾句往往是主旨，中间的例子只是论据。',
      ),
      Tip(
        title: '片段阅读：警惕偷换',
        body: '错误选项常见四类：范围扩大（部分说成全部）、程度加重（可能说成必然）、'
            '偷换主体、无中生有。原文没提的一律排除。',
      ),
      Tip(
        title: '语句排序：先定首句',
        body: '首句一般是背景或话题引入，不会以「这、那、其、因此」这类指代和总结词开头。'
            '定完首句再看指代和关联词串顺序。',
      ),
    ],
  ),
  TipGroup(
    category: 'shuliang',
    summary: '会做的做完，不会的果断跳',
    tips: [
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
            '这类题几乎是固定套路。',
      ),
      Tip(
        title: '时间纪律',
        body: '数量关系单题超过 90 秒还没思路就跳过。整卷里它的性价比最低，'
            '把时间留给资料分析更划算。',
      ),
    ],
  ),
  TipGroup(
    category: 'panduan',
    summary: '先找规律再看选项，别被选项带跑',
    tips: [
      Tip(
        title: '图形推理：看数量',
        body: '数点、线、面、角、封闭区域。图形杂乱无明显样式时，优先数「面」的个数，'
            '其次是交点和线条数。',
      ),
      Tip(
        title: '图形推理：看位置与样式',
        body: '同一元素在动就看位置（平移、旋转、翻转）；元素相似就看样式'
            '（曲直、对称、笔画数）。先判断类型再套规律。',
      ),
      Tip(
        title: '定义判断：抓关键要件',
        body: '把定义拆成主体、对象、方式、结果几个要件，逐个比对选项。'
            '只要有一个要件不符就排除，不要凭感觉。',
      ),
      Tip(
        title: '类比推理：造句子',
        body: '用题干两个词造一句话，再把选项套进同一句话。'
            '关系一致才是答案，注意区分种属、组成、必要条件。',
      ),
      Tip(
        title: '逻辑判断：翻译推理',
        body: '「如果 A 那么 B」= A→B，逆否等价：非 B→非 A。'
            '「只有 A 才 B」= B→A。先翻译再推，别用生活经验。',
      ),
    ],
  ),
  TipGroup(
    category: 'ziliao',
    summary: '性价比最高的模块，必须拿满',
    tips: [
      Tip(
        title: '先看题再看材料',
        body: '带着问题去材料里定位，别通读。重点圈时间、单位、总量与百分比这四样，'
            '出错基本都栽在这里。',
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
        title: '估算优先',
        body: '选项差距大就直接首数字法或截位法，别硬算。'
            '差距小于 5% 时再补算一位。',
      ),
      Tip(
        title: '错误只该出在知识点',
        body: '资料分析每套只允许自己错 1–2 题，且不该是粗心。'
            '错了要回去看是公式记错、算错，还是单位看错。',
      ),
    ],
  ),
  TipGroup(
    category: 'changshi',
    summary: '靠积累，考场上别纠结',
    tips: [
      Tip(
        title: '时政优先',
        body: '常识里时政占比最大，重点是近一年的重要会议、文件、周年纪念。'
            '这部分性价比最高。',
      ),
      Tip(
        title: '排除法',
        body: '完全不会时，看选项里表述过于绝对的（一定、必然、所有），'
            '这类往往是错的；符合常规认知的更可能对。',
      ),
      Tip(
        title: '不要恋战',
        body: '常识每题控制在 20 秒内，会就是会，不会纠结也没用。'
            '省下的时间留给资料分析。',
      ),
      Tip(
        title: '按模块补',
        body: '常识范围广，按法律、经济、科技、人文、地理分块补，'
            '每天固定看一小块，比临时抱佛脚有效。',
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
