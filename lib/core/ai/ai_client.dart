import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/l10n/app_localizations.dart';

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

/// 一次调用花了多少 token。
class AiUsage {
  const AiUsage({this.inputTokens = 0, this.outputTokens = 0});

  final int inputTokens;
  final int outputTokens;

  bool get isEmpty => inputTokens == 0 && outputTokens == 0;

  AiUsage operator +(AiUsage other) => AiUsage(
        inputTokens: inputTokens + other.inputTokens,
        outputTokens: outputTokens + other.outputTokens,
      );

  /// 两家的字段名不一样：OpenAI 是 prompt/completion_tokens，
  /// Anthropic 是 input/output_tokens。
  static AiUsage? from(dynamic decoded) {
    if (decoded is! Map) return null;
    // Anthropic 流式的第一条把 usage 塞在 message 里
    // （message_start → message.usage.input_tokens），
    // 只看顶层的话输入 token 一个都记不到。
    final raw = decoded['usage'] ??
        (decoded['message'] is Map
            ? (decoded['message'] as Map)['usage']
            : null);
    if (raw is! Map) return null;
    final u = raw;
    int pick(List<String> keys) {
      for (final k in keys) {
        final v = int.tryParse('${u[k]}');
        if (v != null) return v;
      }
      return 0;
    }

    final usage = AiUsage(
      inputTokens: pick(['prompt_tokens', 'input_tokens']),
      outputTokens: pick(['completion_tokens', 'output_tokens']),
    );
    return usage.isEmpty ? null : usage;
  }
}

/// 流式过程中的失败。流没法用 [AiResult] 包，只能抛。
class AiException implements Exception {
  const AiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 对话模型客户端。除 Anthropic 外都走 OpenAI 兼容的 /chat/completions。
///
/// 这是 app 里唯一一处联网的地方 —— 除了用户自己配的那个服务商，
/// 不会有任何数据发到别处。
class AiClient {
  const AiClient(this.settings, this.l);

  final AiSettings settings;

  /// 报错文案。这一层没有 BuildContext，由调用方传进来 —— 配 Key 失败时
  /// 用户看到的就是这些句子，在英文界面上冒出中文是最难受的那种 bug。
  final AppL l;

  static const _timeout = Duration(seconds: 120);

  /// 每次调用报一次账。
  ///
  /// 挂成钩子而不是直接写库：core 层不该反过来依赖 data 层，
  /// 而且测试里也不想因为记一笔账就得开数据库。app 启动时接上。
  static void Function(String feature, String model, AiUsage usage)? onUsage;

  /// 这次调用算在哪个功能头上。用量页按它分组。
  static String feature = 'other';

