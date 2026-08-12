import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/auth_session_store.dart';
import 'discover_screen.dart';
import 'match_confirmation_screen.dart';
import 'structured_compatibility_chat_screen.dart';

class PublicProfileViewScreen extends StatefulWidget {
  const PublicProfileViewScreen({
    super.key,
    required this.profile,
    this.fromMatches = false,
    this.matchInterestId,
    this.relationshipStatus,
  });

  final Map<String, dynamic> profile;
  final bool fromMatches;
  final int? matchInterestId;
  final String? relationshipStatus;

  @override
  State<PublicProfileViewScreen> createState() =>
      _PublicProfileViewScreenState();
}

class _PublicProfileViewScreenState extends State<PublicProfileViewScreen> {
  Map<String, dynamic>? _profileDetail;
  bool _isLoading = true;
  bool _isSendingInterest = false;
  bool _isRespondingToMatch = false;
  late String _relationshipStatus;
  int? _activeMatchInterestId;

  @override
  void initState() {
    super.initState();
    _relationshipStatus =
        (widget.relationshipStatus ??
                widget.profile['relationship_status'] as String? ??
                '')
            .trim();
    _activeMatchInterestId =
        widget.matchInterestId ?? widget.profile['match_interest_id'] as int?;
    _loadProfileDetail();
  }

