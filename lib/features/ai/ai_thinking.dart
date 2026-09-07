import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';

/// 等模型开口时的占位。
///
/// 原来这儿是一个转圈 —— 转圈是"卡住了"的通用长相，看不出它在写字。
/// 几条灰杠加一道扫光，形状上就是"一段话正在成形"，等三十秒也不那么难熬。
class AiThinkingSkeleton extends StatefulWidget {
  const AiThinkingSkeleton({super.key, this.lines = 3});

  final int lines;

  @override
  State<AiThinkingSkeleton> createState() => _AiThinkingSkeletonState();
}

class _AiThinkingSkeletonState extends State<AiThinkingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 每行长短不一，看着才像一段话；最后一行短，像话没说完。
  static const _widths = [1.0, 0.94, 0.62, 0.88, 0.45];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = t.lineSoft;
    final glow = t.brand.withValues(alpha: 0.22);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // 扫光从左到右走一遍，两端各留一段空走位，免得刚出画就又进来
        final x = _c.value * 2.4 - 0.7;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 0.45, 0),
            end: Alignment(x + 0.45, 0),
            colors: [base, glow, base],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < widget.lines; i++) ...[
                if (i > 0) const SizedBox(height: 9),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _widths[i % _widths.length],
                  child: Container(
                    height: 11,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 正在输出的文字后面那根光标。
///
/// 一段话停住不动的时候，分不清是模型在想还是网断了；有根光标在闪，
/// 至少知道这事还活着。
class AiCaret extends StatefulWidget {
  const AiCaret({super.key, this.height = 15});

  final double height;

  @override
  State<AiCaret> createState() => _AiCaretState();
}

class _AiCaretState extends State<AiCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FadeTransition(
      // 不要线性闪 —— 那像坏掉的霓虹灯。缓入缓出更接近文本框里的光标。
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      child: Container(
        width: 2,
        height: widget.height,
        margin: const EdgeInsets.only(left: 2, bottom: 1),
        decoration: BoxDecoration(
          color: t.brand,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// 「正在看这道题」那行字里跳动的三个点。
class AiDots extends StatefulWidget {
  const AiDots({super.key});

  @override
  State<AiDots> createState() => _AiDotsState();
}

class _AiDotsState extends State<AiDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0→1→0，两端接得上，循环起来不跳。
  static double _wave(double phase) => 1 - (phase * 2 - 1).abs();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              // 三个点错开三分之一个周期：三角波 0→1→0，看着像依次亮起
              Opacity(
                opacity: 0.28 + 0.72 * _wave((_c.value + i / 3) % 1.0),
                child: Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: t.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
