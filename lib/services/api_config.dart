import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get authBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/auth';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api/auth';
      default:
        return 'http://127.0.0.1:8000/api/auth';
    }
  }
}
