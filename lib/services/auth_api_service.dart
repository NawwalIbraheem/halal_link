import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../utils/auth_session_store.dart';
import 'api_config.dart';

class AuthApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);

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
      ).timeout(_requestTimeout);
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    } on TimeoutException {
      throw Exception(_backendTimeoutMessage());
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
      ).timeout(_requestTimeout);
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    } on TimeoutException {
      throw Exception(_backendTimeoutMessage());
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

  static Future<void> socialLogin({
    required String provider,
    required String providerUserId,
    required String email,
    required String fullName,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/social-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'provider_user_id': providerUserId,
          'email': email.trim().toLowerCase(),
          'full_name': fullName.trim(),
        }),
      ).timeout(_requestTimeout);
    } on http.ClientException {
      throw Exception(_backendUnavailableMessage());
    } on TimeoutException {
      throw Exception(_backendTimeoutMessage());
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

  static String _backendTimeoutMessage() {
    return 'The backend at ${ApiConfig.authBaseUrl} did not respond in time. Make sure Django is running on 0.0.0.0:8000 and the phone is on the same Wi-Fi.';
  }
}
