import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/features/ai/ai_usage_page.dart';

/// 用量是拿模型返回的 usage 记的。两家协议字段名不一样，流式还分两次报 ——
/// 解析错了统计就是一片零，用户以为没花钱。
void main() {
  group('解析 usage', () {
    test('OpenAI 的 prompt/completion_tokens', () {
      final u = AiUsage.from({
        'usage': {'prompt_tokens': 1200, 'completion_tokens': 340},
      });
      expect(u?.inputTokens, 1200);
      expect(u?.outputTokens, 340);
    });

    test('Anthropic 的 input/output_tokens', () {
      final u = AiUsage.from({
        'usage': {'input_tokens': 900, 'output_tokens': 210},
      });
      expect(u?.inputTokens, 900);
      expect(u?.outputTokens, 210);
    });

    test('Anthropic 流式第一条嵌在 message 里', () {
      // message_start 事件长这样，只看顶层的话输入 token 一个都记不到
      final u = AiUsage.from({
        'type': 'message_start',
        'message': {
          'usage': {'input_tokens': 1500, 'output_tokens': 0},
        },
      });
      expect(u?.inputTokens, 1500);
    });

    test('没有 usage 就是 null，不要记一笔零', () {
      expect(AiUsage.from({'choices': []}), isNull);
      expect(AiUsage.from('文本'), isNull);
      expect(AiUsage.from({'usage': {}}), isNull);
    });

    test('流式分两次报，累加不覆盖', () {
      // Anthropic 开头报输入、结尾报输出，覆盖的话输入就丢了
      var total = const AiUsage();
      total = total + (AiUsage.from({'usage': {'input_tokens': 800}})!);
      total = total + (AiUsage.from({'usage': {'output_tokens': 250}})!);
      expect(total.inputTokens, 800);
      expect(total.outputTokens, 250);
    });
  });

  group('数字显示', () {
    test('一万以内原样', () {
      expect(formatTokens(0), '0');
      expect(formatTokens(9999), '9999');
    });

    test('上万折成 k', () {
      expect(formatTokens(12500), '12.5k');
    });

    test('上百万折成 M', () {
      expect(formatTokens(2450000), '2.45M');
    });
  });
}
