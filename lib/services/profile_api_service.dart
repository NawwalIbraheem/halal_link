import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/auth_session_store.dart';
import 'api_config.dart';

class ProfileApiService {
  static Future<List<Map<String, dynamic>>> getPublicAccounts() async {
    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${ApiConfig.authBaseUrl}/accounts/public/'),
        headers: {'Content-Type': 'application/json'},
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load available profiles.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> getPublicAccountDetail(int accountId) async {
    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${ApiConfig.authBaseUrl}/accounts/public/$accountId/'),
        headers: {'Content-Type': 'application/json'},
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile details.');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<Map<String, dynamic>> sendInterest(int receiverId) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/matches/interests/'),
        headers: _headers(),
        body: jsonEncode(<String, dynamic>{'receiver_id': receiverId}),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      final message = _extractErrorMessage(
        response.body,
        fallback: 'Failed to send interest.',
      );
      throw Exception(message);
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<List<Map<String, dynamic>>> getReceivedInterests() async {
    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${ApiConfig.authBaseUrl}/matches/interests/'),
        headers: _headers(),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load matches.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> getBasicProfile() async {
    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/basic-info/'),
        headers: _headers(),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load basic profile.');
    }

    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    await AuthSessionStore.saveUser(data);
    return data;
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
    late final http.Response response;
    try {
      response = await http.put(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/basic-info/'),
        headers: _headers(),
        body: jsonEncode({
          'full_name': fullName,
          'email': email.trim().toLowerCase(),
          'phone_number': phoneNumber,
          'date_of_birth': dateOfBirth,
          'location': location,
          'education': education,
          'occupation': occupation,
          'languages': languages.join(', '),
          'profile_photo_base64': profilePhotoBase64 ?? '',
        }),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to save basic profile.');
    }

    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    await AuthSessionStore.saveUser(data);
    return data;
  }

  static Future<Map<String, dynamic>> getIslamicProfile() async {
    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/islamic/'),
        headers: _headers(),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load Islamic profile.');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<void> updateIslamicProfile({
    required String prayerLevel,
    required String quranActivity,
    required String quranFrequency,
    required String islamicGoals,
    required List<String> marriageValues,
  }) async {
    late final http.Response response;
    try {
      response = await http.put(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/islamic/'),
        headers: _headers(),
        body: jsonEncode({
          'prayer_level': prayerLevel,
          'quran_activity': quranActivity,
          'quran_frequency': quranFrequency,
          'islamic_goals': islamicGoals,
          'marriage_values': marriageValues,
        }),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to save Islamic profile.');
    }
  }

  static Future<Map<String, dynamic>> getMarriageExpectations() async {
    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/marriage-expectations/'),
        headers: _headers(),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load marriage expectations.');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<void> updateMarriageExpectations({
    required String qualitiesLookingFor,
    required String marriageTimeline,
    required String childrenPreference,
    required String preferredLivingArrangement,
    required String familyInvolvement,
  }) async {
    late final http.Response response;
    try {
      response = await http.put(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/marriage-expectations/'),
        headers: _headers(),
        body: jsonEncode({
          'qualities_looking_for': qualitiesLookingFor,
          'marriage_timeline': marriageTimeline,
          'children_preference': childrenPreference,
          'preferred_living_arrangement': preferredLivingArrangement,
          'family_involvement': familyInvolvement,
        }),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to save marriage expectations.');
    }
  }

  static Future<Map<String, dynamic>> getLifestyleProfile() async {
    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/lifestyle/'),
        headers: _headers(),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load lifestyle profile.');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<void> updateLifestyleProfile({
    required String heightRange,
    required String bodyType,
    required String culturalBackground,
    required String dressStyle,
    required bool photoPrivacyMatchesOnly,
  }) async {
    late final http.Response response;
    try {
      response = await http.put(
        Uri.parse('${ApiConfig.authBaseUrl}/profile/lifestyle/'),
        headers: _headers(),
        body: jsonEncode({
          'height_range': heightRange,
          'body_type': bodyType,
          'cultural_background': culturalBackground,
          'dress_style': dressStyle,
          'photo_privacy_matches_only': photoPrivacyMatchesOnly,
        }),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to save lifestyle profile.');
    }
  }

  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthSessionStore.accessToken}',
    };
  }

  static String _backendUnavailableMessage() {
    return 'Cannot reach the backend at ${ApiConfig.authBaseUrl}. Start the Django server and try again.';
  }

  static String _extractErrorMessage(String responseBody, {required String fallback}) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        for (final value in decoded.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {
      return fallback;
    }

    return fallback;
  }
}
