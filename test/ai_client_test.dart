import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/l10n/app_localizations_zh.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';

void main() {
  group('extractJson', () {
    test('剥掉 ```json 围栏', () {
      final r = extractJson('```json\n{"score":14}\n```');
      expect(r?['score'], 14);
    });

    test('剥掉裸 ``` 围栏', () {
      expect(extractJson('```\n{"a":1}\n```')?['a'], 1);
    });

    test('忽略 JSON 前后的废话', () {
      final r = extractJson('好的，这是批改结果：\n{"score":9,"summary":"还行"}\n希望有帮助！');
      expect(r?['score'], 9);
      expect(r?['summary'], '还行');
    });

    test('能处理嵌套结构', () {
      final r = extractJson('{"points":[{"text":"甲","hit":true}],"dims":{"a":1}}');
      expect((r?['points'] as List).length, 1);
    });

    test('没有 JSON 时返回 null', () {
      expect(extractJson('我不太明白你的意思'), isNull);
      expect(extractJson(''), isNull);
      expect(extractJson('{坏掉的'), isNull);
    });

    test('数组顶层不算，只认对象', () {
      expect(extractJson('[1,2,3]'), isNull);
    });
  });

  group('AiSettings', () {
    test('留空则回落到服务商默认值', () {
      const s = AiSettings(providerId: 'deepseek', apiKey: 'k');
      expect(s.effectiveModel, 'deepseek-v4-flash');
      expect(s.effectiveBaseUrl, 'https://api.deepseek.com/v1');
      expect(s.isConfigured, isTrue);
    });

    test('自定义地址覆盖默认，并去掉末尾斜杠', () {
      const s = AiSettings(
        providerId: 'openai',
        apiKey: 'k',
        baseUrl: 'https://relay.example.com/v1/',
        model: 'my-model',
      );
      expect(s.effectiveBaseUrl, 'https://relay.example.com/v1');
      expect(s.effectiveModel, 'my-model');
    });

    test('没有 key 就算没配好', () {
      expect(const AiSettings(providerId: 'openai', apiKey: '  ').isConfigured, isFalse);
    });

    test('custom 服务商没填地址时不算配好', () {
      expect(const AiSettings(providerId: 'custom', apiKey: 'k').isConfigured, isFalse);
    });
  });

  group('AiClient 未配置时不发请求', () {
    test('complete 直接返回提示', () async {
      final client = AiClient(AiSettings.empty, AppLZh());
      final r = await client.complete(system: 's', prompt: 'p');
      expect(r.isOk, isFalse);
      expect(r.error, contains('还没配置'));
    });
  });

  test('带图请求自动换成服务商的视觉模型', () {
    // DeepSeek 的正文模型不认图片，视觉在另一个模型上。
    // 不自动切的话，拍照录题会直接报错，而用户根本不知道要去改模型名。
    const s = AiSettings(providerId: 'deepseek', apiKey: 'k');
    expect(s.effectiveModel, 'deepseek-v4-flash');
    expect(s.effectiveVisionModel, 'deepseek-v4-flash-vision-exp');

    // 服务商没有单独的视觉模型时，还是用原来那个
    const o = AiSettings(providerId: 'openai', apiKey: 'k');
    expect(o.effectiveVisionModel, o.effectiveModel);
  });
}
