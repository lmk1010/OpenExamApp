import 'package:shared_preferences/shared_preferences.dart';

/// 一个可选的模型。给用户一个下拉，而不是让他去背模型名。
class AiModel {
  const AiModel(this.id, this.label, {this.note = '', this.free = false});

  final String id;
  final String label;

  /// 一句话说明它适合干什么，直接显示在下拉里。
  final String note;

  /// 免费额度内可用，标出来。
  final bool free;
}

/// 一个 AI 服务商的接入参数。除了 Anthropic，其余都走 OpenAI 兼容协议。
class AiProvider {
  const AiProvider({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.defaultModel,
    this.isAnthropic = false,
    this.supportsVision = true,
    this.visionModel,
    this.models = const [],
    this.keyUrl,
    this.hint,
  });

  final String id;
  final String label;
  final String baseUrl;
  final String defaultModel;
  final bool isAnthropic;
  final bool supportsVision;

  /// 看图要换一个模型的服务商填这里。DeepSeek 的视觉能力在
  /// deepseek-v4-flash-vision-exp 上，正文模型不认图片，
  /// 所以拍照录题、试卷识别得自动切过去，而不是让用户自己去改模型名。
  final String? visionModel;

  /// 这家能选的模型。空的话设置页只给一个输入框。
  final List<AiModel> models;

  /// 领 key 的页面，设置页里那行「去哪儿拿 Key」直接点开它。
  final String? keyUrl;

  /// 去哪儿领 key 的短说明。
  final String? hint;

  /// 自定义服务商才需要用户自己填地址。
  bool get needsBaseUrl => id == 'custom';
}

class AiProviders {
  const AiProviders._();

  static const all = <AiProvider>[
    AiProvider(
      id: 'deepseek',
      label: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      // deepseek-chat 现在只是 v4-flash 的别名，写实名才能挑 pro。
      defaultModel: 'deepseek-v4-flash',
      visionModel: 'deepseek-v4-flash-vision-exp',
      keyUrl: 'https://platform.deepseek.com/api_keys',
      hint: 'platform.deepseek.com',
      models: [
        AiModel('deepseek-v4-flash', 'V4 Flash', note: '快且便宜，日常够用'),
        AiModel('deepseek-v4-pro', 'V4 Pro', note: '难题和长文批改更稳'),
      ],
    ),
    AiProvider(
      id: 'openai',
      label: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      keyUrl: 'https://platform.openai.com/api-keys',
      hint: 'platform.openai.com',
      models: [
        AiModel('gpt-4o-mini', 'GPT-4o mini', note: '便宜，能看图'),
        AiModel('gpt-4o', 'GPT-4o', note: '更强，贵一些'),
      ],
    ),
    AiProvider(
      id: 'anthropic',
      label: 'Claude',
      baseUrl: 'https://api.anthropic.com/v1',
      defaultModel: 'claude-sonnet-4-5',
      isAnthropic: true,
      keyUrl: 'https://console.anthropic.com/settings/keys',
      hint: 'console.anthropic.com',
      models: [
        AiModel('claude-sonnet-4-5', 'Sonnet 4.5', note: '写作和批改最稳'),
        AiModel('claude-haiku-4-5-20251001', 'Haiku 4.5', note: '快'),
      ],
    ),
    AiProvider(
      id: 'doubao',
      label: '豆包',
      baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
      defaultModel: 'doubao-seed-1-6-250615',
      keyUrl: 'https://console.volcengine.com/ark',
      hint: 'console.volcengine.com',
      models: [
        AiModel('doubao-seed-1-6-250615', 'Seed 1.6', note: '通用'),
      ],
    ),
    AiProvider(
      id: 'kimi',
      label: 'Kimi',
      baseUrl: 'https://api.moonshot.cn/v1',
      defaultModel: 'moonshot-v1-8k',
      keyUrl: 'https://platform.moonshot.cn/console/api-keys',
      hint: 'platform.moonshot.cn',
      models: [
        AiModel('moonshot-v1-8k', 'v1 8K', note: '短文本'),
        AiModel('moonshot-v1-32k', 'v1 32K', note: '长材料'),
      ],
    ),
    AiProvider(
      id: 'qwen',
      label: '通义千问',
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      defaultModel: 'qwen-plus',
      keyUrl: 'https://bailian.console.aliyun.com/?apiKey=1',
      hint: 'bailian.console.aliyun.com',
      models: [
        AiModel('qwen-plus', 'Qwen Plus', note: '通用'),
        AiModel('qwen-vl-plus', 'Qwen VL Plus', note: '能看图'),
      ],
    ),
    AiProvider(
      id: 'glm',
      label: '智谱 GLM',
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      defaultModel: 'glm-4-flash',
      keyUrl: 'https://bigmodel.cn/usercenter/apikeys',
      hint: 'bigmodel.cn',
      models: [
        AiModel('glm-4-flash', 'GLM-4 Flash', note: '免费额度内可用', free: true),
        AiModel('glm-4-plus', 'GLM-4 Plus', note: '更强'),
      ],
    ),
    AiProvider(
      id: 'custom',
      label: '自定义',
      baseUrl: '',
      defaultModel: '',
      hint: '任何 OpenAI 兼容接口，地址要带上 /v1',
    ),
  ];

  static AiProvider byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}

/// 用户配好的一套 AI 连接。API Key 存在本机 SharedPreferences 里，不上传任何地方。
class AiSettings {
  const AiSettings({
    required this.providerId,
    required this.apiKey,
    this.model = '',
    this.baseUrl = '',
  });

  final String providerId;
  final String apiKey;

  /// 留空则用服务商默认模型。
  final String model;

  /// 留空则用服务商默认地址；中转/自建填这里。
  final String baseUrl;

  static const empty = AiSettings(providerId: 'deepseek', apiKey: '');

  AiProvider get provider => AiProviders.byId(providerId);

  bool get isConfigured => apiKey.trim().isNotEmpty && effectiveBaseUrl.isNotEmpty;

  String get effectiveModel =>
      model.trim().isNotEmpty ? model.trim() : provider.defaultModel;

  /// 带图请求用的模型。服务商单独有视觉模型就切过去，否则还是原来那个。
  String get effectiveVisionModel =>
      provider.visionModel ?? effectiveModel;

  String get effectiveBaseUrl {
    final custom = baseUrl.trim();
    final base = custom.isNotEmpty ? custom : provider.baseUrl;
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  AiSettings copyWith({
    String? providerId,
    String? apiKey,
    String? model,
    String? baseUrl,
  }) {
    return AiSettings(
      providerId: providerId ?? this.providerId,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

/// AI 配置的读写。故意不加密 —— 与 app 其余本地数据一致，也提醒用户这是本机存储。
class AiSettingsStore {
  const AiSettingsStore._();

  static const _keyProvider = 'ai_provider';
  static const _keyApiKey = 'ai_api_key';
  static const _keyModel = 'ai_model';
  static const _keyBaseUrl = 'ai_base_url';

  static Future<AiSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AiSettings(
      providerId: prefs.getString(_keyProvider) ?? 'deepseek',
      apiKey: prefs.getString(_keyApiKey) ?? '',
      model: prefs.getString(_keyModel) ?? '',
      baseUrl: prefs.getString(_keyBaseUrl) ?? '',
    );
  }

  static Future<void> save(AiSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProvider, settings.providerId);
    await prefs.setString(_keyApiKey, settings.apiKey.trim());
    await prefs.setString(_keyModel, settings.model.trim());
    await prefs.setString(_keyBaseUrl, settings.baseUrl.trim());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProvider);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyModel);
    await prefs.remove(_keyBaseUrl);
  }
}
