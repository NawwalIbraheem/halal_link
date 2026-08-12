import 'package:firebase_auth/firebase_auth.dart';

class PhoneResetService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> sendCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken)
    onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {},
      verificationFailed: (error) {
        throw Exception(_mapError(error));
      },
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  static Future<Map<String, String>> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw Exception('Phone verification failed.');
    }

    final idToken = await user.getIdToken();
    final phoneNumber = user.phoneNumber?.trim() ?? '';
    await _auth.signOut();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Phone verification failed.');
    }
    if (phoneNumber.isEmpty) {
      throw Exception('Verified phone number is missing.');
    }
    return {
      'id_token': idToken,
      'phone_number': phoneNumber,
    };
  }

  static String _mapError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number.';
      case 'too-many-requests':
        return 'Too many requests. Please wait and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Phone verification failed.';
    }
  }
}
