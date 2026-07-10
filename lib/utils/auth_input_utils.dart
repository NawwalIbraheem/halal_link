import 'package:flutter/services.dart';

class AuthInputUtils {
  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _tzPhoneRegex = RegExp(r'^\+255 \d{3} \d{3} \d{3}$');
  static final RegExp _tzLocalPhoneRegex = RegExp(r'^\d{3} \d{3} \d{3}$');

  static bool isValidEmail(String value) {
    return _emailRegex.hasMatch(value.trim());
  }

  static bool isValidTzPhone(String value) {
    return _tzPhoneRegex.hasMatch(value.trim());
  }

  static bool isValidTzLocalPhone(String value) {
    return _tzLocalPhoneRegex.hasMatch(value.trim());
  }

  static String? validatePhoneRequired(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Enter your phone number';
    }
    if (!isValidTzLocalPhone(input)) {
      return 'Use format +255 658 541 690';
    }
    return null;
  }

  static String? validateEmailOptional(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return null;
    }
    if (!isValidEmail(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateEmailRequired(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Enter your email address';
    }
    if (!isValidEmail(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhoneOrEmail(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty || input == '+255') {
      return 'Enter your phone number or email';
    }
    if (isValidEmail(input) || isValidTzPhone(input)) {
      return null;
    }
    return 'Use a valid email or +255 *** *** ***';
  }

  static String? validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter your password';
    }
    if (input.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Enter your full name';
    }
    if (input.length < 3) {
      return 'Full name is too short';
    }
    return null;
  }
}

class TzPhoneInputFormatter extends TextInputFormatter {
  const TzPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    String localDigits = digitsOnly;

    if (localDigits.startsWith('255')) {
      localDigits = localDigits.substring(3);
    }
    if (localDigits.startsWith('0')) {
      localDigits = localDigits.substring(1);
    }
    if (localDigits.length > 9) {
      localDigits = localDigits.substring(0, 9);
    }

    final formatted = _formatLocalDigits(localDigits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _formatLocalDigits(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    final chunks = <String>[];
    for (var i = 0; i < digits.length; i += 3) {
      final end = (i + 3 < digits.length) ? i + 3 : digits.length;
      chunks.add(digits.substring(i, end));
    }
    return chunks.join(' ');
  }
}
