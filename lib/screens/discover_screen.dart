import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/profile_api_service.dart';
import '../utils/auth_session_store.dart';
import 'public_profile_view_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final List<Map<String, dynamic>> _profiles = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _matchedProfiles = <Map<String, dynamic>>[];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
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
    final alreadyMatched = _matchedProfiles.any(
      (item) => item['id'] == profile['id'],
    );

    if (!alreadyMatched) {
      _matchedProfiles.add(profile);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadyMatched
              ? 'You already liked ${profile['full_name']}.'
              : 'You liked ${profile['full_name']}. Match flow can be connected next.',
        ),
      ),
    );
    _showNextProfile();
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfffaf7f0),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
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
                          const Expanded(
                            child: Text(
                              'Nikah Link',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          _HeaderCircleButton(
                            icon: Icons.search_rounded,
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          _HeaderCircleButton(
                            icon: Icons.tune_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: profile == null
                            ? _EmptyDiscoverState(onRefresh: _loadProfiles)
                            : Container(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
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
                                                          begin:
                                                              Alignment.topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            const Color.fromRGBO(
                                                              0,
                                                              0,
                                                              0,
                                                              0.18,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 18,
                                                    right: 18,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            const Color.fromRGBO(
                                                              255,
                                                              255,
                                                              255,
                                                              0.24,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'New here',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    20,
                                                    18,
                                                    20,
                                                    22,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 14),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: _buildHighlights(
                                                      profile,
                                                    ).map((item) {
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 7,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              const Color.fromRGBO(
                                                                1,
                                                                68,
                                                                51,
                                                                0.08,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                999,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          item,
                                                          style: const TextStyle(
                                                            color:
                                                                AppColors
                                                                    .primaryGreen,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
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
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        0,
                                        18,
                                        18,
                                      ),
                                      child: Row(
                                        children: [
                                          _ActionCircleButton(
                                            icon: Icons.close_rounded,
                                            color: const Color(0xffdc5f5f),
                                            backgroundColor:
                                                const Color(0xfffff2f2),
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
                                                    builder: (_) =>
                                                        PublicProfileViewScreen(
                                                          profile: profile,
                                                        ),
                                                  ),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.primaryGreen,
                                                side: const BorderSide(
                                                  color: Color(0xffd5dfd6),
                                                ),
                                                minimumSize:
                                                    const Size.fromHeight(58),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
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
                              ),
                      ),
                      const SizedBox(height: 16),
                      _BottomNavBar(matchCount: _matchedProfiles.length),
                    ],
                  ),
                ),
        ),
      ),
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
  const _BottomNavBar({required this.matchCount});

  final int matchCount;

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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.travel_explore_rounded,
            label: 'Discover',
            active: true,
          ),
          _NavItem(
            icon: Icons.favorite_border_rounded,
            label: 'Matches',
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
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
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryGreen : const Color(0xff868e94);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
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
    );
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
