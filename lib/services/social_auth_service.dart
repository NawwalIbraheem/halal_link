import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_api_service.dart';

class SocialAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
  );

  static Future<void> signInWithGoogle() async {
    if (!(kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      throw Exception('Google sign-in is available only on Android, iPhone, and web.');
    }

    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();

      if (account == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      await AuthApiService.socialLogin(
        provider: 'google',
        providerUserId: account.id,
        email: account.email,
        fullName: account.displayName ?? '',
      );
    } on PlatformException catch (error) {
      throw Exception(_googleSignInErrorMessage(error));
    }
  }

  static Future<void> signInWithApple() async {
    if (kIsWeb ||
        !(
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS
        )) {
      throw Exception('Apple sign-in is available only on Apple devices.');
    }

    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw Exception('Apple sign-in is not available on this device.');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final providerUserId = credential.userIdentifier?.trim() ?? '';
    if (providerUserId.isEmpty) {
      throw Exception('Apple sign-in did not return an account identifier.');
    }

    final nameParts = [
      credential.givenName?.trim() ?? '',
      credential.familyName?.trim() ?? '',
    ].where((value) => value.isNotEmpty).toList();

    await AuthApiService.socialLogin(
      provider: 'apple',
      providerUserId: providerUserId,
      email: credential.email ?? '',
      fullName: nameParts.join(' '),
    );
  }

  static String _googleSignInErrorMessage(PlatformException error) {
    final code = error.code.trim();
    final message = (error.message ?? '').trim();
    final details = (error.details ?? '').toString().trim();
    final raw = '$code $message $details';

    if (code == 'sign_in_failed' && raw.contains('ApiException: 10')) {
      return 'Google Sign-In is not configured for this Android app yet. Add package name com.example.nikah_link and SHA1 DD:A7:5F:9F:AE:68:9E:4E:B5:0B:73:5C:1E:66:C6:35:30:C0:4A:FF in Google Cloud or Firebase, then download the Android config and rebuild.';
    }

    if (code == 'network_error') {
      return 'Google Sign-In needs internet access. Check the phone connection and try again.';
    }

    return 'Google Sign-In failed. ${message.isNotEmpty ? message : code}';
  }
}
