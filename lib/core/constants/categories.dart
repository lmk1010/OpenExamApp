import 'package:openexam_app/core/ui/stroke_icons.dart';

class CategoryMeta {
  const CategoryMeta({
    required this.key,
    required this.label,
    required this.short,
    required this.icon,
  });

  final String key;
  final String label;
  final String short;
  final AppIcon icon;
}

const kGongkaoCategories = <CategoryMeta>[
  CategoryMeta(key: 'yanyu', label: '言语理解', short: '言语', icon: AppIcon.speech),
  CategoryMeta(key: 'shuliang', label: '数量关系', short: '数量', icon: AppIcon.numbers),
  CategoryMeta(key: 'panduan', label: '判断推理', short: '判断', icon: AppIcon.logic),
  CategoryMeta(key: 'ziliao', label: '资料分析', short: '资料', icon: AppIcon.chart),
  CategoryMeta(key: 'changshi', label: '常识判断', short: '常识', icon: AppIcon.globe),
];

const kComputerCategories = <CategoryMeta>[
  CategoryMeta(key: 'cs_base', label: '计算机基础', short: '计基', icon: AppIcon.globe),
  CategoryMeta(key: 'cs_security', label: '信息安全', short: '安全', icon: AppIcon.privacy),
  CategoryMeta(key: 'cs_windows', label: 'Windows', short: '系统', icon: AppIcon.papers),
  CategoryMeta(key: 'cs_office', label: '办公软件', short: '办公', icon: AppIcon.papers),
  CategoryMeta(key: 'cs_prog', label: '程序设计', short: '编程', icon: AppIcon.numbers),
  CategoryMeta(key: 'cs_db', label: '数据库', short: '数据库', icon: AppIcon.chart),
  CategoryMeta(key: 'cs_net', label: '网络技术', short: '网络', icon: AppIcon.globe),
  CategoryMeta(key: 'cs_se', label: '软件工程', short: '软工', icon: AppIcon.logic),
];

/// 题库里**实际**有哪些分类。
///
/// 以前各处筛选器都直接遍历 [kGongkaoCategories]，写死行测那五个模块 ——
/// 于是导进来一批医师考试的题（category 是"内科学"），题在库里，可练习页、
/// 搜索、错题本的题型筛选里一个入口都没有，等于导了个寂寞。
///
/// 现在以题库为准：内置那几个有专属插画和图标，其余按名字现生成一套外观。
/// 同一个名字每次生成的图标固定，不会这次是书下次是地球。
class CategoryRegistry {
  CategoryRegistry._();

  /// UI 在 build 里要同步取，所以缓一份。
  static List<CategoryMeta> _current = kGongkaoCategories;

  static List<CategoryMeta> get current => _current;

  /// 用题库里查出来的分类键刷新。传空表示库是空的，退回内置那套当占位。
  static void updateFrom(Iterable<String> keys) {
    final cleaned = keys.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (cleaned.isEmpty) {
      _current = kGongkaoCategories;
      return;
    }
    // 内置的排前面，保持老用户熟悉的顺序；新科目按名字排在后面
    final known = <CategoryMeta>[];
    final extra = <CategoryMeta>[];
    for (final key in cleaned.toSet()) {
      final meta = _builtin(key);
      (meta != null ? known : extra).add(metaFor(key));
    }
    known.sort((a, b) => _builtinIndex(a.key).compareTo(_builtinIndex(b.key)));
    extra.sort((a, b) => a.label.compareTo(b.label));
    _current = [...known, ...extra];
  }

  static CategoryMeta metaFor(String key) {
    final hit = _builtin(key);
    if (hit == null) return _generate(key);
    // 命中的是内置元数据，但 key 必须还是题库里存的那个 ——
    // 换成 cs_db 的话，按 category 查题会一道也查不到。
    return hit.key == key
        ? hit
        : CategoryMeta(
            key: key,
            label: hit.label,
            short: hit.short,
            icon: hit.icon,
          );
  }

  /// 内置元数据。
  ///
  /// 除了按 key，也按中文名认一遍 —— 内置的计算机分类 key 是 `cs_db` 这种
  /// slug，而 AI 从资料里读出来的是"数据库"，光比 key 永远对不上，导进来的
  /// 计算机题就拿不到内置的图标，白配了一套。
  static CategoryMeta? _builtin(String key) {
    for (final item in kGongkaoCategories) {
      if (item.key == key || item.label == key) return item;
    }
    for (final item in kComputerCategories) {
      if (item.key == key || item.label == key) return item;
    }
    return null;
  }

  static int _builtinIndex(String key) {
    for (var i = 0; i < kGongkaoCategories.length; i++) {
      if (kGongkaoCategories[i].key == key) return i;
    }
    for (var i = 0; i < kComputerCategories.length; i++) {
      if (kComputerCategories[i].key == key) return 100 + i;
    }
    return 999;
  }

