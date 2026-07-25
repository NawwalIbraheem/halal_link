import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import 'discover_screen.dart';
import 'structured_compatibility_chat_screen.dart';

class MatchConfirmationScreen extends StatelessWidget {
  const MatchConfirmationScreen({
    super.key,
    required this.currentUser,
    required this.matchedUser,
    required this.matchInterestId,
  });

  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> matchedUser;
  final int matchInterestId;

  @override
  Widget build(BuildContext context) {
    final currentUserName =
        (currentUser['full_name'] as String? ?? 'You').trim();
    final matchedUserName =
        (matchedUser['full_name'] as String? ?? 'Nikah Link member').trim();
    final currentUserPhoto = _decodePhoto(
      (currentUser['profile_photo_base64'] as String? ?? '').trim(),
    );
    final matchedUserPhoto = _decodePhoto(
      (matchedUser['profile_photo_base64'] as String? ?? '').trim(),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 6,
                left: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const DiscoverScreen(initialTabIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(29, 53, 39, 0.08),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xffd9b65d),
                            size: 18,
                          ),
                          const SizedBox(height: 10),
                          Image.asset(
                            'lib/assets/images/nikah_link_icon_green.png',
                            width: 56,
                            height: 56,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'You have a new match!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff18201e),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 276,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MatchProfileCard(
                                        name: currentUserName,
                                        label: 'You',
                                        photoBytes: currentUserPhoto,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: _MatchProfileCard(
                                        name: matchedUserName,
                                        label: 'Your match',
                                        photoBytes: matchedUserPhoto,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.12),
                                        blurRadius: 18,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'You and $matchedUserName have shown mutual interest.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1f2825),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Take the next step and get to know each other better.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xff697176),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StructuredCompatibilityChatScreen(
                                      matchedUserName: matchedUserName,
                                      matchInterestId: matchInterestId,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Start structured conversation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const DiscoverScreen(initialTabIndex: 0),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryGreen,
                                minimumSize: const Size.fromHeight(56),
                                side: const BorderSide(color: Color(0xffd6dfd7)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Keep browsing',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List? _decodePhoto(String encodedValue) {
    if (encodedValue.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encodedValue);
    } catch (_) {
      return null;
    }
  }
}

class _MatchProfileCard extends StatelessWidget {
  const _MatchProfileCard({
    required this.name,
    required this.label,
    required this.photoBytes,
  });

  final String name;
  final String label;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xfff7faf7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xffe1e9e2)),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 0.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: photoBytes == null
                  ? Container(
                      color: const Color(0xffe9f0ea),
                      alignment: Alignment.center,
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : Image.memory(
                      photoBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xff24312d),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
