import 'package:material_ui/material_ui.dart';

/// Spacing scale. Only these values are used anywhere in the app.
abstract final class Space {
  static const double s0 = 0;
  static const double s25 = 2;
  static const double s50 = 4;
  static const double s75 = 8;
  static const double s100 = 12;
  static const double s200 = 16;
  static const double s300 = 24;
  static const double s400 = 32;
  static const double s500 = 40;
  static const double s600 = 48;
  static const double s700 = 64;
  static const double s800 = 80;
  static const double s900 = 96;
}

/// Corner radii (Tailwind values).
abstract final class Radii {
  static const double none = 0;
  static const double sm = 2;
  static const double base = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 24;
  static const double full = 9999;

  /// Inner radius for a shape sitting inside another one: `outer - gap`, applied when the gap is
  /// under 32 and the result is above 2. Otherwise the inner shape stays square.
  static double nested(double outer, double gap) {
    if (gap >= 32) return outer;
    final inner = outer - gap;
    return inner > 2 ? inner : 0;
  }
}

/// Motion: weighted, decelerating. Only transform and opacity move; colour shifts may use [fade].
abstract final class Motion {
  static const Curve curve = Cubic(0.22, 1, 0.36, 1);
  static const Duration layout = Duration(milliseconds: 500);
  static const Duration fade = Duration(milliseconds: 300);
  static const Duration press = Duration(milliseconds: 200);
  static const Duration reveal = Duration(milliseconds: 600);

  /// Reduced motion: no movement, only a plain opacity change.
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}

/// Flat colours. Dark mode backgrounds come from the approved list; light mode mirrors it.
class AppPalette {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color raised;
  final Color hover;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color positive;
  final Color negative;

  const AppPalette._({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.raised,
    required this.hover,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.positive,
    required this.negative,
  });

  static const dark = AppPalette._(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF181818),
    raised: Color(0xFF1F1F1F),
    hover: Color(0xFF272727),
    border: Color(0xFF313131),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFF9B9B9B),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    positive: Color(0xFF34D399),
    negative: Color(0xFFF87171),
  );

  static const light = AppPalette._(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    raised: Color(0xFFEFEFEF),
    hover: Color(0xFFE8E8E8),
    border: Color(0xFFDEDEDE),
    text: Color(0xFF000000),
    textMuted: Color(0xFF666666),
    accent: Color(0xFF000000),
    onAccent: Color(0xFFFFFFFF),
    positive: Color(0xFF047857),
    negative: Color(0xFFB91C1C),
  );
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}