  /// 导入的分类没有内置元数据，就地造一个。
  ///
  /// AI 起的名基本都是中文（"刑法""内科学"），直接拿来当标签；万一是拼音或
  /// 英文 slug，也总比空白强。
  static CategoryMeta _generate(String key) {
    final label = key;
    // 简称取前两个字：横着排的筛选条塞不下"教育心理学"。
    // 按 rune 取，别按 code unit —— emoji 和生僻字是两个 code unit，
    // 硬切会切出半个字符。
    final runes = label.runes.toList();
    final short = runes.length <= 3
        ? label
        : String.fromCharCodes(runes.take(2));
    return CategoryMeta(
      key: key,
      label: label,
      short: short,
      icon: _iconFor(key),
    );
  }

  /// 一组中性图标，按名字取一个。同名恒定同图标。
  static const _pool = <AppIcon>[
    AppIcon.papers,
    AppIcon.globe,
    AppIcon.logic,
    AppIcon.numbers,
    AppIcon.speech,
    AppIcon.chart,
    AppIcon.privacy,
    AppIcon.shuffle,
  ];

  static AppIcon _iconFor(String key) =>
      _pool[_stableHash(key) % _pool.length];

  /// 不用 hashCode —— 它在不同次运行里可能不一样，图标就会跳。
  static int _stableHash(String s) {
    var h = 0;
    for (final unit in s.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }
}

String categoryLabel(String? key) {
  for (final item in kGongkaoCategories) {
    if (item.key == key) return item.label;
  }
  for (final item in kComputerCategories) {
    if (item.key == key) return item.label;
  }
  return key?.isNotEmpty == true ? key! : '综合';
}

AppIcon categoryIcon(String? key) {
  if (key == null || key.isEmpty) return AppIcon.shuffle;
  return CategoryRegistry.metaFor(key).icon;
}

/// Seed bank sub_category keys → 考生常用叫法.
const kSubCategoryLabels = <String, String>{
  'xuanci': '逻辑填空',
  'yueduan': '片段阅读',
  'yuju': '语句表达',
  'wenzhang': '文章阅读',
  'jisuan': '数学运算',
  'tuili': '数字推理',
  'dingyi': '定义判断',
  'luoji': '逻辑判断',
  'leibi': '类比推理',
  'tuxing': '图形推理',
  'zonghe': '综合资料',
  'zengzhang': '增长量/率',
  'biaoge': '表格资料',
  'zhengzhi': '政治',
  'keji': '科技',
  'renwen': '人文',
  'falv': '法律',
  'jingji': '经济',
  'dili': '地理',
};

String subCategoryLabel(String? key) {
  if (key == null || key.isEmpty) return '未分类';
  final known = kSubCategoryLabels[key];
  if (known != null) return known;
  // 导入的题可能带任意子分类键。是中文就照原样显示，是 bizhong 这种
  // 拼音/英文 slug 就别摆到界面上 —— 那是数据里的键，不是给人看的词。
  final hasCjk = RegExp(r'[\u4e00-\u9fa5]').hasMatch(key);
  return hasCjk ? key : '其他';
}

/// 错因分类 — from how 考生 actually review: 粗心 / 不会 / 审题 / 没时间.
class WrongReason {
  const WrongReason({required this.key, required this.label, required this.hint});

  final String key;
  final String label;
  final String hint;
}

const kWrongReasons = <WrongReason>[
  WrongReason(key: 'careless', label: '粗心', hint: '会做但看漏、算错、选错'),
  WrongReason(key: 'unknown', label: '不会', hint: '知识点或方法没掌握'),
  WrongReason(key: 'misread', label: '审题', hint: '看错题干、单位、限定词'),
  WrongReason(key: 'timeout', label: '没时间', hint: '时间不够，蒙的或没做完'),
];

String wrongReasonLabel(String? key) {
  for (final r in kWrongReasons) {
    if (r.key == key) return r.label;
  }
  return '';
}

/// 收藏标签 — small fixed set beats free-form tags on a phone.
const kMarkTags = <String>['易错', '公式', '技巧', '待复习'];

/// 纠错类型 — 没有服务器，但把问题标出来至少能自己回头核对、也能随备份带走。
const kFeedbackKinds = <String, String>{
  'answer': '答案有误',
  'analysis': '解析看不懂',
  'typo': '题干有错字',
  'image': '图片缺失或看不清',
  'other': '其他问题',
};

/// 报考地区 — matched against paper titles, so the list follows what the bank
/// actually contains rather than a full administrative list.
const kProvinces = <String>[
  '国考',
  '北京', '上海', '广东', '江苏', '浙江', '山东', '河南', '河北', '四川', '湖北',
  '湖南', '安徽', '福建', '江西', '陕西', '山西', '辽宁', '吉林', '黑龙江',
  '云南', '贵州', '广西', '天津', '重庆', '内蒙古', '新疆', '甘肃', '海南',
  '宁夏', '青海', '西藏',
];
