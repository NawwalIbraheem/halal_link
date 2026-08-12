import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Random _random = Random();

  static const List<Map<String, String>> structuredQuestions = [
    {
      'topic': 'Marriage Intention',
      'prompt': 'Why are you seeking marriage at this stage of your life?',
      'description':
          'This tells the other person whether they are serious and what motivates them.',
    },
    {
      'topic': 'Deen',
      'prompt':
          'What role do you want Islam to play in your future marriage and home?',
      'description':
          'This is probably the most important question because it reveals their priorities and values.',
    },
    {
      'topic': 'Spouse Expectations',
      'prompt':
          'What are the three most important qualities you are looking for in a spouse?',
      'description':
          'This helps both people understand what each values most.',
    },
    {
      'topic': 'Family',
      'prompt': 'How involved would you like your families to be after marriage?',
      'description':
          'This is especially important in East African Muslim communities where family involvement can differ.',
    },
    {
      'topic': 'Career & Lifestyle',
      'prompt':
          'How do you see balancing work, family, and personal responsibilities after marriage?',
      'description':
          'This helps uncover expectations about work, roles, and daily life.',
    },
    {
      'topic': 'Children',
      'prompt':
          'Do you hope to have children? If yes, what kind of Islamic values would you like to raise them with?',
      'description':
          'This combines two important discussions into one question.',
    },
    {
      'topic': 'Conflict Resolution',
      'prompt':
          'When disagreements arise, how do you believe a husband and wife should resolve them?',
      'description':
          'A marriage is not about avoiding conflict, it is about handling it well. This question reveals maturity and communication style.',
    },
    {
      'topic': 'Future Vision',
      'prompt':
          'Where do you hope to see yourself and your family in the next five years?',
      'description':
          'This reveals long-term goals and whether both people are moving in a similar direction.',
    },
  ];

  static CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');
  static CollectionReference<Map<String, dynamic>> get matches =>
      _firestore.collection('matches');

  static User? get currentFirebaseUser => _auth.currentUser;

  static String normalizePhoneNumber(String rawValue) {
    final digits = rawValue.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+255')) {
      return '+255${digits.substring(4).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    if (digits.startsWith('255')) {
      return '+255${digits.substring(3).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    if (digits.startsWith('0')) {
      return '+255${digits.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    final onlyNumbers = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyNumbers.length == 9) {
      return '+255$onlyNumbers';
    }
    return rawValue.trim();
  }

  static int generateNumericId() {
    return DateTime.now().microsecondsSinceEpoch + _random.nextInt(999);
  }

  static String nowIso() => DateTime.now().toUtc().toIso8601String();

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  findUserDocumentByPublicId(int publicId) async {
    final snapshot =
        await users.where('id', isEqualTo: publicId).limit(1).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return snapshot.docs.first;
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  findUserDocumentByPhone(String phoneNumber) async {
    final normalized = normalizePhoneNumber(phoneNumber);
    final snapshot = await users
        .where('phone_number_search', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return snapshot.docs.first;
  }

  static Future<Map<String, dynamic>> ensureUserDocument({
    required User firebaseUser,
    String? fullName,
    String? phoneNumber,
    String? gender,
    String? authProvider,
  }) async {
    final docRef = users.doc(firebaseUser.uid);
    final snapshot = await docRef.get();
    final existing = snapshot.data() ?? <String, dynamic>{};
    final normalizedPhone =
        (phoneNumber ?? existing['phone_number']?.toString() ?? '').trim();
    final normalizedPhoneSearch = normalizedPhone.isEmpty
        ? ''
        : normalizePhoneNumber(normalizedPhone);

    final fullNameValue =
        (fullName?.trim().isNotEmpty == true ? fullName!.trim() : null) ??
        (existing['full_name'] as String?)?.trim() ??
        (firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : null) ??
        (firebaseUser.email?.split('@').first.trim().isNotEmpty == true
            ? firebaseUser.email!.split('@').first.trim()
            : 'Nikah Link member');

    final payload = <String, dynamic>{
      'uid': firebaseUser.uid,
      'id': existing['id'] as int? ?? generateNumericId(),
      'full_name': fullNameValue,
      'email': (firebaseUser.email ?? existing['email'] ?? '').toString().trim().toLowerCase(),
      'phone_number': normalizedPhone,
      'phone_number_search': normalizedPhoneSearch,
      'gender': (gender ?? existing['gender'] ?? '').toString().trim().toLowerCase(),
      'is_verified': existing['is_verified'] as bool? ?? false,
      'auth_provider':
          (authProvider ?? existing['auth_provider'] ?? 'email').toString(),
      'social_provider_user_id':
          (existing['social_provider_user_id'] ?? '').toString(),
      'date_of_birth': (existing['date_of_birth'] ?? '').toString(),
      'location': (existing['location'] ?? '').toString(),
      'education': (existing['education'] ?? '').toString(),
      'occupation': (existing['occupation'] ?? '').toString(),
      'languages': (existing['languages'] ?? '').toString(),
      'profile_photo_base64': (existing['profile_photo_base64'] ?? '').toString(),
      'islamic_profile': Map<String, dynamic>.from(
        existing['islamic_profile'] as Map? ??
            const <String, dynamic>{
              'prayer_level': '',
              'quran_activity': '',
              'quran_frequency': '',
              'islamic_goals': '',
              'marriage_values': <String>[],
            },
      ),
      'marriage_expectations': Map<String, dynamic>.from(
        existing['marriage_expectations'] as Map? ??
            const <String, dynamic>{
              'qualities_looking_for': '',
              'marriage_timeline': '',
              'children_preference': '',
              'preferred_living_arrangement': '',
              'family_involvement': '',
            },
      ),
      'lifestyle_profile': Map<String, dynamic>.from(
        existing['lifestyle_profile'] as Map? ??
            const <String, dynamic>{
              'height_range': '',
              'body_type': '',
              'cultural_background': '',
              'dress_style': '',
              'photo_privacy_matches_only': true,
            },
      ),
      'created_at': (existing['created_at'] ?? nowIso()).toString(),
      'updated_at': nowIso(),
    };

    try {
      await docRef.set(payload, SetOptions(merge: true));
      final latest = await docRef.get();
      return userMapFromDocument(latest);
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Map<String, dynamic> userMapFromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return {
      'uid': snapshot.id,
      'id': data['id'] as int? ?? 0,
      'full_name': (data['full_name'] ?? '').toString(),
      'email': (data['email'] ?? '').toString(),
      'phone_number': (data['phone_number'] ?? '').toString(),
      'gender': (data['gender'] ?? '').toString(),
      'is_verified': data['is_verified'] as bool? ?? false,
      'date_of_birth': (data['date_of_birth'] ?? '').toString(),
      'location': (data['location'] ?? '').toString(),
      'education': (data['education'] ?? '').toString(),
      'occupation': (data['occupation'] ?? '').toString(),
      'languages': (data['languages'] ?? '').toString(),
      'profile_photo_base64': (data['profile_photo_base64'] ?? '').toString(),
    };
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> currentUserDocument() async {
    final user = currentFirebaseUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }
    try {
      return await users.doc(user.uid).get();
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  currentUserMatchDocuments() async {
    final user = currentFirebaseUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }
    try {
      final snapshot = await matches
          .where('participant_uids', arrayContains: user.uid)
          .get();
      return snapshot.docs;
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  findMatchDocumentByPublicId(int matchPublicId) async {
    final snapshot =
        await matches.where('id', isEqualTo: matchPublicId).limit(1).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return snapshot.docs.first;
  }

  static bool chatUnlockedFromMatchData(
    Map<String, dynamic> data,
    String currentUid,
    String otherUid,
  ) {
    if ((data['status'] ?? '').toString() != 'accepted') {
      return false;
    }
    final answersByUser = Map<String, dynamic>.from(
      data['structured_answers_by_user'] as Map? ?? const <String, dynamic>{},
    );
    final reflectionsByUser = Map<String, dynamic>.from(
      data['structured_reflections_by_user'] as Map? ??
          const <String, dynamic>{},
    );
    final currentAnswers = Map<String, dynamic>.from(
      answersByUser[currentUid] as Map? ?? const <String, dynamic>{},
    );
    final otherAnswers = Map<String, dynamic>.from(
      answersByUser[otherUid] as Map? ?? const <String, dynamic>{},
    );
    final currentReflection = Map<String, dynamic>.from(
      reflectionsByUser[currentUid] as Map? ?? const <String, dynamic>{},
    );
    final otherReflection = Map<String, dynamic>.from(
      reflectionsByUser[otherUid] as Map? ?? const <String, dynamic>{},
    );
    if (currentAnswers.length < structuredQuestions.length ||
        otherAnswers.length < structuredQuestions.length) {
      return false;
    }
    return (currentReflection['compatibility_decision'] ?? '').toString() ==
            'Yes, I would like to continue.' &&
        (currentReflection['family_step_decision'] ?? '').toString() == 'Yes' &&
        (otherReflection['compatibility_decision'] ?? '').toString() ==
            'Yes, I would like to continue.' &&
        (otherReflection['family_step_decision'] ?? '').toString() == 'Yes';
  }

  static String prayerLevelDisplay(String value) {
    switch (value.trim().toLowerCase()) {
      case 'always':
        return 'Always';
      case 'often':
        return 'Often';
      case 'sometimes':
        return 'Sometimes';
      case 'rarely':
        return 'Rarely';
      default:
        return 'Not shared yet';
    }
  }

  static String quranActivityDisplay(String value) {
    switch (value.trim().toLowerCase()) {
      case 'hifz':
        return 'I do Hifz';
      case 'tafsir':
        return 'I attend Tafsir classes';
      case 'tajweed':
        return 'I am learning Tajweed';
      case 'read_quran':
        return 'I read the Quran';
      default:
        return '';
    }
  }

  static String quranFrequencyDisplay(String value) {
    switch (value.trim().toLowerCase()) {
      case 'regularly':
        return 'Regularly';
      case 'occasionally':
        return 'Occasionally';
      case 'learning':
        return 'Learning';
      case 'rarely':
        return 'Rarely';
      default:
        return '';
    }
  }

  static String _mapFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
        return 'Cloud Firestore is currently unavailable. Check the phone internet connection and make sure Firestore Database is created in Firebase project nikahlink-b60e5.';
      case 'failed-precondition':
        return 'Cloud Firestore is not ready yet. Open Firebase project nikahlink-b60e5 and create the Firestore Database first.';
      case 'permission-denied':
        return 'Cloud Firestore denied access. Check your Firestore security rules.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Cloud Firestore is not available right now.';
    }
  }
}