  void _report(AiUsage? usage) {
    if (usage == null || usage.isEmpty) return;
    onUsage?.call(feature, settings.effectiveModel, usage);
  }

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
      return AiResult.fail(l.aiNotConfigured);
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
      return AiResult.fail(l.aiNotConfigured);
    }
    if (!settings.provider.supportsVision) {
      return AiResult.fail(l.aiNoVision(settings.provider.labelText(l)));
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
    String? imageBase64,
    String mimeType = 'image/png',
  }) async {
    final result = imageBase64 == null
        ? await complete(system: system, prompt: prompt, maxTokens: maxTokens)
        : await completeWithImage(
            system: system,
            prompt: prompt,
            imageBase64: imageBase64,
            mimeType: mimeType,
            maxTokens: maxTokens,
          );
    if (!result.isOk) return AiResult.fail(result.error);
    final parsed = extractJson(result.value ?? '');
    if (parsed == null) {
      return AiResult.fail(l.aiUnparsable);
    }
    return AiResult.ok(parsed);
  }

  /// 连通性自检：花最少的 token 确认 key、地址、模型三样都对。
  Future<AiResult<String>> testConnection() async {
    if (settings.apiKey.trim().isEmpty) return AiResult.fail(l.aiNoKey);
    if (settings.effectiveBaseUrl.isEmpty) return AiResult.fail(l.aiNoBaseUrl);
    // 预算给足。DeepSeek V4、o 系列这类会先花 token 想，
    // max_tokens 给小了，想完就没配额吐正文，回来是一句空字符串 ——
    // 那不是"模型坏了"，是我们没给够。
    final result = await complete(
      system: '你是一个连通性测试端点。',
      prompt: '只回复两个字：正常',
      maxTokens: 512,
    );
    if (!result.isOk) return result;
    return AiResult.ok(l.aiConnOk(settings.effectiveModel));
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

  /// 边生成边吐字。
  ///
  /// 讲一道题要几十秒，一次性等到底的话，屏幕上就是一个转圈 —— 看不出它是在
  /// 想还是已经卡死。逐字出来至少能读起来。
  ///
  /// 每段增量文本是一个事件；出错抛 [AiException]，调用方自己接。
  Stream<String> completeStream({
    required String system,
    required String prompt,
    int maxTokens = 4096,
  }) async* {
    if (!settings.isConfigured) {
      throw AiException(l.aiNotConfigured);
    }
    final body = {
      ..._bodyFor(system: system, prompt: prompt, maxTokens: maxTokens),
      'stream': true,
      // OpenAI 兼容接口默认不在流里报用量，得显式要；Anthropic 本来就给。
      // 不支持这个参数的网关会忽略它，不至于报错。
      if (!settings.provider.isAnthropic)
        'stream_options': {'include_usage': true},
    };

    final request = http.Request('POST', _chatUri)
      ..headers.addAll(_headers)
      ..body = jsonEncode(body);

    http.StreamedResponse response;
    try {
      response = await http.Client().send(request).timeout(_timeout);
    } on TimeoutException {
      throw AiException(l.aiTimeout);
    } catch (error) {
      throw AiException(l.aiRequestFailed('$error'));
    }

    if (response.statusCode != 200) {
      final text = await response.stream.bytesToString();
      throw AiException(_describeError(response.statusCode, text));
    }

    var any = false;
    var usage = const AiUsage();
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      Object? decoded;
      try {
        decoded = jsonDecode(payload);
      } catch (_) {
        continue; // 半行 JSON，跳过等下一行
      }
      // 用量分片没有正文，但要收下 —— Anthropic 分两次报（开头报输入、
      // 结尾报输出），所以是累加不是覆盖
      final u = AiUsage.from(decoded);
      if (u != null) usage = usage + u;

      final delta = _deltaFrom(decoded);
      if (delta == null || delta.isEmpty) continue;
      any = true;
      yield delta;
    }
    _report(usage);

    if (!any) {
      throw AiException(l.aiNoContent);
    }
  }

  /// 从一个流式分片里取出新增的那点文字。两家协议的字段位置不一样。
  static String? _deltaFrom(dynamic decoded) {
    if (decoded is! Map) return null;

    // Anthropic: {"type":"content_block_delta","delta":{"type":"text_delta","text":"…"}}
    final delta = decoded['delta'];
    if (delta is Map) {
      final text = delta['text'];
      if (text is String) return text;
      // OpenAI 兼容的 delta 在 choices 里，这里的是 Anthropic 的
      final content = delta['content'];
      if (content is String) return content;
    }

    // OpenAI: {"choices":[{"delta":{"content":"…"}}]}
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final d = first['delta'];
        if (d is Map && d['content'] is String) return d['content'] as String;
        // 有的网关流式也照非流式那样塞 message
        final m = first['message'];
        if (m is Map && m['content'] is String) return m['content'] as String;
      }
    }
    return null;
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
      _report(AiUsage.from(decoded));
      final text = _textFrom(decoded);
      if (text == null || text.trim().isEmpty) {
        return AiResult.fail(l.aiNoContent);
      }
      return AiResult.ok(text);
    } on TimeoutException {
      return AiResult.fail(l.aiTimeout);
    } catch (error) {
      return AiResult.fail(l.aiRequestFailed('$error'));
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
      final choice = choices.first as Map;
      final message = choice['message'];
      if (message is Map) {
        final text = message['content'];
        if (text is String && text.trim().isNotEmpty) return text;
        // 推理模型会把过程放 reasoning_content。正文空但推理有内容，
        // 说明预算被想的部分吃光了 —— 这时候报"没配额"比报"空内容"准。
        if (choice['finish_reason'] == 'length' &&
            '${message['reasoning_content'] ?? ''}'.trim().isNotEmpty) {
          return null;
        }
        if (text is String) return text;
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
        return l.aiBadKey(status, detail);
      case 404:
        return l.aiNotFound(detail);
      case 429:
        return l.aiRateLimited(detail);
      default:
        return l.aiServerError(status, detail);
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
