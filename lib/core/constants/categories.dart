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

String categoryLabel(String? key) {
  for (final item in kGongkaoCategories) {
    if (item.key == key) return item.label;
  }
  return key?.isNotEmpty == true ? key! : '综合';
}

AppIcon categoryIcon(String? key) {
  for (final item in kGongkaoCategories) {
    if (item.key == key) return item.icon;
  }
  return AppIcon.shuffle;
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
