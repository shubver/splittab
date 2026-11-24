import 'package:material_ui/material_ui.dart';

import 'text_styles.dart';
import 'tokens.dart';

ThemeData buildTheme(AppPalette p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    error: p.negative,
    onError: p.onAccent,
    surface: p.background,
    onSurface: p.text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    fontFamily: AppText.family,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x00000000),
    hoverColor: const Color(0x00000000),
    dividerColor: p.border,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.text,
      selectionColor: p.hover,
      selectionHandleColor: p.text,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: const Color(0x00000000),
      modalBackgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxxl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.raised,
      contentTextStyle: AppText.body5.copyWith(color: p.text),
      actionTextColor: p.text,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
        side: BorderSide(color: p.border),
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
