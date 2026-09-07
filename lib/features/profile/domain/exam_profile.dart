import 'dart:convert';

import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一项专属能力。开着才在界面上出现。
///
/// 这些模块都是为考公写的：申论是主观题批改，词语是给逻辑填空用的，技巧速查
/// 里只有行测五模块的方法，省份是报考地区。备医师考试的人不该在界面上看见
/// 它们 —— 用不上还得绕开。
enum ExamFeature {
  essay,
  vocab,
  tips,
  provinces;

  /// 名字和说明跟着界面语言走，所以不能写进枚举的构造参数里。
  String label(AppL l) => switch (this) {
        ExamFeature.essay => l.featEssay,
        ExamFeature.vocab => l.featVocab,
        ExamFeature.tips => l.featTips,
        ExamFeature.provinces => l.featProvinces,
      };

  String hint(AppL l) => switch (this) {
        ExamFeature.essay => l.featEssayHint,
        ExamFeature.vocab => l.featVocabHint,
        ExamFeature.tips => l.featTipsHint,
        ExamFeature.provinces => l.featProvincesHint,
      };
}

/// 备考目标。
///
/// 决定界面上出现哪些模块、模考按什么时长算。**不决定题库** —— 题都在一个库里，
/// profile 只是一副眼镜。这样同时备两门考试的人切来切去，题和记录都不会丢。
///
/// 刻意做得很薄：只有名字、几个开关、两个数字。考试种类千差万别，把差异全塞
/// 进配置只会得到一个谁也填不明白的表单；剩下的差异交给题库自己（有什么分类
/// 就显示什么分类）。
class ExamProfile {
  const ExamProfile({
    required this.id,
    required this.name,
    this.features = const {
      ExamFeature.essay,
      ExamFeature.vocab,
      ExamFeature.tips,
      ExamFeature.provinces,
    },
    this.mockMinutes = 45,
    this.mockCount = 50,
  });

  final String id;
  final String name;
  final Set<ExamFeature> features;

  /// 限时模考的时长和题量。行测是 120 分钟 135 题，医师是每单元 150 题，
  /// 差得远，做成数字比写死好。
  final int mockMinutes;
  final int mockCount;

  bool has(ExamFeature f) => features.contains(f);

  Duration get mockLimit => Duration(minutes: mockMinutes);

  ExamProfile copyWith({
    String? name,
    Set<ExamFeature>? features,
    int? mockMinutes,
    int? mockCount,
  }) =>
      ExamProfile(
        id: id,
        name: name ?? this.name,
        features: features ?? this.features,
        mockMinutes: mockMinutes ?? this.mockMinutes,
        mockCount: mockCount ?? this.mockCount,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'features': features.map((e) => e.name).toList(),
        'mockMinutes': mockMinutes,
        'mockCount': mockCount,
      };

  factory ExamProfile.fromJson(Map<String, Object?> json) => ExamProfile(
        id: '${json['id'] ?? 'default'}',
        name: '${json['name'] ?? '我的备考'}',
        features: {
          for (final raw in (json['features'] as List<dynamic>? ?? const []))
            for (final f in ExamFeature.values)
              if (f.name == '$raw') f,
        },
        mockMinutes: int.tryParse('${json['mockMinutes']}') ?? 45,
        mockCount: int.tryParse('${json['mockCount']}') ?? 50,
      );

  /// 默认那一份：考公，全开。
  ///
  /// 老用户升级上来什么都不会变 —— 这个 app 到现在为止就是按考公做的，
  /// 默认值必须跟原样一致，不能让人升级完发现申论不见了。
  static const gongkao = ExamProfile(
    id: 'gongkao',
    // 名字留空，显示时按当前语言兜底 —— 这里是 const，取不到 context。
    name: '',
    mockMinutes: 45,
    mockCount: 50,
  );

  /// 新建时的起点：什么专属模块都不开，练习、错题、记录这些通用的照常。
  static ExamProfile blank(String name) => ExamProfile(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        // 空名字留空串，显示时按当前语言兜底。
        name: name.trim(),
        features: const {},
      );
}

/// 存备考目标。
///
/// 界面在 build 里要同步读，所以内存里留一份当前的；改动后立刻刷新缓存。
class ExamProfileStore {
  ExamProfileStore._();

  static const _listKey = 'exam_profiles';
  static const _activeKey = 'exam_profile_active';

  /// 当前这份。没加载完之前就是默认的考公，跟老版本长得一样。
  static ExamProfile current = ExamProfile.gongkao;

