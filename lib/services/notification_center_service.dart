import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetTabIndex,
    this.matchInterestId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final int targetTabIndex;
  final int? matchInterestId;
  final bool isRead;

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      targetTabIndex: targetTabIndex,
      matchInterestId: matchInterestId,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationCenterService {
  static const String _readIdsKey = 'read_notification_ids';

  static Future<List<AppNotificationItem>> buildNotifications({
    required List<Map<String, dynamic>> matchEntries,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readIdsKey)?.toSet() ?? <String>{};
    final notifications = <AppNotificationItem>[];

    for (final entry in matchEntries) {
      final matchInterestId = entry['match_interest_id'] as int?;
      if (matchInterestId == null) {
        continue;
      }

      final fullName =
          (entry['full_name'] as String? ?? 'Nikah Link member').trim();
      final relationshipStatus =
          (entry['relationship_status'] as String? ?? '').trim();
      final chatUnlocked = entry['chat_unlocked'] as bool? ?? false;

      if (relationshipStatus == 'pending') {
        final id = 'interest_pending_$matchInterestId';
        notifications.add(
          AppNotificationItem(
            id: id,
            title: 'New interest from $fullName',
            body: 'This member sent interest to you. Open Matches to review.',
            type: 'interest',
            targetTabIndex: 1,
            matchInterestId: matchInterestId,
            isRead: readIds.contains(id),
          ),
        );
      }

      if (relationshipStatus == 'accepted') {
        final id = 'interest_accepted_$matchInterestId';
        notifications.add(
          AppNotificationItem(
            id: id,
            title: '$fullName accepted the match',
            body: 'Your match is accepted. You can continue from Matches.',
            type: 'accepted',
            targetTabIndex: 1,
            matchInterestId: matchInterestId,
            isRead: readIds.contains(id),
          ),
        );
      }

      if (chatUnlocked) {
        final id = 'chat_unlocked_$matchInterestId';
        notifications.add(
          AppNotificationItem(
            id: id,
            title: 'Chat unlocked with $fullName',
            body:
                'Structured conversation is complete. You can now open Chat.',
            type: 'chat',
            targetTabIndex: 2,
            matchInterestId: matchInterestId,
            isRead: readIds.contains(id),
          ),
        );
      }
    }

    notifications.sort((a, b) => a.isRead == b.isRead ? 0 : (a.isRead ? 1 : -1));
    return notifications;
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readIdsKey)?.toSet() ?? <String>{};
    readIds.add(id);
    await prefs.setStringList(_readIdsKey, readIds.toList());
  }

  static Future<void> markAllAsRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readIdsKey)?.toSet() ?? <String>{};
    readIds.addAll(ids);
    await prefs.setStringList(_readIdsKey, readIds.toList());
  }
}
