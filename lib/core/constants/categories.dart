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
