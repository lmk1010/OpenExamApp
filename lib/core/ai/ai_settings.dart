import 'package:shared_preferences/shared_preferences.dart';

/// 一个 AI 服务商的接入参数。除了 Anthropic，其余都走 OpenAI 兼容协议。
class AiProvider {
  const AiProvider({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.defaultModel,
    this.isAnthropic = false,
    this.supportsVision = true,
    this.hint,
  });

  final String id;
  final String label;
  final String baseUrl;
  final String defaultModel;
  final bool isAnthropic;
  final bool supportsVision;

  /// 去哪儿领 key，显示在设置页里。
  final String? hint;
}

class AiProviders {
  const AiProviders._();

  static const all = <AiProvider>[
    AiProvider(
      id: 'deepseek',
      label: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
      supportsVision: false,
      hint: 'platform.deepseek.com',
    ),
    AiProvider(
      id: 'openai',
      label: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      hint: 'platform.openai.com',
    ),
    AiProvider(
      id: 'anthropic',
      label: 'Claude',
      baseUrl: 'https://api.anthropic.com/v1',
      defaultModel: 'claude-sonnet-4-5',
      isAnthropic: true,
      hint: 'console.anthropic.com',
    ),
    AiProvider(
      id: 'doubao',
      label: '豆包',
      baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
      defaultModel: 'doubao-seed-1-6-250615',
      hint: 'console.volcengine.com',
    ),
    AiProvider(
      id: 'kimi',
      label: 'Kimi',
      baseUrl: 'https://api.moonshot.cn/v1',
      defaultModel: 'moonshot-v1-8k',
      hint: 'platform.moonshot.cn',
    ),
    AiProvider(
      id: 'qwen',
      label: '通义千问',
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      defaultModel: 'qwen-plus',
      hint: 'bailian.console.aliyun.com',
    ),
    AiProvider(
      id: 'glm',
      label: '智谱 GLM',
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      defaultModel: 'glm-4-flash',
      hint: 'bigmodel.cn',
    ),
    AiProvider(
      id: 'custom',
      label: '自定义',
      baseUrl: '',
      defaultModel: '',
      hint: '任何 OpenAI 兼容接口',
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
