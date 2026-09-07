// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLZh extends AppL {
  AppLZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'OpenExam';

  @override
  String get onboardTitle => '上岸\n是划出来的';

  @override
  String onboardBodyWithBank(int count) {
    return '$count 道题在这台手机里\n不用登录，没网也能划';
  }

  @override
  String get onboardBodyNoBank => '题库和 App 是分开的\n导入一份就能开始，不用登录、没网也能划';

  @override
  String get onboardBodyLoading => '不用登录，没网也能划';

  @override
  String get onboardWrongTitle => '错的题\n自己会记着';

  @override
  String get onboardWrongBody => '答错的进错题本，再答对就出去\n想写两句笔记、标一下错在哪，都行';

  @override
  String get onboardSkip => '跳过';

  @override
  String get onboardStart => '出发';

  @override
  String get noBankTitle => '还没有题库';

  @override
  String get noBankBody =>
      '这个版本不预装题目 —— 题库和 App 是分开的，装哪套题库就是练哪门考试。导入一份就能开始：做题、按卷模考、错题复盘、弱点诊断都不用联网。';

  @override
  String get noBankImport => '导入题库';

  @override
  String get noBankHint =>
      '也可以把题库文件放进「文件」App 的 OpenExam 文件夹，或者用「扫描试卷」把纸质卷子拍成题目。';

  @override
  String get bankTitle => '题库';

  @override
  String get bankExportTitle => '导出题库';

  @override
  String get bankExportBody => '导出成 zip，含题目和图片。别人用「导入题库」就能装上 —— 跟导入是同一个格式。';

  @override
  String get bankExportWholeBank => '整个题库';

  @override
  String bankExportWholeBankHint(int count) {
    return '$count 题 · 文件会很大';
  }

  @override
  String bankExportCount(int count) {
    return '$count 题';
  }

  @override
  String get bankExportEmpty => '这个范围里没有题';

  @override
  String get bankExportCancelled => '已取消';

  @override
  String bankExportDone(int count, String name) {
    return '已导出 $count 题：$name';
  }

  @override
  String bankExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get settingsLanguage => '界面语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageSystemHint => '按手机的语言自动切换';

  @override
  String get onboardNext => '下一个';

  @override
  String get onboardFinish => '开始划';
}
