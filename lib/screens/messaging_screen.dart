import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/profile_api_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_settings_controller.dart';
import 'discover_screen.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({
    super.key,
    required this.matchedUserName,
    required this.matchInterestId,
  });

  final String matchedUserName;
  final int matchInterestId;

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages(initialLoad: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadMessages(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool initialLoad = false}) async {
    try {
      final response = await ProfileApiService.getMatchMessages(
        matchInterestId: widget.matchInterestId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _messages
          ..clear()
          ..addAll(
            response.map(
              (item) => _ChatMessage(
                id: item['id'] as int? ?? 0,
                text: (item['content'] as String? ?? '').trim(),
                time: _formatServerTime(item['created_at']?.toString() ?? ''),
                isMine: item['is_mine'] as bool? ?? false,
              ),
            ),
          );
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (initialLoad) {
        setState(() {
          _isLoading = false;
        });
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final message = await ProfileApiService.sendMatchMessage(
        matchInterestId: widget.matchInterestId,
        content: text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            id: message['id'] as int? ?? 0,
            text: (message['content'] as String? ?? '').trim(),
            time: _formatServerTime(message['created_at']?.toString() ?? ''),
            isMine: message['is_mine'] as bool? ?? true,
          ),
        );
        _messageController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
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
          _isSending = false;
        });
      }
    }
  }

  String _formatServerTime(String rawValue) {
    final dateTime = DateTime.tryParse(rawValue)?.toLocal();
    if (dateTime == null) {
      return '';
    }

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    Color scaffoldColor(ChatBackgroundStyle style) {
      return switch (style) {
        ChatBackgroundStyle.warm => const Color(0xffefe7d8),
        ChatBackgroundStyle.light => const Color(0xffedf2f4),
        ChatBackgroundStyle.sage => const Color(0xffe4ece2),
        ChatBackgroundStyle.dark => const Color(0xff111715),
      };
    }

    Color topBarColor(ChatBackgroundStyle style) {
      return switch (style) {
        ChatBackgroundStyle.warm => const Color(0xfff6f1e8),
        ChatBackgroundStyle.light => const Color(0xffffffff),
        ChatBackgroundStyle.sage => const Color(0xfff1f6ef),
        ChatBackgroundStyle.dark => const Color(0xff1a2320),
      };
    }

    LinearGradient chatGradient(ChatBackgroundStyle style) {
      return switch (style) {
        ChatBackgroundStyle.warm => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffe8dec9), Color(0xfff4ecdf)],
        ),
        ChatBackgroundStyle.light => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffeef3f5), Color(0xffffffff)],
        ),
        ChatBackgroundStyle.sage => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffdfe9df), Color(0xfff2f7f0)],
        ),
        ChatBackgroundStyle.dark => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff1b2421), Color(0xff101715)],
        ),
      };
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final chatFontSize = settings.chatFontSize;
          final backgroundStyle = settings.chatBackgroundStyle;
          final darkBackground = backgroundStyle == ChatBackgroundStyle.dark;

          return Scaffold(
            backgroundColor: scaffoldColor(backgroundStyle),
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                    color: topBarColor(backgroundStyle),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const DiscoverScreen(initialTabIndex: 1),
                            ),
                            (route) => false,
                          ),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: darkBackground
                                ? Colors.white
                                : const Color(0xff202825),
                          ),
                        ),
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: const Color(0xffe7efe9),
                          child: Text(
                            widget.matchedUserName.isEmpty
                                ? '?'
                                : widget.matchedUserName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.matchedUserName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: darkBackground
                                      ? Colors.white
                                      : const Color(0xff18201e),
                                ),
                              ),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.videocam_outlined,
                          color: darkBackground
                              ? Colors.white70
                              : AppColors.primaryGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.call_rounded,
                          color: darkBackground
                              ? Colors.white70
                              : AppColors.primaryGreen,
                          size: 21,
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.more_vert_rounded,
                          color: darkBackground
                              ? Colors.white70
                              : const Color(0xff202825),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: chatGradient(backgroundStyle),
                      ),
                      child: Column(
                        children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfffbf2d9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Reminder: Keep conversations respectful, purposeful and focused on marriage.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: Color(0xff6c5a2f),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _messages.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'No messages yet. Start the conversation with sincerity and kindness.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Color(0xff697176),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.separated(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return Align(
                                    alignment: message.isMine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 300),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                        decoration: BoxDecoration(
                                          color: message.isMine
                                              ? const Color(0xffdcf8c6)
                                              : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: Radius.circular(
                                              message.isMine ? 12 : 4,
                                            ),
                                            bottomRight: Radius.circular(
                                              message.isMine ? 4 : 12,
                                            ),
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color.fromRGBO(0, 0, 0, 0.06),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.text,
                                              style: TextStyle(
                                                fontSize: chatFontSize,
                                                height: 1.4,
                                                color: const Color(0xff202825),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                message.time,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: message.isMine
                                                      ? const Color(0xff5f7c6a)
                                                      : const Color(0xff8a8f90),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemCount: _messages.length,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.08),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 14),
                                    const Icon(
                                      Icons.sentiment_satisfied_alt_rounded,
                                      color: Color(0xff8d948f),
                                      size: 22,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        minLines: 1,
                                        maxLines: 4,
                                        style: TextStyle(
                                          fontSize: chatFontSize,
                                          color: const Color(0xff202825),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Type a message',
                                          hintStyle: TextStyle(
                                            fontSize: chatFontSize,
                                            color: const Color(0xff8d948f),
                                          ),
                                          border: InputBorder.none,
                                          isCollapsed: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.attach_file_rounded,
                                      color: Color(0xff8d948f),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Color(0xff8d948f),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 14),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _isSending ? null : _sendMessage,
                              borderRadius: BorderRadius.circular(999),
                              child: Ink(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _isSending
                                      ? const Color(0xff6c9185)
                                      : AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: _isSending
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
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
                  const _ChatBottomNavBar(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatBottomNavBar extends StatelessWidget {
  const _ChatBottomNavBar();

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
          _StaticNavItem(
            icon: Icons.travel_explore_rounded,
            label: 'Discover',
            active: false,
          ),
          _StaticNavItem(
            icon: Icons.favorite_border_rounded,
            label: 'Matches',
            active: false,
          ),
          _StaticNavItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            active: true,
          ),
          _StaticNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            active: false,
          ),
        ],
      ),
    );
  }
}

class _StaticNavItem extends StatelessWidget {
  const _StaticNavItem({
    required this.icon,
    required this.label,
    required this.active,
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

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isMine,
  });

  final int id;
  final String text;
  final String time;
  final bool isMine;
}