  static List<ExamProfile> _all = const [ExamProfile.gongkao];

  static List<ExamProfile> get all => _all;

  /// 全新安装时该给哪一份。
  ///
  /// 以前一律给「考公·全开」—— 那是这个 app 只有一种用法时的合理默认。现在
  /// 发行版默认不带题库，于是英文用户装上第一眼看到的是技巧速查（行测五模块
  /// 的中文方法）、词语（中文成语辨析）、申论。界面是英文的，内容全是中文，
  /// 看上去就是个坏掉的 App。审核员看到的也是这个。
  ///
  /// 所以默认跟着**题库里实际有什么**走：库里是行测就给考公那份，
  /// 空库或者别的考试就什么专属模块都不开 —— 练习、错题、统计这些通用的照常。
  /// 判断一批分类像不像行测。五个模块里对上三个就算 —— 有的卷不考数量。
  static const _gongkaoKeys = {
    'yanyu',
    'shuliang',
    'panduan',
    'ziliao',
    'changshi',
  };

  static bool looksGongkao(Iterable<String> categories) =>
      categories.toSet().intersection(_gongkaoKeys).length >= 3;

  /// 全新安装时给哪一份。
  ///
  /// 用「这个包带没带内置题库」来判断，而不是去查库：main 里刻意不 await 开库
  /// （首启要解包几秒，等它就是一扇白窗），这里查库等于把那几秒又等回来。
  /// 带题库的包是我们自己的行测版，不带的是发行版 —— 这个信号够准且不花钱。
  static Future<ExamProfile> _freshDefault() async =>
      await AppDatabase.hasBundledBank ? ExamProfile.gongkao : neutral;

  /// 不开任何中文专属模块的默认档。名字留空，由界面按当前语言兜底。
  static const neutral = ExamProfile(
    id: 'default',
    name: '',
    features: {},
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_listKey);
    if (raw == null || raw.isEmpty) {
      final fallback = await _freshDefault();
      _all = [fallback];
      current = fallback;
      return;
    }
    try {
      _all = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((e) => ExamProfile.fromJson(Map<String, Object?>.from(e)))
          .toList();
    } catch (_) {
      _all = const [ExamProfile.gongkao];
    }
    if (_all.isEmpty) _all = [await _freshDefault()];

    final activeId = prefs.getString(_activeKey);
    current = _all.firstWhere(
      (p) => p.id == activeId,
      orElse: () => _all.first,
    );
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _listKey,
      jsonEncode(_all.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_activeKey, current.id);
  }

  static Future<void> switchTo(String id) async {
    current = _all.firstWhere((p) => p.id == id, orElse: () => current);
    await _persist();
  }

  static Future<ExamProfile> create(String name) async {
    final p = ExamProfile.blank(name);
    _all = [..._all, p];
    current = p;
    await _persist();
    return p;
  }

  static Future<void> save(ExamProfile profile) async {
    _all = [
      for (final p in _all) p.id == profile.id ? profile : p,
    ];
    if (current.id == profile.id) current = profile;
    await _persist();
  }

  /// 删一份。删到一个不剩就退回默认的考公 —— 没有 profile 的状态没有意义，
  /// 界面总得按某一套显示。
  static Future<void> remove(String id) async {
    _all = _all.where((p) => p.id != id).toList();
    // 删光了退回中性档，不是考公档 —— 界面总得按某一套画，但那一套不该
    // 自作主张把中文专属模块打开。
    if (_all.isEmpty) _all = [await _freshDefault()];
    if (current.id == id) current = _all.first;
    await _persist();
  }

  /// 导进来一套行测题库之后，把中文专属模块打开。
  ///
  /// 不然会是这么个死角：用户导了行测题库，技巧速查、词语、申论却还关着，
  /// 而他压根不知道设置里有「界面模块」这一项。只在用户没自己改过档案时动手
  /// —— 手动关掉过的人不该被自动打开。
  static Future<void> adoptFromBank(Iterable<String> categories) async {
    if (current.id != neutral.id) return;
    if (!looksGongkao(categories)) return;
    final prefs = await SharedPreferences.getInstance();
    _all = const [ExamProfile.gongkao];
    current = ExamProfile.gongkao;
    await prefs.setString(
      _listKey,
      jsonEncode([ExamProfile.gongkao.toJson()]),
    );
    await prefs.setString(_activeKey, ExamProfile.gongkao.id);
  }

}
