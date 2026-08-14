import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/auth_session_store.dart';
import 'firebase_data_service.dart';

class ProfileApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<List<Map<String, dynamic>>> getPublicAccounts() async {
    try {
      final currentUser = _auth.currentUser;
      final currentUid = currentUser?.uid ?? '';
      Map<String, dynamic> currentData = const <String, dynamic>{};
      if (currentUid.isNotEmpty) {
        final currentSnapshot = await FirebaseDataService.currentUserDocument();
        currentData = currentSnapshot.data() ?? const <String, dynamic>{};
      }

      final currentGender = (currentData['gender'] ?? '').toString().trim().toLowerCase();
      final targetGender = currentGender == 'male'
          ? 'female'
          : currentGender == 'female'
          ? 'male'
          : '';
      final hiddenProfileUids = <String>{};

      if (currentUid.isNotEmpty) {
        final currentMatches = await FirebaseDataService.currentUserMatchDocuments();
        for (final match in currentMatches) {
          final matchData = match.data();
          final status = (matchData['status'] ?? '').toString().trim().toLowerCase();
          if (status == 'declined') {
            continue;
          }

          final senderUid = (matchData['sender_uid'] ?? '').toString().trim();
          final receiverUid = (matchData['receiver_uid'] ?? '').toString().trim();
          if (senderUid == currentUid && receiverUid.isNotEmpty) {
            hiddenProfileUids.add(receiverUid);
          } else if (receiverUid == currentUid && senderUid.isNotEmpty) {
            hiddenProfileUids.add(senderUid);
          }
        }
      }

      final usersSnapshot = await FirebaseDataService.users.get();
      final results = <Map<String, dynamic>>[];

      for (final doc in usersSnapshot.docs) {
        if (doc.id == currentUid) {
          continue;
        }
        if (hiddenProfileUids.contains(doc.id)) {
          continue;
        }
        final data = doc.data();
        final gender = (data['gender'] ?? '').toString().trim().toLowerCase();
        if (targetGender.isNotEmpty && gender != targetGender) {
          continue;
        }

        final publicData = await _buildPublicAccountListItem(
          doc.id,
          data,
          viewerUid: currentUid,
        );
        results.add(publicData);
      }

      return results;
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> getPublicAccountDetail(int accountId) async {
    try {
      final doc = await FirebaseDataService.findUserDocumentByPublicId(accountId);
      if (doc == null) {
        throw Exception('Selected profile was not found.');
      }
      final currentUid = _auth.currentUser?.uid ?? '';
      return _buildPublicAccountDetailItem(
        doc.id,
        doc.data(),
        viewerUid: currentUid,
      );
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> sendInterest(int receiverId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      final currentUserSnapshot = await FirebaseDataService.currentUserDocument();
      final currentUserData = currentUserSnapshot.data() ?? const <String, dynamic>{};
      final receiverDoc =
          await FirebaseDataService.findUserDocumentByPublicId(receiverId);
      if (receiverDoc == null) {
        throw Exception('Selected profile was not found.');
      }
      if (receiverDoc.id == currentUser.uid) {
        throw Exception('You cannot send interest to yourself.');
      }

      final currentMatches = await FirebaseDataService.currentUserMatchDocuments();
      for (final doc in currentMatches) {
        final data = doc.data();
        final senderUid = (data['sender_uid'] ?? '').toString();
        final receiverUid = (data['receiver_uid'] ?? '').toString();
        final status = (data['status'] ?? 'pending').toString();
        final samePair =
            senderUid == currentUser.uid && receiverUid == receiverDoc.id;
        final reversePair =
            senderUid == receiverDoc.id && receiverUid == currentUser.uid;

        if (samePair) {
          return {
            'message': status == 'accepted'
                ? 'This match is already accepted.'
                : 'You already sent interest to this profile.',
            'created': false,
            'receiver_id': receiverId,
            'match_interest_id': data['id'] as int? ?? 0,
            'relationship_status':
                status == 'accepted' ? 'accepted' : 'pending_sent',
          };
        }

        if (reversePair) {
          return {
            'message': status == 'accepted'
                ? 'This match is already accepted.'
                : 'This person already sent interest to you. Check your matches.',
            'created': false,
            'receiver_id': receiverId,
            'match_interest_id': data['id'] as int? ?? 0,
            'relationship_status':
                status == 'accepted' ? 'accepted' : 'pending_received',
          };
        }
      }

      final matchId = FirebaseDataService.generateNumericId();
      await FirebaseDataService.matches.doc(matchId.toString()).set({
        'id': matchId,
        'sender_uid': currentUser.uid,
        'receiver_uid': receiverDoc.id,
        'sender_public_id': currentUserData['id'] as int? ?? 0,
        'receiver_public_id': receiverDoc.data()['id'] as int? ?? receiverId,
        'participant_uids': <String>[currentUser.uid, receiverDoc.id],
        'status': 'pending',
        'created_at': FirebaseDataService.nowIso(),
        'responded_at': null,
        'structured_answers_by_user': <String, dynamic>{},
        'structured_reflections_by_user': <String, dynamic>{},
      });

      return {
        'message': 'Interest sent successfully.',
        'created': true,
        'receiver_id': receiverId,
        'match_interest_id': matchId,
        'relationship_status': 'pending_sent',
      };
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<List<Map<String, dynamic>>> getReceivedInterests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      final currentMatches = await FirebaseDataService.currentUserMatchDocuments();
      final results = <Map<String, dynamic>>[];

      for (final doc in currentMatches) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString();
        if (status == 'declined') {
          continue;
        }

        final senderUid = (data['sender_uid'] ?? '').toString();
        final receiverUid = (data['receiver_uid'] ?? '').toString();
        final counterpartUid =
            senderUid == currentUser.uid ? receiverUid : senderUid;
        if (counterpartUid.isEmpty) {
          continue;
        }

        final counterpartSnapshot =
            await FirebaseDataService.users.doc(counterpartUid).get();
        final counterpartData =
            counterpartSnapshot.data() ?? const <String, dynamic>{};

        final relationshipStatus = status == 'accepted'
            ? 'accepted'
            : receiverUid == currentUser.uid
            ? 'pending_received'
            : 'pending_sent';

        results.add({
          'id': counterpartData['id'] as int? ?? 0,
          'match_interest_id': data['id'] as int? ?? 0,
          'full_name': (counterpartData['full_name'] ?? 'Nikah Link member')
              .toString()
              .trim(),
          'email': (counterpartData['email'] ?? '').toString(),
          'is_verified': counterpartData['is_verified'] as bool? ?? false,
          'gender': (counterpartData['gender'] ?? '').toString(),
          'date_of_birth': (counterpartData['date_of_birth'] ?? '').toString(),
          'location': (counterpartData['location'] ?? '').toString(),
          'education': (counterpartData['education'] ?? '').toString(),
          'occupation': (counterpartData['occupation'] ?? '').toString(),
          'languages': (counterpartData['languages'] ?? '').toString(),
          'profile_photo_base64': await _visibleProfilePhoto(
            viewerUid: currentUser.uid,
            profileUid: counterpartUid,
            profileData: counterpartData,
          ),
          'interest_sent_at': (data['created_at'] ?? '').toString(),
          'relationship_status': relationshipStatus,
          'is_actionable': relationshipStatus == 'pending_received',
          'chat_unlocked': FirebaseDataService.chatUnlockedFromMatchData(
            data,
            currentUser.uid,
            counterpartUid,
          ),
        });
      }

      results.sort((a, b) => ((b['interest_sent_at'] ?? '').toString())
          .compareTo((a['interest_sent_at'] ?? '').toString()));
      return results;
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> respondToInterest({
    required int matchInterestId,
    required bool accept,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      final matchDoc =
          await FirebaseDataService.findMatchDocumentByPublicId(matchInterestId);
      if (matchDoc == null) {
        throw Exception('Match request is missing.');
      }
      final data = matchDoc.data();
      final receiverUid = (data['receiver_uid'] ?? '').toString();
      if (receiverUid != currentUser.uid) {
        throw Exception('Only the receiver can respond to this match.');
      }

      await FirebaseDataService.matches.doc(matchDoc.id).set({
        'status': accept ? 'accepted' : 'declined',
        'responded_at': FirebaseDataService.nowIso(),
      }, SetOptions(merge: true));

      return {
        'message': accept
            ? 'Match accepted successfully.'
            : 'Match declined successfully.',
        'status': accept ? 'accepted' : 'declined',
        'sender_id': data['sender_public_id'] as int? ?? 0,
      };
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> getBasicProfile() async {
    try {
      final snapshot = await FirebaseDataService.currentUserDocument();
      final data = FirebaseDataService.userMapFromDocument(snapshot);
      await AuthSessionStore.saveUser(data);
      return data;
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> updateBasicProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String location,
    required String education,
    required String occupation,
    required List<String> languages,
    String? profilePhotoBase64,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      await FirebaseDataService.users.doc(currentUser.uid).set({
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone_number': phoneNumber.trim(),
        'phone_number_search':
            FirebaseDataService.normalizePhoneNumber(phoneNumber.trim()),
        'date_of_birth': dateOfBirth.trim(),
        'location': location.trim(),
        'education': education.trim(),
        'occupation': occupation.trim(),
        'languages': languages.join(', ').trim(),
        'profile_photo_base64': (profilePhotoBase64 ?? '').trim(),
        'updated_at': FirebaseDataService.nowIso(),
      }, SetOptions(merge: true));

      final updated = await getBasicProfile();
      return updated;
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> getIslamicProfile() async {
    try {
      final snapshot = await FirebaseDataService.currentUserDocument();
      final data = snapshot.data() ?? const <String, dynamic>{};
      final profile = Map<String, dynamic>.from(
        data['islamic_profile'] as Map? ??
            const <String, dynamic>{
              'prayer_level': '',
              'quran_activity': '',
              'quran_frequency': '',
              'islamic_goals': '',
              'marriage_values': <String>[],
            },
      );
      return profile;
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<void> updateIslamicProfile({
    required String prayerLevel,
    required String quranActivity,
    required String quranFrequency,
    required String islamicGoals,
    required List<String> marriageValues,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      await FirebaseDataService.users.doc(currentUser.uid).set({
        'islamic_profile': {
          'prayer_level': prayerLevel.trim(),
          'quran_activity': quranActivity.trim(),
          'quran_frequency': quranFrequency.trim(),
          'islamic_goals': islamicGoals.trim(),
          'marriage_values': marriageValues,
        },
        'updated_at': FirebaseDataService.nowIso(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> getMarriageExpectations() async {
    try {
      final snapshot = await FirebaseDataService.currentUserDocument();
      final data = snapshot.data() ?? const <String, dynamic>{};
      return Map<String, dynamic>.from(
        data['marriage_expectations'] as Map? ??
            const <String, dynamic>{
              'qualities_looking_for': '',
              'marriage_timeline': '',
              'children_preference': '',
              'preferred_living_arrangement': '',
              'family_involvement': '',
            },
      );
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<void> updateMarriageExpectations({
    required String qualitiesLookingFor,
    required String marriageTimeline,
    required String childrenPreference,
    required String preferredLivingArrangement,
    required String familyInvolvement,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      await FirebaseDataService.users.doc(currentUser.uid).set({
        'marriage_expectations': {
          'qualities_looking_for': qualitiesLookingFor.trim(),
          'marriage_timeline': marriageTimeline.trim(),
          'children_preference': childrenPreference.trim(),
          'preferred_living_arrangement': preferredLivingArrangement.trim(),
          'family_involvement': familyInvolvement.trim(),
        },
        'updated_at': FirebaseDataService.nowIso(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> getLifestyleProfile() async {
    try {
      final snapshot = await FirebaseDataService.currentUserDocument();
      final data = snapshot.data() ?? const <String, dynamic>{};
      return Map<String, dynamic>.from(
        data['lifestyle_profile'] as Map? ??
            const <String, dynamic>{
              'height_range': '',
              'body_type': '',
              'cultural_background': '',
              'dress_style': '',
              'photo_privacy_matches_only': true,
            },
      );
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<void> updateLifestyleProfile({
    required String heightRange,
    required String bodyType,
    required String culturalBackground,
    required String dressStyle,
    required bool photoPrivacyMatchesOnly,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      await FirebaseDataService.users.doc(currentUser.uid).set({
        'lifestyle_profile': {
          'height_range': heightRange.trim(),
          'body_type': bodyType.trim(),
          'cultural_background': culturalBackground.trim(),
          'dress_style': dressStyle.trim(),
          'photo_privacy_matches_only': photoPrivacyMatchesOnly,
        },
        'updated_at': FirebaseDataService.nowIso(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> saveStructuredConversationAnswers({
    required int matchInterestId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }
      final matchDoc = await _getAcceptedMatch(matchInterestId);
      final data = matchDoc.data();
      final existing = Map<String, dynamic>.from(
        data['structured_answers_by_user'] as Map? ?? const <String, dynamic>{},
      );
      final currentAnswers = <String, dynamic>{
        for (final item in answers)
          '${item['question_index']}': (item['answer'] ?? '').toString().trim(),
      };
      existing[currentUser.uid] = currentAnswers;

      await FirebaseDataService.matches.doc(matchDoc.id).set({
        'structured_answers_by_user': existing,
      }, SetOptions(merge: true));

      return getStructuredConversationSummary(matchInterestId: matchInterestId);
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> getStructuredConversationSummary({
    required int matchInterestId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }
      final matchDoc = await _getAcceptedMatch(matchInterestId);
      final data = matchDoc.data();
      final senderUid = (data['sender_uid'] ?? '').toString();
      final receiverUid = (data['receiver_uid'] ?? '').toString();
      final otherUid = senderUid == currentUser.uid ? receiverUid : senderUid;

      final answersByUser = Map<String, dynamic>.from(
        data['structured_answers_by_user'] as Map? ?? const <String, dynamic>{},
      );
      final reflectionsByUser = Map<String, dynamic>.from(
        data['structured_reflections_by_user'] as Map? ??
            const <String, dynamic>{},
      );

      final yourAnswers = Map<String, dynamic>.from(
        answersByUser[currentUser.uid] as Map? ?? const <String, dynamic>{},
      );
      final theirAnswers = Map<String, dynamic>.from(
        answersByUser[otherUid] as Map? ?? const <String, dynamic>{},
      );

      final questions = <Map<String, dynamic>>[];
      for (var index = 0;
          index < FirebaseDataService.structuredQuestions.length;
          index += 1) {
        final question = FirebaseDataService.structuredQuestions[index];
        questions.add({
          'question_index': index,
          'topic': question['topic'] ?? '',
          'prompt': question['prompt'] ?? '',
          'description': question['description'] ?? '',
          'your_answer': (yourAnswers['$index'] ?? '').toString().trim(),
          'their_answer': (theirAnswers['$index'] ?? '').toString().trim(),
        });
      }

      final currentReflection = Map<String, dynamic>.from(
        reflectionsByUser[currentUser.uid] as Map? ??
            const <String, dynamic>{
              'compatibility_decision': '',
              'family_step_decision': '',
            },
      );
      final matchedReflection = Map<String, dynamic>.from(
        reflectionsByUser[otherUid] as Map? ??
            const <String, dynamic>{
              'compatibility_decision': '',
              'family_step_decision': '',
            },
      );

      final bothAnswered = yourAnswers.length >= FirebaseDataService.structuredQuestions.length &&
          theirAnswers.length >= FirebaseDataService.structuredQuestions.length;
      final chatUnlocked = FirebaseDataService.chatUnlockedFromMatchData(
        data,
        currentUser.uid,
        otherUid,
      );

      return {
        'questions': questions,
        'current_user_reflection': currentReflection,
        'matched_user_reflection': matchedReflection,
        'both_answered': bothAnswered,
        'chat_unlocked': chatUnlocked,
      };
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> submitStructuredConversationReflection({
    required int matchInterestId,
    required String compatibilityDecision,
    required String familyStepDecision,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }
      final matchDoc = await _getAcceptedMatch(matchInterestId);
      final data = matchDoc.data();
      final existing = Map<String, dynamic>.from(
        data['structured_reflections_by_user'] as Map? ??
            const <String, dynamic>{},
      );
      existing[currentUser.uid] = {
        'compatibility_decision': compatibilityDecision.trim(),
        'family_step_decision': familyStepDecision.trim(),
      };

      await FirebaseDataService.matches.doc(matchDoc.id).set({
        'structured_reflections_by_user': existing,
      }, SetOptions(merge: true));

      return getStructuredConversationSummary(matchInterestId: matchInterestId);
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<List<Map<String, dynamic>>> getMatchMessages({
    required int matchInterestId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }
      final matchDoc = await _getChatUnlockedMatch(matchInterestId);
      final messagesSnapshot = await FirebaseDataService.matches
          .doc(matchDoc.id)
          .collection('messages')
          .orderBy('created_at')
          .get();

      return messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'] as int? ?? 0,
          'sender_id': data['sender_public_id'] as int? ?? 0,
          'sender_name': (data['sender_name'] ?? '').toString(),
          'content': (data['content'] ?? '').toString(),
          'created_at': (data['created_at'] ?? '').toString(),
          'is_mine': (data['sender_uid'] ?? '').toString() == currentUser.uid,
        };
      }).toList();
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<Map<String, dynamic>> sendMatchMessage({
    required int matchInterestId,
    required String content,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }
      final currentSnapshot = await FirebaseDataService.currentUserDocument();
      final currentData = currentSnapshot.data() ?? const <String, dynamic>{};
      final matchDoc = await _getChatUnlockedMatch(matchInterestId);

      final messageId = FirebaseDataService.generateNumericId();
      final payload = {
        'id': messageId,
        'sender_uid': currentUser.uid,
        'sender_public_id': currentData['id'] as int? ?? 0,
        'sender_name': (currentData['full_name'] ?? '').toString(),
        'content': content.trim(),
        'created_at': FirebaseDataService.nowIso(),
      };

      await FirebaseDataService.matches
          .doc(matchDoc.id)
          .collection('messages')
          .doc(messageId.toString())
          .set(payload);

      return {
        ...payload,
        'is_mine': true,
      };
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>> _getAcceptedMatch(
    int matchInterestId,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You are not logged in.');
    }
    final matchDoc =
        await FirebaseDataService.findMatchDocumentByPublicId(matchInterestId);
    if (matchDoc == null) {
      throw Exception('Match request is missing.');
    }
    final data = matchDoc.data();
    final participants = (data['participant_uids'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    if (!participants.contains(currentUser.uid)) {
      throw Exception('This match does not belong to you.');
    }
    if ((data['status'] ?? '').toString() != 'accepted') {
      throw Exception('Structured conversation is available only for accepted matches.');
    }
    return matchDoc;
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>> _getChatUnlockedMatch(
    int matchInterestId,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You are not logged in.');
    }
    final matchDoc = await _getAcceptedMatch(matchInterestId);
    final data = matchDoc.data();
    final senderUid = (data['sender_uid'] ?? '').toString();
    final receiverUid = (data['receiver_uid'] ?? '').toString();
    final otherUid = senderUid == currentUser.uid ? receiverUid : senderUid;
    final unlocked = FirebaseDataService.chatUnlockedFromMatchData(
      data,
      currentUser.uid,
      otherUid,
    );
    if (!unlocked) {
      throw Exception('Chat is available only after both reflections are accepted.');
    }
    return matchDoc;
  }

  static Future<Map<String, dynamic>> _buildPublicAccountListItem(
    String profileUid,
    Map<String, dynamic> data, {
    required String viewerUid,
  }) async {
    final photo = await _visibleProfilePhoto(
      viewerUid: viewerUid,
      profileUid: profileUid,
      profileData: data,
    );
    return {
      'id': data['id'] as int? ?? 0,
      'full_name': (data['full_name'] ?? 'Nikah Link member').toString().trim(),
      'email': (data['email'] ?? '').toString().trim(),
      'is_verified': data['is_verified'] as bool? ?? false,
      'gender': (data['gender'] ?? '').toString().trim(),
      'date_of_birth': (data['date_of_birth'] ?? '').toString().trim(),
      'location': (data['location'] ?? '').toString().trim(),
      'education': (data['education'] ?? '').toString().trim(),
      'occupation': (data['occupation'] ?? '').toString().trim(),
      'languages': (data['languages'] ?? '').toString().trim(),
      'profile_photo_base64': photo,
      'can_view_photo': photo.isNotEmpty,
    };
  }

  static Future<Map<String, dynamic>> _buildPublicAccountDetailItem(
    String profileUid,
    Map<String, dynamic> data, {
    required String viewerUid,
  }) async {
    final islamicProfile = Map<String, dynamic>.from(
      data['islamic_profile'] as Map? ?? const <String, dynamic>{},
    );
    final photo = await _visibleProfilePhoto(
      viewerUid: viewerUid,
      profileUid: profileUid,
      profileData: data,
    );
    return {
      'id': data['id'] as int? ?? 0,
      'full_name': (data['full_name'] ?? 'Nikah Link member').toString().trim(),
      'email': (data['email'] ?? '').toString().trim(),
      'is_verified': data['is_verified'] as bool? ?? false,
      'gender': (data['gender'] ?? '').toString().trim(),
      'date_of_birth': (data['date_of_birth'] ?? '').toString().trim(),
      'location': (data['location'] ?? '').toString().trim(),
      'education': (data['education'] ?? '').toString().trim(),
      'occupation': (data['occupation'] ?? '').toString().trim(),
      'languages': (data['languages'] ?? '').toString().trim(),
      'profile_photo_base64': photo,
      'can_view_photo': photo.isNotEmpty,
      'about_me': _buildAboutMe(data),
      'prayer_level_display': FirebaseDataService.prayerLevelDisplay(
        (islamicProfile['prayer_level'] ?? '').toString(),
      ),
      'quran_focus_display': _buildQuranFocusDisplay(islamicProfile),
      'islamic_goals_display': _buildIslamicGoalsDisplay(islamicProfile),
    };
  }

  static String _buildAboutMe(Map<String, dynamic> data) {
    final parts = <String>[];
    final occupation = (data['occupation'] ?? '').toString().trim();
    final location = (data['location'] ?? '').toString().trim();
    final languages = (data['languages'] ?? '').toString().trim();

    if (occupation.isNotEmpty) {
      parts.add('I work as a ${occupation.toLowerCase()}');
    }
    if (location.isNotEmpty) {
      parts.add('living in $location');
    }
    if (languages.isNotEmpty) {
      final primaryLanguage = languages.split(',').first.trim();
      if (primaryLanguage.isNotEmpty) {
        parts.add('and speak $primaryLanguage');
      }
    }
    if (parts.isEmpty) {
      return 'I am looking for a sincere Muslim partner to build a peaceful Islamic home.';
    }
    return '${parts.join(', ')}. I value honesty, deen, and a marriage built on kindness.';
  }

  static String _buildQuranFocusDisplay(Map<String, dynamic> profile) {
    final activity = FirebaseDataService.quranActivityDisplay(
      (profile['quran_activity'] ?? '').toString(),
    );
    final frequency = FirebaseDataService.quranFrequencyDisplay(
      (profile['quran_frequency'] ?? '').toString(),
    );
    final values = [
      if (activity.isNotEmpty) activity,
      if (frequency.isNotEmpty) frequency,
    ];
    return values.isEmpty ? 'Not shared yet' : values.join(' • ');
  }

  static String _buildIslamicGoalsDisplay(Map<String, dynamic> profile) {
    final goals = (profile['islamic_goals'] ?? '').toString().trim();
    if (goals.isEmpty) {
      return 'To please Allah and build a strong Islamic home.';
    }
    return goals;
  }

  static Future<String> _visibleProfilePhoto({
    required String viewerUid,
    required String profileUid,
    required Map<String, dynamic> profileData,
  }) async {
    final rawPhoto = (profileData['profile_photo_base64'] ?? '').toString().trim();
    if (rawPhoto.isEmpty) {
      return '';
    }

    final lifestyle = Map<String, dynamic>.from(
      profileData['lifestyle_profile'] as Map? ?? const <String, dynamic>{},
    );
    final matchesOnly = lifestyle['photo_privacy_matches_only'] as bool? ?? true;
    if (!matchesOnly) {
      return rawPhoto;
    }
    if (viewerUid.isEmpty) {
      return '';
    }
    if (viewerUid == profileUid) {
      return rawPhoto;
    }

    final matches = await FirebaseDataService.matches
        .where('participant_uids', arrayContains: viewerUid)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (final doc in matches.docs) {
      final data = doc.data();
      final participants =
          (data['participant_uids'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList();
      if (participants.contains(profileUid)) {
        return rawPhoto;
      }
    }
    return '';
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
