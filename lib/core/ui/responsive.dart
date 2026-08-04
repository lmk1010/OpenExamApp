import 'package:flutter/material.dart';

/// 屏幕宽度分档。手机竖屏是 compact，手机横屏和小平板是 medium，
/// 平板横屏和折叠屏展开是 expanded。
enum Breakpoint { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  Breakpoint get breakpoint {
    final w = MediaQuery.sizeOf(this).width;
    if (w >= 1000) return Breakpoint.expanded;
    if (w >= 640) return Breakpoint.medium;
    return Breakpoint.compact;
  }

  bool get isCompact => breakpoint == Breakpoint.compact;

  /// 够宽就该换布局：侧边导航、两栏、多列网格。
  bool get isWide => breakpoint != Breakpoint.compact;

  bool get isExpanded => breakpoint == Breakpoint.expanded;

  /// 列表和正文的最大宽度。平板上让一行文字横穿 1200px 是最省事也最难读的做法。
  double get readableWidth => switch (breakpoint) {
        Breakpoint.compact => double.infinity,
        Breakpoint.medium => 620,
        Breakpoint.expanded => 720,
      };

  /// 网格列数，按可用宽度算，不按设备类型猜。
  int columnsFor({double minTileWidth = 300, int max = 3}) {
    final w = MediaQuery.sizeOf(this).width;
    final n = (w / minTileWidth).floor();
    return n.clamp(1, max);
  }
}

/// 把内容限制在可读宽度内并居中。窄屏上是透明的，什么也不做。
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final limit = maxWidth ?? context.readableWidth;
    if (!limit.isFinite) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: limit),
        child: child,
      ),
    );
  }
}
