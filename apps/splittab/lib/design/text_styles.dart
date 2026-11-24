import 'package:material_ui/material_ui.dart';

/// The named text styles. Every piece of text in the app uses one of these.
/// Sizes and line heights come from the type scale; weights are Regular 400, Medium 500, Semibold 600.
abstract final class AppText {
  static const String family = 'Geist';

  static TextStyle _s(double size, double lineHeight, int weight) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    fontStyle: FontStyle.normal,
  );

  // Headings (Semibold)
  static final heading1 = _s(60, 60, 600);
  static final heading2 = _s(48, 48, 600);
  static final heading3 = _s(36, 40, 600);
  static final heading4 = _s(30, 36, 600);
  static final heading5 = _s(24, 32, 600);
  static final heading6 = _s(20, 28, 600);

  // Titles (Medium)
  static final title1 = _s(20, 28, 500);
  static final title2 = _s(18, 28, 500);
  static final title3 = _s(16, 24, 500);
  static final title4 = _s(14, 20, 500);
  static final title5 = _s(12, 16, 500);

  // Body
  static final body1 = _s(16, 24, 600);
  static final body2 = _s(16, 24, 500);
  static final body3 = _s(16, 24, 400);
  static final body4 = _s(14, 20, 600);
  static final body5 = _s(14, 20, 500);
  static final body6 = _s(14, 20, 400);

  // Buttons (Semibold)
  static final buttonLg = _s(18, 28, 600);
  static final buttonMd = _s(16, 24, 600);
  static final buttonSm = _s(14, 20, 600);
  static final buttonXsm = _s(12, 16, 600);

  // Captions
  static final caption1 = _s(14, 20, 500);
  static final caption2 = _s(14, 20, 400);
  static final caption3 = _s(12, 16, 600);
  static final caption4 = _s(12, 16, 500);
  static final caption5 = _s(12, 16, 400);

  /// Numbers line up in columns when they are tabular.
  static TextStyle numeric(TextStyle base) =>
      base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
