import 'package:flutter/material.dart';

/// Semantic design tokens. Every widget reads colours from here via
/// `context.tokens`, so a new theme is a new token set — never a page edit.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.name,
    required this.brand,
    required this.brandSoft,
    required this.onBrand,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.line,
    required this.lineSoft,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.categories,
    required this.shadow,
    required this.gradient,
    required this.glow,
    required this.glass,
    required this.glassStrong,
    required this.glassBorder,
    required this.chip,
    required this.onChip,
  });

  final String name;

  /// Primary brand colour — buttons, active states, progress fills.
  final Color brand;

  /// Tinted brand wash for icon chips and selected surfaces.
  final Color brandSoft;
  final Color onBrand;

  /// 主行动色。按钮、进度、选中块用它，不是 [brand]。
  ///
  /// 分成两个是因为亮黄在白底上做文字读不出来（对比度约 1.7:1），
  /// 而海蓝做大色块又太重。所以：黄管"按下去会发生什么"，蓝管"这行字能点"。
  final Color accent;

  /// 亮黄的浅底，用在当前项那一行。
  final Color accentSoft;

  /// 压在 [accent] 上的文字色。
  final Color onAccent;

  /// Page background, one step darker/lighter than [surface].
  final Color bg;
  final Color surface;
  final Color surfaceAlt;

  final Color text;
  final Color textSoft;
  final Color muted;

  /// Solid hairline and the dashed/very quiet variant.
  final Color line;
  final Color lineSoft;

  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;

  /// Per-category accent, keyed by category id (yanyu, shuliang, …).
  final Map<String, Color> categories;

  final List<BoxShadow> shadow;

  /// Ambient page backdrop: a soft vertical wash behind every screen.
  final List<Color> gradient;

  /// Colour of the blurred light blob painted over the backdrop.
  final Color glow;

  /// Frosted panel fill (translucent — always sits on [gradient]).
  final Color glass;

  /// Denser frosted fill for panels that carry dense content.
  final Color glassStrong;
  final Color glassBorder;

  /// Tonal chip over the backdrop (the 米家-style status tiles).
  final Color chip;
  final Color onChip;

  Color category(String key) => categories[key] ?? brand;

  @override
  AppTokens copyWith({
    String? name,
    Color? brand,
    Color? brandSoft,
    Color? onBrand,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? textSoft,
    Color? muted,
    Color? line,
    Color? lineSoft,
    Color? success,
    Color? successSoft,
    Color? danger,
    Color? dangerSoft,
    Map<String, Color>? categories,
    List<BoxShadow>? shadow,
    List<Color>? gradient,
    Color? glow,
    Color? glass,
    Color? glassStrong,
    Color? glassBorder,
    Color? chip,
    Color? onChip,
  }) {
    return AppTokens(
      gradient: gradient ?? this.gradient,
      glow: glow ?? this.glow,
      glass: glass ?? this.glass,
      glassStrong: glassStrong ?? this.glassStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      chip: chip ?? this.chip,
      onChip: onChip ?? this.onChip,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrand: onBrand ?? this.onBrand,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      text: text ?? this.text,
      textSoft: textSoft ?? this.textSoft,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      categories: categories ?? this.categories,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      gradient: [
        for (var i = 0; i < gradient.length; i++)
          c(gradient[i], other.gradient[i.clamp(0, other.gradient.length - 1)]),
      ],
      glow: c(glow, other.glow),
      glass: c(glass, other.glass),
      glassStrong: c(glassStrong, other.glassStrong),
      glassBorder: c(glassBorder, other.glassBorder),
      chip: c(chip, other.chip),
      onChip: c(onChip, other.onChip),
      name: t < 0.5 ? name : other.name,
      brand: c(brand, other.brand),
      brandSoft: c(brandSoft, other.brandSoft),
      onBrand: c(onBrand, other.onBrand),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccent: c(onAccent, other.onAccent),
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      text: c(text, other.text),
      textSoft: c(textSoft, other.textSoft),
      muted: c(muted, other.muted),
      line: c(line, other.line),
      lineSoft: c(lineSoft, other.lineSoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      categories: {
        for (final entry in categories.entries)
          entry.key: c(entry.value, other.categories[entry.key] ?? entry.value),
      },
      shadow: t < 0.5 ? shadow : other.shadow,
    );
  }

  /// Light: lavender-tinted canvas, white surfaces, indigo brand.
  static const light = AppTokens(
    name: 'light',
    accent: Color(0xFFFFC94A),
    accentSoft: Color(0xFFFFF6E0),
    onAccent: Color(0xFF4A3410),
    brand: Color(0xFF1B8FD1),
    brandSoft: Color(0xFFE3F2FA),
    onBrand: Colors.white,
    bg: Color(0xFFF2F8FC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEAF2F7),
    text: Color(0xFF16232E),
    textSoft: Color(0xFF4A5866),
    muted: Color(0xFF7A8B99),
    line: Color(0xFFD3DDE5),
    lineSoft: Color(0xFFE1EBF2),
    success: Color(0xFF12A06B),
    successSoft: Color(0xFFE7F7EF),
    danger: Color(0xFFE2483D),
    dangerSoft: Color(0xFFFDEFEC),
    categories: {
      'yanyu': Color(0xFF2E6FD9),
      'shuliang': Color(0xFFE5941F),
      'panduan': Color(0xFF7A5CD0),
      'ziliao': Color(0xFF109C93),
      'changshi': Color(0xFFD9506F),
    },
    shadow: [
      BoxShadow(color: Color(0x121A4266), blurRadius: 26, offset: Offset(0, 10)),
    ],
    // 米家's sky: real colour up top, dissolving to near-white at the bottom.
    gradient: [Color(0xFFEAF3FA), Color(0xFFF0F6FB), Color(0xFFF2F8FC)],
    glow: Color(0x80FFFFFF),
    glass: Color(0x8AFFFFFF),
    glassStrong: Color(0xCCFFFFFF),
    glassBorder: Color(0xA6FFFFFF),
    chip: Color(0xA62E4560),
    onChip: Color(0xFFFFFFFF),
  );

  /// Dark: deep slate canvas, violet brand, same semantic roles.
  static const dark = AppTokens(
    name: 'dark',
    accent: Color(0xFFFFC94A),
    accentSoft: Color(0xFF3A3016),
    onAccent: Color(0xFF241A05),
    brand: Color(0xFF5C9DFF),
    brandSoft: Color(0xFF17263D),
    onBrand: Colors.white,
    bg: Color(0xFF0F1116),
    surface: Color(0xFF1C212B),
    surfaceAlt: Color(0xFF262C38),
    text: Color(0xFFF2F3F7),
    textSoft: Color(0xFFC3C6D1),
    muted: Color(0xFF858A99),
    line: Color(0xFF353B48),
    lineSoft: Color(0xFF272C36),
    success: Color(0xFF35C48D),
    successSoft: Color(0xFF16302A),
    danger: Color(0xFFFF6B5E),
    dangerSoft: Color(0xFF34211F),
    categories: {
      'yanyu': Color(0xFF62A5FF),
      'shuliang': Color(0xFFF0A83F),
      'panduan': Color(0xFF9E86F0),
      'ziliao': Color(0xFF3EC4B8),
      'changshi': Color(0xFFF06A8B),
    },
    shadow: [
      BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 10)),
    ],
    gradient: [Color(0xFF141821), Color(0xFF11151C), Color(0xFF0F1116)],
    glow: Color(0x3D5C9DFF),
    glass: Color(0x14FFFFFF),
    glassStrong: Color(0x1FFFFFFF),
    glassBorder: Color(0x1AFFFFFF),
    chip: Color(0x33FFFFFF),
    onChip: Color(0xFFF2F3F7),
  );

  /// 咕咕嘎嘎 — charcoal penguin suit + warm yellow beak accents.
  static const guga = AppTokens(
    name: 'guga',
    accent: Color(0xFFFFC94A),
    accentSoft: Color(0xFFFFF6E0),
    onAccent: Color(0xFF4A3410),
    brand: Color(0xFFF0A429),
    brandSoft: Color(0xFFFFF1D6),
    onBrand: Color(0xFF1A1A1C),
    bg: Color(0xFFF4F4F6),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFECECEF),
    text: Color(0xFF1C1C1E),
    textSoft: Color(0xFF4A4A4F),
    muted: Color(0xFF8E8E96),
    line: Color(0xFFD8D8DE),
    lineSoft: Color(0xFFE8E8ED),
    success: Color(0xFF2FA36B),
    successSoft: Color(0xFFE6F6EE),
    danger: Color(0xFFE2554A),
    dangerSoft: Color(0xFFFDECEA),
    categories: {
      'yanyu': Color(0xFF3D7CC9),
      'shuliang': Color(0xFFF0A429),
      'panduan': Color(0xFF6B5CAD),
      'ziliao': Color(0xFF2A9B94),
      'changshi': Color(0xFFD45B78),
    },
    shadow: [
      BoxShadow(color: Color(0x18121A2B), blurRadius: 22, offset: Offset(0, 10)),
    ],
    gradient: [Color(0xFFE8E8EC), Color(0xFFF3F3F5), Color(0xFFFAFAFB)],
    glow: Color(0x66FFFFFF),
    glass: Color(0xB8FFFFFF),
    glassStrong: Color(0xE0FFFFFF),
    glassBorder: Color(0xA6FFFFFF),
    chip: Color(0xA62C2C2E),
    onChip: Color(0xFFFFFFFF),
  );

  /// 皮卡丘黄 — sunny yellow companion theme (original fox mascot + lightning).
  static const spark = AppTokens(
    name: 'spark',
    accent: Color(0xFFFFC94A),
    accentSoft: Color(0xFFFFF6E0),
    onAccent: Color(0xFF4A3410),
    brand: Color(0xFFF0B429),
    brandSoft: Color(0xFFFFF0C8),
    onBrand: Color(0xFF3A2A00),
    bg: Color(0xFFFFFBF2),
    surface: Color(0xFFFFFFF8),
    surfaceAlt: Color(0xFFFFF4DC),
    text: Color(0xFF2A2418),
    textSoft: Color(0xFF5C5344),
    muted: Color(0xFFA09480),
    line: Color(0xFFE8D9B0),
    lineSoft: Color(0xFFF3E8C8),
    success: Color(0xFF2FA36B),
    successSoft: Color(0xFFE6F6EE),
    danger: Color(0xFFE85D4C),
    dangerSoft: Color(0xFFFDECEA),
    categories: {
      'yanyu': Color(0xFFE8A317),
      'shuliang': Color(0xFF4A8FD8),
      'panduan': Color(0xFFF07850),
      'ziliao': Color(0xFF3CB89A),
      'changshi': Color(0xFFE85D4C),
    },
    shadow: [
      BoxShadow(color: Color(0x1AF0A800), blurRadius: 22, offset: Offset(0, 10)),
    ],
    gradient: [Color(0xFFFFE6A8), Color(0xFFFFF3D4), Color(0xFFFFFBF2)],
    glow: Color(0x80FFFFFF),
    glass: Color(0xBFFFFFFF),
    glassStrong: Color(0xE6FFFFFF),
    glassBorder: Color(0xB3FFFFFF),
    chip: Color(0xA65C4A1A),
    onChip: Color(0xFFFFFFF8),
  );
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
