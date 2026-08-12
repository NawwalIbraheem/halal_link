import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/profile_api_service.dart';
import '../utils/auth_session_store.dart';
import 'discover_screen.dart';
import 'login_screen.dart';
import 'profile_setup_basic_info_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _routeFromSavedSession);
  }

  Future<void> _routeFromSavedSession() async {
    await AuthSessionStore.load();
    if (!mounted) {
      return;
    }

    if (AuthSessionStore.accessToken.trim().isEmpty) {
      _openScreen(const LoginScreen());
      return;
    }

    try {
      await ProfileApiService.getBasicProfile();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _openScreen(const LoginScreen());
      return;
    }

    if (!mounted) {
      return;
    }

    final hasCompletedProfile = await _hasCompletedProfileSetup();
    if (!mounted) {
      return;
    }

    _openScreen(
      hasCompletedProfile
          ? const DiscoverScreen()
          : const ProfileSetupBasicInfoScreen(),
    );
  }

  Future<bool> _hasCompletedProfileSetup() async {
    final user = AuthSessionStore.user;
    final hasBasicInfo =
        (user['date_of_birth']?.toString().trim().isNotEmpty ?? false) &&
        ((user['location'] as String? ?? '').trim().isNotEmpty) &&
        ((user['education'] as String? ?? '').trim().isNotEmpty) &&
        ((user['occupation'] as String? ?? '').trim().isNotEmpty) &&
        ((user['languages'] as String? ?? '').trim().isNotEmpty);

    if (!hasBasicInfo) {
      return false;
    }

    try {
      final islamic = await ProfileApiService.getIslamicProfile();
      final marriage = await ProfileApiService.getMarriageExpectations();
      final lifestyle = await ProfileApiService.getLifestyleProfile();

      final hasIslamicProfile =
          (islamic['prayer_level'] as String? ?? '').trim().isNotEmpty &&
          (islamic['quran_activity'] as String? ?? '').trim().isNotEmpty &&
          (islamic['quran_frequency'] as String? ?? '').trim().isNotEmpty &&
          (islamic['islamic_goals'] as String? ?? '').trim().isNotEmpty &&
          ((islamic['marriage_values'] as List<dynamic>? ?? []).isNotEmpty);

      final hasMarriageExpectations =
          (marriage['qualities_looking_for'] as String? ?? '').trim().isNotEmpty &&
          (marriage['marriage_timeline'] as String? ?? '').trim().isNotEmpty &&
          (marriage['children_preference'] as String? ?? '').trim().isNotEmpty &&
          (marriage['preferred_living_arrangement'] as String? ?? '')
              .trim()
              .isNotEmpty &&
          (marriage['family_involvement'] as String? ?? '').trim().isNotEmpty;

      final hasLifestyleProfile =
          (lifestyle['height_range'] as String? ?? '').trim().isNotEmpty &&
          (lifestyle['body_type'] as String? ?? '').trim().isNotEmpty &&
          (lifestyle['cultural_background'] as String? ?? '').trim().isNotEmpty &&
          (lifestyle['dress_style'] as String? ?? '').trim().isNotEmpty;

      return hasIslamicProfile &&
          hasMarriageExpectations &&
          hasLifestyleProfile;
    } catch (_) {
      return false;
    }
  }

  void _openScreen(Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.2),
                      radius: 1.12,
                      colors: [
                        Color(0xff0d6b52),
                        AppColors.primaryGreen,
                        Color(0xff022b22),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'lib/assets/images/Mosque Skyline.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color.fromRGBO(0, 0, 0, 0.22),
                        ],
                        stops: [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'lib/assets/images/nikah_link_icon.png',
                          width: width * 0.34,
                          height: width * 0.34,
                        ),
                        SizedBox(height: height * 0.02),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Nikah ',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              TextSpan(
                                text: 'Link',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: width * 0.09,
                              height: 1.5,
                              color: const Color.fromRGBO(200, 155, 36, 0.85),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Halal Connections. Lifelong Commitment.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: width * 0.09,
                              height: 1.5,
                              color: const Color.fromRGBO(200, 155, 36, 0.85),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: height * 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                        child: Image.asset(
                          'lib/assets/images/Masjid.png',
                          fit: BoxFit.fitWidth,
                          width: double.infinity,
                          opacity: const AlwaysStoppedAnimation(0.92),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Icon(
                        Icons.favorite,
                        color: AppColors.gold,
                        size: 18,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connecting hearts.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Building halal marriages.',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
