import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'constants/app_theme.dart';
import 'screens/splash_screen.dart';
import 'utils/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    if (kDebugMode) {
      debugPrint('Firebase was not initialized on this platform.');
    }
  }
  await AppSettingsController.instance.load();

  runApp(
    const NikahLinkApp(),
  );
}

class NikahLinkApp extends StatelessWidget {
  const NikahLinkApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTheme = ThemeData(brightness: brightness);
    final baseTextTheme = GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
      displayLarge: GoogleFonts.poppins(textStyle: baseTheme.textTheme.displayLarge),
      displayMedium: GoogleFonts.poppins(textStyle: baseTheme.textTheme.displayMedium),
      displaySmall: GoogleFonts.poppins(textStyle: baseTheme.textTheme.displaySmall),
      headlineLarge: GoogleFonts.poppins(textStyle: baseTheme.textTheme.headlineLarge),
      headlineMedium: GoogleFonts.poppins(textStyle: baseTheme.textTheme.headlineMedium),
      headlineSmall: GoogleFonts.poppins(textStyle: baseTheme.textTheme.headlineSmall),
      titleLarge: GoogleFonts.poppins(textStyle: baseTheme.textTheme.titleLarge),
      titleMedium: GoogleFonts.poppins(textStyle: baseTheme.textTheme.titleMedium),
      titleSmall: GoogleFonts.poppins(textStyle: baseTheme.textTheme.titleSmall),
      bodyLarge: GoogleFonts.poppins(textStyle: baseTheme.textTheme.bodyLarge),
      bodyMedium: GoogleFonts.poppins(textStyle: baseTheme.textTheme.bodyMedium),
      bodySmall: GoogleFonts.poppins(textStyle: baseTheme.textTheme.bodySmall),
      labelLarge: GoogleFonts.poppins(textStyle: baseTheme.textTheme.labelLarge),
      labelMedium: GoogleFonts.poppins(textStyle: baseTheme.textTheme.labelMedium),
      labelSmall: GoogleFonts.poppins(textStyle: baseTheme.textTheme.labelSmall),
    ).apply(
      bodyColor: isDark ? AppThemeColors.darkText : AppThemeColors.lightText,
      displayColor: isDark ? AppThemeColors.darkText : AppThemeColors.lightText,
    );

    return ThemeData(
      brightness: brightness,
      textTheme: baseTextTheme,
      primaryTextTheme: GoogleFonts.poppinsTextTheme(baseTheme.primaryTextTheme),
      visualDensity: const VisualDensity(horizontal: -0.4, vertical: -0.4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      iconTheme: const IconThemeData(size: 22),
      scaffoldBackgroundColor:
          isDark ? AppThemeColors.darkBackground : AppThemeColors.lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xff0f8a6b) : AppColors.primaryGreen,
        brightness: brightness,
      ),
      cardColor: isDark ? AppThemeColors.darkSurface : AppThemeColors.lightSurface,
      canvasColor: isDark ? AppThemeColors.darkSurface : AppThemeColors.lightSurface,
      dividerColor: isDark ? AppThemeColors.darkBorder : AppThemeColors.lightBorder,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppThemeColors.darkBackground : AppThemeColors.lightBackground,
        foregroundColor:
            isDark ? AppThemeColors.darkText : AppThemeColors.lightText,
        elevation: 0,
        toolbarHeight: 52,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppThemeColors.darkSurface : AppThemeColors.lightSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 48),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 48),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppThemeColors.darkSurface : AppThemeColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color:
              isDark ? AppThemeColors.darkTextMuted : AppThemeColors.lightTextMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? AppThemeColors.darkBorder : AppThemeColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? AppThemeColors.darkBorder : AppThemeColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryGreen),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nikah Link',
          themeMode: settings.themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.96,
                  maxScaleFactor: 1.0,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: SplashScreen(),
        );
      },
    );
  }
}
