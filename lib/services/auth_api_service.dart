import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/auth_session_store.dart';
import 'api_config.dart';

class AuthApiService {
  static Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': fullName,
          'email': email.trim().toLowerCase(),
          'phone_number': '+255 ${phoneNumber.trim()}',
          'password': password,
        }),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode == 201) {
      return;
    }

    throw Exception(_extractErrorMessage(response));
  }

  static Future<void> login({
    required String identifier,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier.trim(),
          'password': password,
        }),
      );
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    }

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }

    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    await AuthSessionStore.saveSession(
      accessTokenValue: data['access'] as String? ?? '',
      refreshTokenValue: data['refresh'] as String? ?? '',
      userValue: Map<String, dynamic>.from(data['user'] as Map? ?? {}),
    );
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final values = decoded.values.toList();
        final firstValue = values.isNotEmpty ? values.first : null;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue != null) {
          return firstValue.toString();
        }
      }
    } catch (_) {
      // Fall back to a generic message below.
    }

    return 'Something went wrong. Please try again.';
  }

  static String _backendUnavailableMessage() {
    return 'Cannot reach the backend at ${ApiConfig.authBaseUrl}. Start the Django server and try again.';
  }
}