  void _handleBackNavigation() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(_relationshipStatus);
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const DiscoverScreen()),
    );
  }

  Future<void> _loadProfileDetail() async {
    try {
      final id = widget.profile['id'] as int?;
      if (id == null) {
        throw Exception('Profile id is missing.');
      }

      final detail = await ProfileApiService.getPublicAccountDetail(id);
      if (!mounted) {
        return;
      }

      setState(() {
        _profileDetail = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _profileDetail = Map<String, dynamic>.from(widget.profile);
        _isLoading = false;
      });
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _respondToMatch({required bool accept}) async {
    if (_isRespondingToMatch) {
      return;
    }

    final matchInterestId = widget.matchInterestId;
    final activeMatchInterestId = matchInterestId ?? _activeMatchInterestId;
    if (activeMatchInterestId == null) {
      AppSnackbar.show(context, 'Match request is missing.');
      return;
    }

    setState(() {
      _isRespondingToMatch = true;
    });

    try {
      final response = await ProfileApiService.respondToInterest(
        matchInterestId: activeMatchInterestId,
        accept: accept,
      );

      if (!mounted) {
        return;
      }

      if (!accept) {
        AppSnackbar.show(
          context,
          (response['message'] as String? ?? 'Match declined successfully.').trim(),
        );
        Navigator.of(context).pop('declined');
        return;
      }

      setState(() {
        _relationshipStatus = 'accepted';
      });

      await AuthSessionStore.load();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchConfirmationScreen(
            currentUser: AuthSessionStore.user,
            matchedUser: _profileDetail ?? widget.profile,
            matchInterestId: activeMatchInterestId,
          ),
          settings: const RouteSettings(name: 'match_confirmation'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRespondingToMatch = false;
        });
      }
    }
  }

  int? _calculateAge(String dateText) {
    if (dateText.trim().isEmpty) {
      return null;
    }

    final date = DateTime.tryParse(dateText);
    if (date == null) {
      return null;
    }

    final now = DateTime.now();
    var age = now.year - date.year;
    final birthdayHasPassed =
        now.month > date.month ||
        (now.month == date.month && now.day >= date.day);
    if (!birthdayHasPassed) {
      age -= 1;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileDetail ?? widget.profile;
    final fullName =
        (profile['full_name'] as String? ?? 'Nikah Link member').trim();
    final location = (profile['location'] as String? ?? '').trim();
    final education = (profile['education'] as String? ?? '').trim();
    final occupation = (profile['occupation'] as String? ?? '').trim();
    final aboutMe = (profile['about_me'] as String? ?? '').trim();
    final prayerLevel =
        (profile['prayer_level_display'] as String? ?? 'Not shared yet').trim();
    final quranFocus =
        (profile['quran_focus_display'] as String? ?? 'Not shared yet').trim();
    final islamicGoals = (profile['islamic_goals_display'] as String? ??
            'To please Allah and build a strong Islamic home.')
        .trim();
    final dateOfBirth = profile['date_of_birth']?.toString() ?? '';
    final age = _calculateAge(dateOfBirth);
    final isVerified = profile['is_verified'] as bool? ?? false;
    final profilePhotoBase64 =
        (profile['profile_photo_base64'] as String? ?? '').trim();
    final canViewPhoto = profile['can_view_photo'] as bool? ?? profilePhotoBase64.isNotEmpty;
    final profilePhotoBytes = _decodePhoto(profilePhotoBase64);
    final isPendingReceived = widget.fromMatches && _relationshipStatus == 'pending_received';
    final isAccepted = _relationshipStatus == 'accepted';
    final isSent = _relationshipStatus == 'pending_sent';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(29, 53, 39, 0.08),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 250,
                                width: double.infinity,
                                child: Image.asset(
                                  'lib/assets/images/Mosque Skyline 3.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        const Color.fromRGBO(0, 0, 0, 0.22),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Material(
                                  color: const Color.fromRGBO(255, 255, 255, 0.18),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    onTap: _handleBackNavigation,
                                    customBorder: const CircleBorder(),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 18,
                                right: 18,
                                child: Row(
                                  children: [
                                    _TopOverlayIcon(icon: Icons.search_rounded),
                                    const SizedBox(width: 10),
                                    _TopOverlayIcon(icon: Icons.bookmark_border),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 88,
                                          height: 88,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                  0,
                                                  0,
                                                  0,
                                                  0.18,
                                                ),
                                                blurRadius: 16,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 41,
                                            backgroundColor:
                                                const Color(0xffeef2ed),
                                            backgroundImage:
                                                profilePhotoBytes == null
                                                ? null
                                                : MemoryImage(profilePhotoBytes),
                                            child: profilePhotoBytes == null
                                                ? Text(
                                                    fullName.isEmpty
                                                        ? '?'
                                                        : fullName[0]
                                                              .toUpperCase(),
                                                    style: const TextStyle(
                                                      color: AppColors.primaryGreen,
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!canViewPhoto) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                            255,
                                            255,
                                            255,
                                            0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.28,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock_outline_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Photo visible to approved matches',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            age == null
                                                ? fullName
                                                : '$fullName, $age',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        if (isVerified)
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: Color(0xff2ec98d),
                                            size: 22,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      location.isEmpty
                                          ? 'Nikah Link community'
                                          : location,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About me',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff19201f),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                aboutMe.isEmpty
                                    ? 'I am looking for a sincere Muslim partner to build a peaceful Islamic home.'
                                    : aboutMe,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xff596166),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Divider(color: Color(0xffe9e3d9), height: 1),
                              const SizedBox(height: 18),
                              const Text(
                                'Islamic profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff19201f),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoRow(
                                icon: Icons.mosque_outlined,
                                label: 'Prays',
                                value: prayerLevel,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoRow(
                                icon: Icons.menu_book_rounded,
                                label: 'Quran',
                                value: quranFocus,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoRow(
                                icon: Icons.flag_outlined,
                                label: 'Islamic goals',
                                value: islamicGoals,
                                multiline: true,
                              ),
                              const SizedBox(height: 18),
                              const Divider(color: Color(0xffe9e3d9), height: 1),
                              const SizedBox(height: 18),
                              const Text(
                                'Education & career',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff19201f),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryPill(
                                      icon: Icons.school_outlined,
                                      text: education.isEmpty
                                          ? 'Not shared yet'
                                          : education,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _SummaryPill(
                                      icon: Icons.work_outline_rounded,
                                      text: occupation.isEmpty
                                          ? 'Not shared yet'
                                          : occupation,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              isPendingReceived
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _isRespondingToMatch
                                                ? null
                                                : () => _respondToMatch(
                                                      accept: false,
                                                    ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xffc25050),
                                              side: const BorderSide(
                                                color: Color(0xffe8caca),
                                              ),
                                              minimumSize:
                                                  const Size.fromHeight(54),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: const Text(
                                              'Decline',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isRespondingToMatch
                                                ? null
                                                : () => _respondToMatch(
                                                      accept: true,
                                                    ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryGreen,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              minimumSize:
                                                  const Size.fromHeight(54),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: _isRespondingToMatch
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.3,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Accept',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : isAccepted
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                              1,
                                              68,
                                              51,
                                              0.08,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'Accepted',
                                            style: TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      StructuredCompatibilityChatScreen(
                                                    matchedUserName: fullName,
                                                    matchInterestId:
                                                        _activeMatchInterestId!,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryGreen,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              minimumSize:
                                                  const Size.fromHeight(54),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: const Text(
                                              'Go to structured questions',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isSendingInterest || isSent
                                                ? null
                                                : () => _sendInterest(fullName),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryGreen,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              minimumSize:
                                                  const Size.fromHeight(54),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: _isSendingInterest
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.3,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : Text(
                                                    isSent ? 'Sent' : 'Send interest',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xffd8e0d9),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.bookmark_border_rounded,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Future<void> _sendInterest(String fullName) async {
    if (_isSendingInterest) {
      return;
    }

    final id = widget.profile['id'] as int?;
    if (id == null) {
      AppSnackbar.show(context, 'Profile id is missing.');
      return;
    }

    setState(() {
      _isSendingInterest = true;
    });

    try {
      final response = await ProfileApiService.sendInterest(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _relationshipStatus =
            (response['relationship_status'] as String? ?? 'pending_sent').trim();
        _activeMatchInterestId = response['match_interest_id'] as int?;
      });
      AppSnackbar.show(
        context,
        (response['message'] as String? ?? 'Interest sent to $fullName.').trim(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingInterest = false;
        });
      }
    }
  }
}

class _TopOverlayIcon extends StatelessWidget {
  const _TopOverlayIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xff4b5a55)),
        const SizedBox(width: 10),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff26322e),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff6f1e6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff26322e),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
