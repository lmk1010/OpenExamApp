import 'package:flutter/material.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';

/// Builds a ThemeData from a token set, so light/dark (and any future theme)
/// share one definition and differ only in tokens.
class AppTheme {
  /// Horizontal page gutter used by every screen.
  static const double gutter = 18;

  /// Corner radius of surfaces / cards.
  static const double radius = 24;

  /// Tabular figures so numbers never jitter between states.
  static const List<FontFeature> numeric = [FontFeature.tabularFigures()];

  static ThemeData light() => _build(AppTokens.light, Brightness.light);
  static ThemeData dark() => _build(AppTokens.dark, Brightness.dark);
  static ThemeData guga() => _build(AppTokens.guga, Brightness.light);
  static ThemeData spark() => _build(AppTokens.spark, Brightness.light);

  static ThemeData fromTokens(AppTokens t, Brightness brightness) =>
      _build(t, brightness);

  static SystemUiOverlayStyle overlayFor(AppTokens t, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData _build(AppTokens t, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: t.brand,
        brightness: brightness,
        primary: t.brand,
        onPrimary: t.onBrand,
        surface: t.surface,
        onSurface: t.text,
      ),
    );

    return base.copyWith(
      extensions: [t],
      scaffoldBackgroundColor: Colors.transparent,
      // 默认的 Android 页面切换是从底部整屏推上来的，在这种浅色渐变背景上
      // 显得笨重。换成淡入 + 轻微横移，跟 Ambient Glass 的层次感一致。
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlideTransitions(),
          TargetPlatform.iOS: _FadeSlideTransitions(),
        },
      ),
      canvasColor: Colors.transparent,
      dividerColor: t.line,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: t.text, height: 1.2, letterSpacing: -0.6),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.text, height: 1.1, letterSpacing: -0.4, fontFeatures: numeric),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.text, height: 1.3, letterSpacing: -0.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.text, height: 1.35, letterSpacing: -0.2),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.text, height: 1.4, letterSpacing: -0.1),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: t.text, height: 1.65),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: t.textSoft, height: 1.55),
        bodySmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: t.muted, height: 1.45, fontFeatures: numeric),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.text),
        labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.muted),
        labelSmall: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: t.muted, letterSpacing: 0.6),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.text,
        systemOverlayStyle: overlayFor(t, brightness),
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.text, letterSpacing: -0.2),
        toolbarHeight: 48,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.brand,
          foregroundColor: t.onBrand,
          disabledBackgroundColor: t.surfaceAlt,
          disabledForegroundColor: t.muted,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.text,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          side: BorderSide(color: t.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.brand,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.brand,
        linearTrackColor: t.surfaceAlt,
        linearMinHeight: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.text,
        insetPadding: const EdgeInsets.fromLTRB(gutter, 0, gutter, 20),
        contentTextStyle: TextStyle(fontSize: 14, color: t.surface, height: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

/// 淡入 + 从右侧轻推 16dp，返回时反向。比 Material 默认的整屏上推轻，
/// 也比纯淡入更能说明「进了一层」。
class _FadeSlideTransitions extends PageTransitionsBuilder {
  const _FadeSlideTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final out = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut);
    // Scaffolds are transparent app-wide (the ambient backdrop is painted once
    // at the root), so a pushed page used to let the page underneath show
    // through for the whole transition — two layers of text at once. Every
    // route gets its own backdrop here instead.
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: Listenable.merge([curved, out]),
        builder: (context, child) => Transform.translate(
          // 新页从右边轻推进来；被压在下面的旧页往左让一点。
          offset: Offset(22 * (1 - curved.value) - 14 * out.value, 0),
          child: child,
        ),
        child: AmbientBackground(child: child),
      ),
    );
  }
}
