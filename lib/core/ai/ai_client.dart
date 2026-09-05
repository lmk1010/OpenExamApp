import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openexam_app/core/ai/ai_settings.dart';

/// AI 调用的结果。失败时 [error] 是一句能直接给用户看的中文。
class AiResult<T> {
  const AiResult.ok(this.value)
      : error = null,
        isOk = true;
  const AiResult.fail(this.error)
      : value = null,
        isOk = false;

  final T? value;
  final String? error;
  final bool isOk;
}

/// 对话模型客户端。除 Anthropic 外都走 OpenAI 兼容的 /chat/completions。
///
/// 这是 app 里唯一一处联网的地方 —— 除了用户自己配的那个服务商，
/// 不会有任何数据发到别处。
class AiClient {
  const AiClient(this.settings);

  final AiSettings settings;

  static const _timeout = Duration(seconds: 120);

  Map<String, String> get _headers {
    if (settings.provider.isAnthropic) {
      return {
        'content-type': 'application/json',
        'x-api-key': settings.apiKey,
        'anthropic-version': '2023-06-01',
      };
    }
    return {
      'content-type': 'application/json',
      'authorization': 'Bearer ${settings.apiKey}',
    };
  }

  Uri get _chatUri => Uri.parse(
        settings.provider.isAnthropic
            ? '${settings.effectiveBaseUrl}/messages'
            : '${settings.effectiveBaseUrl}/chat/completions',
      );

  /// 纯文本对话。[system] 是角色设定，[prompt] 是这次要问的。
  Future<AiResult<String>> complete({
    required String system,
    required String prompt,
    int maxTokens = 4096,
  }) async {
    if (!settings.isConfigured) {
      return const AiResult.fail('还没配置 AI，去「我的 → AI 设置」里填一下');
    }
    return _post(_bodyFor(system: system, prompt: prompt, maxTokens: maxTokens));
  }

  /// 带图的对话，用于从截图里认题。
  Future<AiResult<String>> completeWithImage({
    required String system,
    required String prompt,
    required String imageBase64,
    String mimeType = 'image/png',
    int maxTokens = 8192,
  }) async {
    if (!settings.isConfigured) {
      return const AiResult.fail('还没配置 AI，去「我的 → AI 设置」里填一下');
    }
    if (!settings.provider.supportsVision) {
      return AiResult.fail('${settings.provider.label} 不支持图片识别，换个支持视觉的模型');
    }
    return _post(_bodyFor(
      system: system,
      prompt: prompt,
      maxTokens: maxTokens,
      imageBase64: imageBase64,
      mimeType: mimeType,
    ));
  }

  /// 要求模型只回 JSON，并把它解析出来。模型爱裹 ```json，这里一并剥掉。
  Future<AiResult<Map<String, dynamic>>> completeJson({
    required String system,
    required String prompt,
    int maxTokens = 4096,
  }) async {
    final result = await complete(system: system, prompt: prompt, maxTokens: maxTokens);
    if (!result.isOk) return AiResult.fail(result.error);
    final parsed = extractJson(result.value ?? '');
    if (parsed == null) {
      return const AiResult.fail('模型没有返回可解析的结果，再试一次');
    }
    return AiResult.ok(parsed);
  }

  /// 连通性自检：花最少的 token 确认 key、地址、模型三样都对。
  Future<AiResult<String>> testConnection() async {
    if (settings.apiKey.trim().isEmpty) return const AiResult.fail('还没填 API Key');
    if (settings.effectiveBaseUrl.isEmpty) return const AiResult.fail('还没填接口地址');
    final result = await complete(
      system: '你是一个连通性测试端点。',
      prompt: '只回复两个字：正常',
      maxTokens: 16,
    );
    if (!result.isOk) return result;
    return AiResult.ok('连接正常 · ${settings.effectiveModel}');
  }

  Map<String, dynamic> _bodyFor({
    required String system,
    required String prompt,
    required int maxTokens,
    String? imageBase64,
    String mimeType = 'image/png',
  }) {
    if (settings.provider.isAnthropic) {
      final content = <Map<String, dynamic>>[
        if (imageBase64 != null)
          {
            'type': 'image',
            'source': {'type': 'base64', 'media_type': mimeType, 'data': imageBase64},
          },
        {'type': 'text', 'text': prompt},
      ];
      return {
        'model': imageBase64 == null
            ? settings.effectiveModel
            : settings.effectiveVisionModel,
        'max_tokens': maxTokens,
        'system': system,
        'messages': [
          {'role': 'user', 'content': content},
        ],
      };
    }

    final content = imageBase64 == null
        ? prompt
        : <Map<String, dynamic>>[
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$imageBase64'},
            },
            {'type': 'text', 'text': prompt},
          ];

    return {
      'model': imageBase64 == null
          ? settings.effectiveModel
          : settings.effectiveVisionModel,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': content},
      ],
    };
  }

  Future<AiResult<String>> _post(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(_chatUri, headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return AiResult.fail(_describeError(response.statusCode, response.body));
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final text = _textFrom(decoded);
      if (text == null || text.trim().isEmpty) {
        return const AiResult.fail('模型返回了空内容，换个模型或稍后再试');
      }
      return AiResult.ok(text);
    } on TimeoutException {
      return const AiResult.fail('请求超时了，检查一下网络或换个接口地址');
    } catch (error) {
      return AiResult.fail('请求失败：$error');
    }
  }

  String? _textFrom(dynamic decoded) {
    if (decoded is! Map) return null;
    // Anthropic: content 是块数组
    final content = decoded['content'];
    if (content is List && content.isNotEmpty) {
      final first = content.first;
      if (first is Map && first['text'] is String) return first['text'] as String;
    }
    // OpenAI 兼容
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = (choices.first as Map)['message'];
      if (message is Map && message['content'] is String) {
        return message['content'] as String;
      }
    }
    return null;
  }

  String _describeError(int status, String body) {
    String detail = body;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          detail = error['message'] as String;
        } else if (decoded['message'] is String) {
          detail = decoded['message'] as String;
        }
      }
    } catch (_) {
      // 非 JSON 的错误体（网关的 HTML 之类）就原样截断显示
    }
    if (detail.length > 160) detail = '${detail.substring(0, 160)}…';

    switch (status) {
      case 401:
      case 403:
        return 'API Key 不对或没权限（$status）：$detail';
      case 404:
        return '接口地址或模型名不对（404）：$detail';
      case 429:
        return '请求太频繁或余额不足（429）：$detail';
      default:
        return '服务返回 $status：$detail';
    }
  }
}

/// 从模型输出里抠出第一个完整 JSON 对象。模型常裹 ```json 或加几句废话。
Map<String, dynamic>? extractJson(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
    final fence = text.lastIndexOf('```');
    if (fence != -1) text = text.substring(0, fence);
  }
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) return null;
  try {
    final decoded = jsonDecode(text.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
