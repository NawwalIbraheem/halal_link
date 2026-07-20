import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../constants/app_colors.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/auth_session_store.dart';
import 'public_profile_view_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final List<Map<String, dynamic>> _profiles = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _receivedInterests = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isMatchesLoading = true;
  int _currentIndex = 0;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait(<Future<void>>[
      _loadProfiles(),
      _loadReceivedInterests(),
    ]);
  }

  Future<void> _loadProfiles() async {
    try {
      await AuthSessionStore.load();
      final profiles = await ProfileApiService.getPublicAccounts();
      final currentUserEmail =
          (AuthSessionStore.user['email'] as String? ?? '').trim().toLowerCase();
      final currentUserName =
          (AuthSessionStore.user['full_name'] as String? ?? '').trim();

      final filtered = profiles.where((profile) {
        final email = (profile['email'] as String? ?? '').trim().toLowerCase();
        final fullName = (profile['full_name'] as String? ?? '').trim();

        if (currentUserEmail.isNotEmpty && email == currentUserEmail) {
          return false;
        }
        if (email.isEmpty && currentUserName.isNotEmpty && fullName == currentUserName) {
          return false;
        }
        return true;
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _profiles
          ..clear()
          ..addAll(filtered);
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _loadReceivedInterests() async {
    try {
      await AuthSessionStore.load();
      final interests = await ProfileApiService.getReceivedInterests();

      if (!mounted) {
        return;
      }

      setState(() {
        _receivedInterests
          ..clear()
          ..addAll(interests);
        _isMatchesLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMatchesLoading = false;
      });
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showNextProfile() {
    if (_profiles.isEmpty) {
      return;
    }

    setState(() {
      if (_currentIndex < _profiles.length - 1) {
        _currentIndex += 1;
      } else {
        _currentIndex = 0;
      }
    });
  }

  void _handlePass() {
    if (_profiles.isEmpty) {
      return;
    }

    _showNextProfile();
  }

  void _handleLike() {
    if (_profiles.isEmpty) {
      return;
    }

    final profile = _profiles[_currentIndex];
    AppSnackbar.show(context, 'Open the profile to send interest to ${profile['full_name']}.');
    _showNextProfile();
  }

  void _handleTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    if (index == 1 && _receivedInterests.isEmpty && !_isMatchesLoading) {
      setState(() {
        _isMatchesLoading = true;
      });
      _loadReceivedInterests();
    }
  }

  String _formatHeadline(Map<String, dynamic> profile) {
    final name = (profile['full_name'] as String? ?? 'Nikah Link member').trim();
    final dateOfBirth = profile['date_of_birth']?.toString() ?? '';
    final age = _calculateAge(dateOfBirth);

    return age == null ? name : '$name, $age';
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

  String _buildSubtitle(Map<String, dynamic> profile) {
    final location = (profile['location'] as String? ?? '').trim();
    final distance = _mockDistance(profile);
    if (location.isEmpty) {
      return distance;
    }
    return '$location  •  $distance away';
  }

  String _mockDistance(Map<String, dynamic> profile) {
    final id = (profile['id'] as int? ?? 0);
    final distances = ['2 km', '4 km', '6 km', '8 km', '11 km'];
    return distances[id % distances.length];
  }

  List<String> _buildHighlights(Map<String, dynamic> profile) {
    final highlights = <String>[];
    final occupation = (profile['occupation'] as String? ?? '').trim();
    final education = (profile['education'] as String? ?? '').trim();
    final languages = (profile['languages'] as String? ?? '').trim();

    if (occupation.isNotEmpty) {
      highlights.add(occupation);
    }
    if (education.isNotEmpty) {
      highlights.add(education);
    }
    if (languages.isNotEmpty) {
      highlights.add(languages.split(',').first.trim());
    }

    if (highlights.isEmpty) {
      highlights.addAll(['Practicing', 'Serious', 'Ready']);
    }

    return highlights.take(3).toList();
  }

  String _buildAbout(Map<String, dynamic> profile) {
    final occupation = (profile['occupation'] as String? ?? '').trim();
    final location = (profile['location'] as String? ?? '').trim();
    final education = (profile['education'] as String? ?? '').trim();

    final parts = <String>[];
    if (occupation.isNotEmpty) {
      parts.add('I work as a $occupation');
    }
    if (location.isNotEmpty) {
      parts.add('based in $location');
    }
    if (education.isNotEmpty) {
      parts.add('with a background in $education');
    }

    if (parts.isEmpty) {
      return 'I am here seeking a sincere Muslim partner for a serious halal marriage journey.';
    }

    return '${parts.join(', ')}. I am looking for a sincere Muslim partner to build a peaceful Islamic family.';
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profiles.isEmpty ? null : _profiles[_currentIndex];
    final body = _selectedTabIndex == 0
        ? _buildDiscoverContent(profile)
        : _buildMatchesContent();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfffaf7f0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'lib/assets/images/nikah_link_icon_green.png',
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedTabIndex == 0 ? 'Nikah Link' : 'Matches',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    _HeaderCircleButton(
                      icon: _selectedTabIndex == 0
                          ? Icons.search_rounded
                          : Icons.refresh_rounded,
                      onTap: _selectedTabIndex == 0
                          ? () {}
                          : () {
                              setState(() {
                                _isMatchesLoading = true;
                              });
                              _loadReceivedInterests();
                            },
                    ),
                    const SizedBox(width: 10),
                    _HeaderCircleButton(
                      icon: _selectedTabIndex == 0
                          ? Icons.tune_rounded
                          : Icons.favorite_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(child: body),
                const SizedBox(height: 16),
                _BottomNavBar(
                  selectedIndex: _selectedTabIndex,
                  matchCount: _receivedInterests.length,
                  onTap: _handleTabSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverContent(Map<String, dynamic>? profile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return _EmptyDiscoverState(onRefresh: _loadProfiles);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(29, 53, 39, 0.08),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 280,
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
                                  const Color.fromRGBO(0, 0, 0, 0.18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 18,
                          right: 18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'New here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatHeadline(profile),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff18201e),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildSubtitle(profile),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff6b7378),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _buildHighlights(profile).map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(1, 68, 51, 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item,
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'About me',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff18201e),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildAbout(profile),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xff576066),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                _ActionCircleButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xffdc5f5f),
                  backgroundColor: const Color(0xfffff2f2),
                  onTap: _handlePass,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PrimaryLoveButton(
                    onTap: _handleLike,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PublicProfileViewScreen(profile: profile),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(
                        color: Color(0xffd5dfd6),
                      ),
                      minimumSize: const Size.fromHeight(58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'View profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesContent() {
    if (_isMatchesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receivedInterests.isEmpty) {
      return _EmptyMatchesState(onRefresh: _loadReceivedInterests);
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _receivedInterests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final profile = _receivedInterests[index];
        return _MatchCard(profile: profile);
      },
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xff2f3b38)),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _PrimaryLoveButton extends StatelessWidget {
  const _PrimaryLoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Icon(Icons.favorite_rounded, size: 28),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.matchCount,
    required this.onTap,
  });

  final int selectedIndex;
  final int matchCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(28, 39, 33, 0.07),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.travel_explore_rounded,
            label: 'Discover',
            active: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.favorite_border_rounded,
            label: 'Matches',
            active: selectedIndex == 1,
            badgeCount: matchCount,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            active: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            active: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.badgeCount = 0,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryGreen : const Color(0xff868e94);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchesState extends StatelessWidget {
  const _EmptyMatchesState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(29, 53, 39, 0.08),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                size: 70,
                color: Color(0xff95a19a),
              ),
              const SizedBox(height: 18),
              const Text(
                'No interests yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff24312d),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'When someone sends interest to you, they will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xff687278),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final fullName =
        (profile['full_name'] as String? ?? 'Nikah Link member').trim();
    final location = (profile['location'] as String? ?? '').trim();
    final occupation = (profile['occupation'] as String? ?? '').trim();
    final education = (profile['education'] as String? ?? '').trim();
    final profilePhotoBase64 =
        (profile['profile_photo_base64'] as String? ?? '').trim();
    final profilePhotoBytes = _decodePhoto(profilePhotoBase64);
    final highlights = <String>[
      if (occupation.isNotEmpty) occupation,
      if (education.isNotEmpty) education,
      if (location.isNotEmpty) location,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(29, 53, 39, 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xffeef2ed),
                  backgroundImage:
                      profilePhotoBytes == null ? null : MemoryImage(profilePhotoBytes),
                  child: profilePhotoBytes == null
                      ? Text(
                          fullName.isEmpty ? '?' : fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff18201e),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.isEmpty ? 'Nikah Link community' : location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff6b7378),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: highlights.take(3).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(1, 68, 51, 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PublicProfileViewScreen(profile: profile),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: Color(0xffd5dfd6)),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'View profile',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
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

class _EmptyDiscoverState extends StatelessWidget {
  const _EmptyDiscoverState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 70,
              color: Color(0xff95a19a),
            ),
            const SizedBox(height: 18),
            const Text(
              'No profiles available yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xff24312d),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Once more members complete their profile, they will appear here for discovery.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xff687278),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
