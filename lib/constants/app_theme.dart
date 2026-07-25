import 'package:flutter/material.dart';

class AppThemeColors {
  static const Color lightBackground = Color(0xfffaf7f0);
  static const Color lightSurface = Color(0xffffffff);
  static const Color lightSurfaceMuted = Color(0xfff6f1e8);
  static const Color lightSoft = Color(0xffeef2ed);
  static const Color lightBorder = Color(0xffddd8cc);
  static const Color lightText = Color(0xff18201e);
  static const Color lightTextMuted = Color(0xff6b7378);

  static const Color darkBackground = Color(0xff0f1715);
  static const Color darkSurface = Color(0xff18211f);
  static const Color darkSurfaceMuted = Color(0xff1f2a27);
  static const Color darkSoft = Color(0xff24312d);
  static const Color darkBorder = Color(0xff30403b);
  static const Color darkText = Color(0xfff3f4ef);
  static const Color darkTextMuted = Color(0xffb3beb8);

  static Color background(Brightness brightness) {
    return brightness == Brightness.dark ? darkBackground : lightBackground;
  }

  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  static Color surfaceMuted(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurfaceMuted : lightSurfaceMuted;
  }

  static Color soft(Brightness brightness) {
    return brightness == Brightness.dark ? darkSoft : lightSoft;
  }

  static Color border(Brightness brightness) {
    return brightness == Brightness.dark ? darkBorder : lightBorder;
  }

  static Color text(Brightness brightness) {
    return brightness == Brightness.dark ? darkText : lightText;
  }

  static Color textMuted(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextMuted : lightTextMuted;
  }
}

extension AppThemeX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get appBackground => AppThemeColors.background(Theme.of(this).brightness);
  Color get appSurface => AppThemeColors.surface(Theme.of(this).brightness);
  Color get appSurfaceMuted =>
      AppThemeColors.surfaceMuted(Theme.of(this).brightness);
  Color get appSoftSurface => AppThemeColors.soft(Theme.of(this).brightness);
  Color get appBorder => AppThemeColors.border(Theme.of(this).brightness);
  Color get appText => AppThemeColors.text(Theme.of(this).brightness);
  Color get appTextMuted => AppThemeColors.textMuted(Theme.of(this).brightness);
}
