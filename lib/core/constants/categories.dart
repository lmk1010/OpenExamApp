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
  for (final item in kGongkaoCategories) {
    if (item.key == key) return item.icon;
  }
  for (final item in kComputerCategories) {
    if (item.key == key) return item.icon;
  }
  return AppIcon.shuffle;
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
