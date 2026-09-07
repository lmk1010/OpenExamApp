import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 界面语言。
///
/// 默认跟手机走：不设 [MaterialApp.locale] 时 Flutter 会拿系统语言去
/// [supportedLocales] 里匹配，匹配不上落到第一个。所以「按手机语言自动识别」
/// 是免费的，这个类真正要解决的是**另外那一半** —— 手动指定。
///
/// 为什么必须能手动指定：这个 app 的用户里有一批是人在国外、手机是英文、
/// 但备的是中文考试的人。把界面按手机语言强行切成英文，对他们是纯粹的倒退。
/// 反过来也一样。语言跟着内容走，不总是跟着系统走。
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final instance = LocaleController._();

  static const _key = 'ui_locale';

  /// 支持的语言。加新语言只改这里和 lib/l10n/。
  ///
  /// 顺序有意义：匹配不上系统语言时 Flutter 落到第一个，所以第一个必须是
  /// 覆盖最全的那份 —— 目前文案是先用中文写的，英文是翻译。
  static const supported = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// null = 跟手机走。
  Locale? _locale;

  Locale? get locale => _locale;

  bool get followsSystem => _locale == null;

  /// 当前实际生效的语言码，给设置页显示用。
  String labelFor(Locale? deviceLocale) {
    final l = _locale ?? deviceLocale;
    return switch (l?.languageCode) {
      'en' => 'English',
      'zh' => '中文',
      _ => '中文',
    };
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == null || code.isEmpty) return;
    _locale = Locale(code);
    notifyListeners();
  }

  /// 传 null 表示回到「跟手机走」。
  Future<void> set(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}
