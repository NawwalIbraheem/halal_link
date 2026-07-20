import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _localNetworkHost = '172.25.179.1';

  static String get authBaseUrl {
    if (_overrideBaseUrl.trim().isNotEmpty) {
      return _overrideBaseUrl.trim();
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/auth';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Real Android phones cannot reach the computer through 10.0.2.2.
        // Use the computer's current Wi-Fi IP during local development.
        return 'http://$_localNetworkHost:8000/api/auth';
      default:
        return 'http://127.0.0.1:8000/api/auth';
    }
  }
}
