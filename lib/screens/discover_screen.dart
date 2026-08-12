import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/notification_center_service.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_settings_controller.dart';
import '../utils/auth_session_store.dart';
import 'login_screen.dart';
import 'messaging_screen.dart';
import 'notifications_screen.dart';
import 'profile_setup_basic_info_screen.dart';
import 'public_profile_view_screen.dart';
import 'structured_compatibility_chat_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final List<Map<String, dynamic>> _profiles = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _matchEntries = <Map<String, dynamic>>[];
  final List<AppNotificationItem> _notifications = <AppNotificationItem>[];
  Map<String, dynamic> _currentUserProfile = <String, dynamic>{};
  bool _isLoading = true;
  bool _isMatchesLoading = true;
  bool _isProfileLoading = true;
  bool _hasShownAcceptedMatchNotice = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait(<Future<void>>[
      _loadProfiles(),
      _loadReceivedInterests(),
      _loadCurrentUserProfile(),
    ]);
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      await AuthSessionStore.load();
      if (mounted) {
        setState(() {
          _currentUserProfile = Map<String, dynamic>.from(AuthSessionStore.user);
        });
      }

      final profile = await ProfileApiService.getBasicProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserProfile = profile;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUserProfile = Map<String, dynamic>.from(AuthSessionStore.user);
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _respondToMatchFromList({
    required int matchInterestId,
    required bool accept,
  }) async {
    try {
      final response = await ProfileApiService.respondToInterest(
        matchInterestId: matchInterestId,
        accept: accept,
      );

      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        context,
        (response['message'] as String? ??
                (accept
                    ? 'Match accepted successfully.'
                    : 'Match declined successfully.'))
            .trim(),
      );

      setState(() {
        _isLoading = true;
        _isMatchesLoading = true;
      });
      await _loadProfiles();
      await _loadReceivedInterests();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    final notifications =
        await NotificationCenterService.buildNotifications(
          matchEntries: _matchEntries,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _notifications
        ..clear()
        ..addAll(notifications);
    });
  }

  int get _unreadNotificationCount {
    final notificationsEnabled =
        AppSettingsController.instance.notificationsEnabled;
    if (!notificationsEnabled) {
      return 0;
    }
    return _notifications.where((item) => !item.isRead).length;
  }

  Future<void> _openNotifications() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          notifications: List<AppNotificationItem>.from(_notifications),
          notificationsEnabled:
              AppSettingsController.instance.notificationsEnabled,
          onMarkAllRead: () async {
            await NotificationCenterService.markAllAsRead(
              _notifications.map((item) => item.id).toList(),
            );
            await _refreshNotifications();
          },
          onNotificationOpened: (notification) async {
            await NotificationCenterService.markAsRead(notification.id);
            await _refreshNotifications();
          },
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null) {
      setState(() {
        _selectedTabIndex = result;
      });
    }
  }

  Future<void> _showThemeSettings() async {
    final controller = AppSettingsController.instance;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff18201e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose how the whole app should look.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff697176),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ThemeChoiceTile(
                    title: 'Light mode',
                    subtitle: 'Bright background and classic app colors',
                    selected: controller.themeMode == ThemeMode.light,
                    onTap: () => controller.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(height: 12),
                  _ThemeChoiceTile(
                    title: 'Dark mode',
                    subtitle: 'Dimmed interface for low-light use',
                    selected: controller.themeMode == ThemeMode.dark,
                    onTap: () => controller.setThemeMode(ThemeMode.dark),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showChatThemeSettings() async {
    final controller = AppSettingsController.instance;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chat Theme',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff18201e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Control chat font size and conversation background.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff697176),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Font size: ${controller.chatFontSize.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff18201e),
                    ),
                  ),
                  Slider(
                    value: controller.chatFontSize,
                    min: 12,
                    max: 18,
                    divisions: 6,
                    activeColor: AppColors.primaryGreen,
                    onChanged: (value) => controller.setChatFontSize(value),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chat background',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff18201e),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ChatBackgroundStyle.values.map((style) {
                      final selected = controller.chatBackgroundStyle == style;
                      return InkWell(
                        onTap: () => controller.setChatBackgroundStyle(style),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 88,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryGreen
                                  : const Color(0xffd8ddd9),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: _chatPreviewGradient(style),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _chatBackgroundLabel(style),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppColors.primaryGreen
                                      : const Color(0xff485451),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  String _themeLabel(ThemeMode mode) {
    return mode == ThemeMode.dark ? 'Dark mode' : 'Light mode';
  }

  String _chatBackgroundLabel(ChatBackgroundStyle style) {
    return switch (style) {
      ChatBackgroundStyle.warm => 'Warm',
      ChatBackgroundStyle.light => 'Light',
      ChatBackgroundStyle.sage => 'Sage',
      ChatBackgroundStyle.dark => 'Dark',
    };
  }

  LinearGradient _chatPreviewGradient(ChatBackgroundStyle style) {
    return switch (style) {
      ChatBackgroundStyle.warm => const LinearGradient(
        colors: [Color(0xffe8dec9), Color(0xfff4ecdf)],
      ),
      ChatBackgroundStyle.light => const LinearGradient(
        colors: [Color(0xffeef3f5), Color(0xffffffff)],
      ),
      ChatBackgroundStyle.sage => const LinearGradient(
        colors: [Color(0xffdfe9df), Color(0xfff2f7f0)],
      ),
      ChatBackgroundStyle.dark => const LinearGradient(
        colors: [Color(0xff1a2320), Color(0xff101715)],
      ),
    };
  }

  Future<void> _showNotificationSettings() async {
    final controller = AppSettingsController.instance;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff18201e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Control reminders and alerts from the app.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff697176),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primaryGreen,
                    title: const Text(
                      'Enable notifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff18201e),
                      ),
                    ),
                    subtitle: const Text(
                      'Receive alerts for new interests, matches, and chats',
                    ),
                    value: controller.notificationsEnabled,
                    onChanged: controller.setNotificationsEnabled,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showPrivacySettings() async {
    final controller = AppSettingsController.instance;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy & Safety',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff18201e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose what other members can see about your account.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff697176),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primaryGreen,
                    title: const Text(
                      'Show profile in discovery',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff18201e),
                      ),
                    ),
                    subtitle: const Text(
                      'Allow other members to discover your profile',
                    ),
                    value: controller.profileVisible,
                    onChanged: controller.setProfileVisible,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primaryGreen,
                    title: const Text(
                      'Show online status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff18201e),
                      ),
                    ),
                    subtitle: const Text(
                      'Let accepted matches see when you are active',
                    ),
                    value: controller.showOnlineStatus,
                    onChanged: controller.setShowOnlineStatus,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showHelpSupport() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff18201e),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Use these support details if you need help with your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xff697176),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 18),
              _ProfileInfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email Support',
                value: 'support@nikahlink.app',
              ),
              _ProfileInfoRow(
                icon: Icons.info_outline_rounded,
                label: 'Guidance',
                value: 'Check your profile details, structured conversation status, and chat access before contacting support.',
              ),
            ],
          ),
        );
      },
    );
  }

  String _notificationLabel(bool enabled) {
    return enabled ? 'Notifications are on' : 'Notifications are off';
  }

  String _privacyLabel(AppSettingsController controller) {
    final visibility = controller.profileVisible ? 'Visible' : 'Hidden';
    final onlineStatus =
        controller.showOnlineStatus ? 'online shown' : 'online hidden';
    return '$visibility • $onlineStatus';
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
        _applyMatchStatesToProfiles();
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
        _matchEntries
          ..clear()
          ..addAll(interests);
        _applyMatchStatesToProfiles();
        _isMatchesLoading = false;
      });
      await _refreshNotifications();

      final acceptedCount = interests
          .where(
            (entry) =>
                (entry['relationship_status'] as String? ?? '').trim() ==
                'accepted',
          )
          .length;
      if (acceptedCount == 0) {
        _hasShownAcceptedMatchNotice = false;
      } else if (_selectedTabIndex == 1 &&
          !_hasShownAcceptedMatchNotice &&
          AppSettingsController.instance.notificationsEnabled &&
          mounted) {
        _hasShownAcceptedMatchNotice = true;
        AppSnackbar.show(
          context,
          acceptedCount == 1
              ? 'One match has been accepted.'
              : '$acceptedCount matches have been accepted.',
        );
      }
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

  void _handleTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    if (index == 1 && _matchEntries.isEmpty && !_isMatchesLoading) {
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
    if (location.isEmpty) {
      return 'Nikah Link community';
    }
    return location;
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

  void _applyMatchStatesToProfiles() {
    if (_profiles.isEmpty) {
      return;
    }

    final stateByProfileId = <int, Map<String, dynamic>>{};
    for (final entry in _matchEntries) {
      final id = entry['id'] as int?;
      if (id != null) {
        stateByProfileId[id] = entry;
      }
    }

    for (var index = 0; index < _profiles.length; index += 1) {
      final profile = Map<String, dynamic>.from(_profiles[index]);
      final id = profile['id'] as int?;
      final matchState = id == null ? null : stateByProfileId[id];
      if (matchState == null) {
        profile.remove('relationship_status');
        profile.remove('match_interest_id');
      } else {
        profile['relationship_status'] = matchState['relationship_status'];
        profile['match_interest_id'] = matchState['match_interest_id'];
      }
      _profiles[index] = profile;
    }
  }

  Future<void> _openProfileFromDiscover(Map<String, dynamic> profile) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PublicProfileViewScreen(
          profile: profile,
          relationshipStatus:
              (profile['relationship_status'] as String? ?? '').trim(),
          matchInterestId: profile['match_interest_id'] as int?,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isMatchesLoading = true;
      });
      await _loadReceivedInterests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_selectedTabIndex) {
      0 => _buildDiscoverContent(),
      1 => _buildMatchesContent(),
      2 => _buildChatContent(),
      3 => _buildProfileContent(),
      _ => _buildDiscoverContent(),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.appBackground,
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
                        _selectedTabIndex == 0
                            ? 'Nikah Link'
                            : _selectedTabIndex == 1
                            ? 'Matches'
                            : _selectedTabIndex == 2
                            ? 'Chat'
                            : 'Profile',
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
                          : _selectedTabIndex == 1 || _selectedTabIndex == 2
                          ? Icons.refresh_rounded
                          : Icons.refresh_rounded,
                      onTap: _selectedTabIndex == 0
                          ? () {}
                          : () {
                              setState(() {
                                _isMatchesLoading = true;
                                if (_selectedTabIndex == 3) {
                                  _isProfileLoading = true;
                                }
                              });
                              if (_selectedTabIndex == 3) {
                                _loadCurrentUserProfile();
                              } else {
                                _loadReceivedInterests();
                              }
                            },
                    ),
                    const SizedBox(width: 10),
                    _HeaderCircleButton(
                      icon: _selectedTabIndex == 0
                          ? Icons.tune_rounded
                          : _selectedTabIndex == 3
                          ? Icons.settings_outlined
                          : Icons.notifications_none_rounded,
                      badgeCount: _unreadNotificationCount,
                      onTap: _selectedTabIndex == 3
                          ? _showNotificationSettings
                          : _openNotifications,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(child: body),
                const SizedBox(height: 16),
                _BottomNavBar(
                  selectedIndex: _selectedTabIndex,
                  matchCount: _matchEntries.length,
                  onTap: _handleTabSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profiles.isEmpty) {
      return _EmptyDiscoverState(onRefresh: _loadProfiles);
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _profiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return _DiscoverListCard(
          profile: profile,
          headline: _formatHeadline(profile),
          subtitle: _buildSubtitle(profile),
          highlights: _buildHighlights(profile),
          about: _buildAbout(profile),
          onViewProfile: () => _openProfileFromDiscover(profile),
        );
      },
    );
  }

  Widget _buildMatchesContent() {
    if (_isMatchesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matchEntries.isEmpty) {
      return _EmptyMatchesState(onRefresh: _loadReceivedInterests);
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _matchEntries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final profile = _matchEntries[index];
        return _MatchCard(
          profile: profile,
          onAccept: (profile['relationship_status'] as String? ?? '').trim() ==
                  'pending_received'
              ? () => _respondToMatchFromList(
                    matchInterestId: profile['match_interest_id'] as int? ?? 0,
                    accept: true,
                  )
              : null,
          onDecline: (profile['relationship_status'] as String? ?? '').trim() ==
                  'pending_received'
              ? () => _respondToMatchFromList(
                    matchInterestId: profile['match_interest_id'] as int? ?? 0,
                    accept: false,
                  )
              : null,
          onOpenStructuredQuestions:
              (profile['relationship_status'] as String? ?? '').trim() ==
                      'accepted'
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StructuredCompatibilityChatScreen(
                            matchedUserName:
                                (profile['full_name'] as String? ??
                                        'Nikah Link member')
                                    .trim(),
                            matchInterestId:
                                profile['match_interest_id'] as int? ?? 0,
                          ),
                        ),
                      );
                    }
                  : null,
          onViewProfile: () async {
            final result = await Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (_) => PublicProfileViewScreen(
                  profile: profile,
                  fromMatches: true,
                  matchInterestId: profile['match_interest_id'] as int?,
                  relationshipStatus:
                      (profile['relationship_status'] as String? ?? '').trim(),
                ),
              ),
            );

            if (!mounted) {
              return;
            }

            if (result == 'accepted' || result == 'declined') {
              setState(() {
                _isLoading = true;
                _isMatchesLoading = true;
              });
              await _loadProfiles();
              await _loadReceivedInterests();
            }
          },
        );
      },
    );
  }

  Widget _buildChatContent() {
    if (_isMatchesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final chatEntries = _matchEntries.where((entry) {
      return entry['chat_unlocked'] as bool? ?? false;
    }).toList();

    if (chatEntries.isEmpty) {
      return _EmptyChatState(onRefresh: _loadReceivedInterests);
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: chatEntries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final entry = chatEntries[index];
        return _ChatListCard(
          profile: entry,
          onOpenChat: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MessagingScreen(
                  matchedUserName:
                      (entry['full_name'] as String? ?? 'Nikah Link member').trim(),
                  matchInterestId: entry['match_interest_id'] as int? ?? 0,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileContent() {
    if (_isProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = _currentUserProfile;
    final fullName = (profile['full_name'] as String? ?? 'Nikah Link member').trim();
    final email = (profile['email'] as String? ?? '').trim();
    final phone = (profile['phone_number'] as String? ?? '').trim();
    final location = (profile['location'] as String? ?? '').trim();
    final education = (profile['education'] as String? ?? '').trim();
    final occupation = (profile['occupation'] as String? ?? '').trim();
    final languages = (profile['languages'] as String? ?? '').trim();
    final photoBytes = _decodePhoto(
      (profile['profile_photo_base64'] as String? ?? '').trim(),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
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
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xffeef2ed),
                  backgroundImage: photoBytes == null ? null : MemoryImage(photoBytes),
                  child: photoBytes == null
                      ? Text(
                          fullName.isEmpty ? '?' : fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff18201e),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  location.isEmpty ? 'Nikah Link member' : location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff6b7378),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSetupBasicInfoScreen(),
                        ),
                      );
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _isProfileLoading = true;
                      });
                      await _loadCurrentUserProfile();
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
                      'Edit profile',
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
          const SizedBox(height: 16),
          _ProfileSectionCard(
            title: 'Account Info',
            children: [
              _ProfileInfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: email.isEmpty ? 'Not added yet' : email,
              ),
              _ProfileInfoRow(
                icon: Icons.call_outlined,
                label: 'Phone',
                value: phone.isEmpty ? 'Not added yet' : phone,
              ),
              _ProfileInfoRow(
                icon: Icons.school_outlined,
                label: 'Education',
                value: education.isEmpty ? 'Not added yet' : education,
              ),
              _ProfileInfoRow(
                icon: Icons.work_outline_rounded,
                label: 'Occupation',
                value: occupation.isEmpty ? 'Not added yet' : occupation,
              ),
              _ProfileInfoRow(
                icon: Icons.language_rounded,
                label: 'Languages',
                value: languages.isEmpty ? 'Not added yet' : languages,
              ),
            ],
          ),
          const SizedBox(height: 16),
        _ProfileSectionCard(
            title: 'Theme',
            children: [
              _ProfileActionRow(
                icon: Icons.light_mode_outlined,
                label: 'App Theme',
                subtitle:
                    _themeLabel(AppSettingsController.instance.themeMode),
                onTap: _showThemeSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSectionCard(
            title: 'Chat Theme',
            children: [
              _ProfileActionRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat Appearance',
                subtitle:
                    '${AppSettingsController.instance.chatFontSize.toStringAsFixed(1)} pt • ${_chatBackgroundLabel(AppSettingsController.instance.chatBackgroundStyle)} background',
                onTap: _showChatThemeSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSectionCard(
            title: 'Settings',
            children: [
              _ProfileActionRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                subtitle: _notificationLabel(
                  AppSettingsController.instance.notificationsEnabled,
                ),
                onTap: _showNotificationSettings,
              ),
              _ProfileActionRow(
                icon: Icons.lock_outline_rounded,
                label: 'Privacy & Safety',
                subtitle: _privacyLabel(AppSettingsController.instance),
                onTap: _showPrivacySettings,
              ),
              _ProfileActionRow(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                subtitle: 'Support contact and guidance',
                onTap: _showHelpSupport,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await AuthSessionStore.clear();
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(icon, color: const Color(0xff2f3b38)),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverListCard extends StatelessWidget {
  const _DiscoverListCard({
    required this.profile,
    required this.headline,
    required this.subtitle,
    required this.highlights,
    required this.about,
    required this.onViewProfile,
  });

  final Map<String, dynamic> profile;
  final String headline;
  final String subtitle;
  final List<String> highlights;
  final String about;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final profilePhotoBase64 =
        (profile['profile_photo_base64'] as String? ?? '').trim();
    final profilePhotoBytes = _decodePhoto(profilePhotoBase64);
    final relationshipStatus =
        (profile['relationship_status'] as String? ?? '').trim();
    final statusLabel = relationshipStatus == 'accepted' ? 'Accepted' : 'Sent';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: Stack(
              children: [
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: profilePhotoBytes == null
                      ? Image.asset(
                          'lib/assets/images/Mosque Skyline 3.png',
                          fit: BoxFit.cover,
                        )
                      : Image.memory(
                          profilePhotoBytes,
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
                    child: Text(
                      relationshipStatus.isEmpty ? 'New here' : statusLabel,
                      style: const TextStyle(
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff18201e),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
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
                  children: highlights.map((item) {
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
                  about,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xff576066),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewProfile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: Color(0xffd5dfd6)),
                          minimumSize: const Size.fromHeight(56),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: relationshipStatus.isNotEmpty
                          ? Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(1, 68, 51, 0.08),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: onViewProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Send interest',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.onRefresh});

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
                Icons.chat_bubble_outline_rounded,
                size: 70,
                color: Color(0xff95a19a),
              ),
              const SizedBox(height: 18),
              const Text(
                'No unlocked chats yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff24312d),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Only matches that are accepted and completed through structured conversation will appear here.',
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
  const _MatchCard({
    required this.profile,
    this.onAccept,
    this.onDecline,
    this.onOpenStructuredQuestions,
    required this.onViewProfile,
  });

  final Map<String, dynamic> profile;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onOpenStructuredQuestions;
  final VoidCallback onViewProfile;

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
    final relationshipStatus =
        (profile['relationship_status'] as String? ?? '').trim();
    final statusLabel = switch (relationshipStatus) {
      'accepted' => 'Accepted',
      'pending_sent' => 'Sent',
      _ => 'New interest',
    };
    final isPendingReceived = relationshipStatus == 'pending_received';
    final isAccepted = relationshipStatus == 'accepted';
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(1, 68, 51, 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
            if (isPendingReceived) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffba3c3c),
                        side: const BorderSide(color: Color(0xffead1d1)),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (isAccepted && onOpenStructuredQuestions != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onOpenStructuredQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Go to structured questions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onViewProfile,
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListCard extends StatelessWidget {
  const _ChatListCard({
    required this.profile,
    required this.onOpenChat,
  });

  final Map<String, dynamic> profile;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final fullName =
        (profile['full_name'] as String? ?? 'Nikah Link member').trim();
    final location = (profile['location'] as String? ?? '').trim();
    final profilePhotoBase64 =
        (profile['profile_photo_base64'] as String? ?? '').trim();
    final profilePhotoBytes = _decodePhoto(profilePhotoBase64);

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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
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
        title: Text(
          fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xff18201e),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            location.isEmpty
                ? 'Structured conversation completed'
                : '$location • Structured conversation completed',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff6b7378),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.primaryGreen,
        ),
        onTap: onOpenChat,
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xff18201e),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(1, 68, 51, 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff7b8582),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff18201e),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(1, 68, 51, 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xff18201e),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff6b7378),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xff9aa39f),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffedf6ef) : const Color(0xfffaf7f0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : const Color(0xffddd8cc),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: selected
                          ? AppColors.primaryGreen
                          : const Color(0xff18201e),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff6b7378),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primaryGreen : const Color(0xff9aa39f),
            ),
          ],
        ),
      ),
    );
  }
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
