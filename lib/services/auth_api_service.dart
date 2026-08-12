import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/auth_session_store.dart';
import 'firebase_data_service.dart';

class AuthApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String gender,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Account could not be created.');
      }

      await firebaseUser.updateDisplayName(fullName.trim());

      final userMap = await FirebaseDataService.ensureUserDocument(
        firebaseUser: firebaseUser,
        fullName: fullName.trim(),
        phoneNumber: '+255 ${phoneNumber.trim()}',
        gender: gender.trim().toLowerCase(),
        authProvider: 'email',
      );

      await AuthSessionStore.saveUser(userMap);
      await _auth.signOut();
      await AuthSessionStore.clear();
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseAuthError(error));
    }
  }

  static Future<void> login({
    required String identifier,
    required String password,
  }) async {
    try {
      UserCredential credential;
      final normalizedIdentifier = identifier.trim();
      if (normalizedIdentifier.contains('@')) {
        credential = await _auth.signInWithEmailAndPassword(
          email: normalizedIdentifier.toLowerCase(),
          password: password,
        );
      } else {
        final userDoc = await FirebaseDataService.findUserDocumentByPhone(
          normalizedIdentifier,
        );
        if (userDoc == null) {
          throw Exception('Invalid email/phone or password.');
        }
        final email = (userDoc.data()['email'] ?? '').toString().trim();
        if (email.isEmpty) {
          throw Exception('This account cannot be logged in with a phone number yet.');
        }
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed.');
      }

      final userMap = await FirebaseDataService.ensureUserDocument(
        firebaseUser: firebaseUser,
      );

      await AuthSessionStore.saveSession(
        accessTokenValue: await firebaseUser.getIdToken() ?? '',
        refreshTokenValue: firebaseUser.refreshToken ?? '',
        userValue: userMap,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseAuthError(error));
    }
  }

  static Future<void> socialLogin({
    required String provider,
    required String providerUserId,
    required String email,
    required String fullName,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('Social login did not complete.');
    }

    final userMap = await FirebaseDataService.ensureUserDocument(
      firebaseUser: firebaseUser,
      fullName: fullName.trim().isEmpty ? null : fullName.trim(),
      authProvider: provider.trim().toLowerCase(),
    );

    await AuthSessionStore.saveSession(
      accessTokenValue: await firebaseUser.getIdToken() ?? '',
      refreshTokenValue: firebaseUser.refreshToken ?? '',
      userValue: {
        ...userMap,
        'social_provider_user_id': providerUserId,
        if (email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
      },
    );
  }

  static Future<Map<String, dynamic>> requestEmailPasswordReset({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return {
        'message': 'Reset email sent successfully.',
      };
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseAuthError(error));
    }
  }

  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    throw Exception('Email OTP verification is not used with Firebase reset email.');
  }

  static Future<Map<String, dynamic>> verifyPhoneReset({
    required String firebaseIdToken,
    required String phoneNumber,
  }) async {
    final normalizedPhone = FirebaseDataService.normalizePhoneNumber(phoneNumber);
    final userDoc = await FirebaseDataService.findUserDocumentByPhone(
      normalizedPhone,
    );
    if (userDoc == null) {
      throw Exception('No account was found for this verified phone number.');
    }

    final email = (userDoc.data()['email'] ?? '').toString().trim().toLowerCase();
    if (email.isEmpty) {
      throw Exception(
        'This phone number is verified, but the linked account has no email to send a reset link to.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseAuthError(error));
    }

    return {
      'reset_token': firebaseIdToken.trim(),
      'email': email,
      'message': 'Phone verified successfully. Reset email sent.',
    };
  }

  static Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      throw Exception('Passwords do not match.');
    }
    throw Exception(
      'Use the reset link sent to email to set a new password in Firebase.',
    );
  }

  static String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email/phone or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Something went wrong. Please try again.';
    }
  }
}
