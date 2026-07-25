import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'constants/app_theme.dart';
import 'screens/splash_screen.dart';
import 'utils/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsController.instance.load();

  runApp(
    const NikahLinkApp(),
  );
}

class NikahLinkApp extends StatelessWidget {
  const NikahLinkApp({super.key});

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
          theme: ThemeData(
            fontFamily: 'Poppins',
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppThemeColors.lightBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryGreen,
              brightness: Brightness.light,
            ),
            cardColor: AppThemeColors.lightSurface,
            canvasColor: AppThemeColors.lightSurface,
            dividerColor: AppThemeColors.lightBorder,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppThemeColors.lightBackground,
              foregroundColor: AppThemeColors.lightText,
              elevation: 0,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: AppThemeColors.lightSurface,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppThemeColors.lightSurface,
              hintStyle: const TextStyle(color: AppThemeColors.lightTextMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppThemeColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppThemeColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
          darkTheme: ThemeData(
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppThemeColors.darkBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff0f8a6b),
              brightness: Brightness.dark,
            ),
            cardColor: AppThemeColors.darkSurface,
            canvasColor: AppThemeColors.darkSurface,
            dividerColor: AppThemeColors.darkBorder,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppThemeColors.darkBackground,
              foregroundColor: AppThemeColors.darkText,
              elevation: 0,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: AppThemeColors.darkSurface,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppThemeColors.darkSurface,
              hintStyle: const TextStyle(color: AppThemeColors.darkTextMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppThemeColors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppThemeColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
          home: SplashScreen(),
        );
      },
    );
  }
}
