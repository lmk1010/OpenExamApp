import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 一项专属能力。开着才在界面上出现。
///
/// 这些模块都是为考公写的：申论是主观题批改，词语是给逻辑填空用的，技巧速查
/// 里只有行测五模块的方法，省份是报考地区。备医师考试的人不该在界面上看见
/// 它们 —— 用不上还得绕开。
enum ExamFeature {
  essay('申论 / 主观题', '写作 + AI 批改'),
  vocab('词语', '词卡、辨析、生词本'),
  tips('技巧速查', '各模块解题方法'),
  provinces('报考地区', '按省份筛选卷子');

  const ExamFeature(this.label, this.hint);

  final String label;
  final String hint;
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
    name: '公务员 · 行测申论',
    mockMinutes: 45,
    mockCount: 50,
  );

  /// 新建时的起点：什么专属模块都不开，练习、错题、记录这些通用的照常。
  static ExamProfile blank(String name) => ExamProfile(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim().isEmpty ? '我的备考' : name.trim(),
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

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_listKey);
    if (raw == null || raw.isEmpty) {
      _all = const [ExamProfile.gongkao];
      current = ExamProfile.gongkao;
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
    if (_all.isEmpty) _all = const [ExamProfile.gongkao];

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
    if (_all.isEmpty) _all = const [ExamProfile.gongkao];
    if (current.id == id) current = _all.first;
    await _persist();
  }
}
