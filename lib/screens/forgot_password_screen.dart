import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/auth_input_utils.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isNavigating = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _goBackToLogin() {
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openEmailResetPlaceholder() {
    if (_isNavigating) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isNavigating = true;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ResetFlowPlaceholderScreen(
          title: 'Check your email or SMS',
          subtitle:
              'This placeholder confirms that a reset link would be sent to the account details you entered.',
          details:
              'In the production flow, this screen can show delivery status, resend timing, and the next password reset step.',
          icon: Icons.mark_email_read_outlined,
        ),
      ),
    ).then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNavigating = false;
      });
    });
  }

  void _openOtpResetPlaceholder() {
    if (_isNavigating) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!AuthInputUtils.isValidTzPhone(_identifierController.text.trim())) {
      AppSnackbar.show(
        context,
        'OTP reset requires a valid phone number like +255 658 541 690.',
      );
      return;
    }
    setState(() {
      _isNavigating = true;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ResetFlowPlaceholderScreen(
          title: 'Phone OTP verification',
          subtitle:
              'This placeholder represents the next step where the user verifies a one-time code sent to their phone.',
          details:
              'Later, this can become the full OTP screen with code entry, resend logic, and a secure password reset handoff.',
          icon: Icons.sms_outlined,
        ),
      ),
    ).then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNavigating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfffbfbf7),
        extendBodyBehindAppBar: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final topInset = MediaQuery.of(context).padding.top;
            final bottomInset = MediaQuery.of(context).padding.bottom;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xfffdfdfb), Color(0xfff7f4eb)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.05,
                      child: Image.asset(
                        'lib/assets/images/Mosque Skyline.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              topInset + 24,
                              20,
                              bottomInset + 10,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Image.asset(
                                    'lib/assets/images/nikah_link_icon_green.png',
                                    width: 126,
                                    height: 126,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 10),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Nikah ',
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.blueGrey.shade800,
                                            letterSpacing: -0.7,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'Link',
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryGreen,
                                            letterSpacing: -0.7,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 1.4,
                                        color: const Color.fromRGBO(
                                          200,
                                          155,
                                          36,
                                          0.85,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Halal Connections. Lifelong Commitment.',
                                        style: TextStyle(
                                          color: Color(0xff495057),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 22,
                                        height: 1.4,
                                        color: const Color.fromRGBO(
                                          200,
                                          155,
                                          36,
                                          0.85,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff202124),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Don\'t worry! We\'ll help you reset it. 🤎',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff5f6368),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Enter your registered phone number or email and we\'ll send you a reset link.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: Color(0xff5f6368),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _AuthField(
                                    hintText: 'Phone number or email',
                                    prefixIcon: Icons.person_outline,
                                    controller: _identifierController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator:
                                        AuthInputUtils.validatePhoneOrEmail,
                                    inputFormatters: const [
                                      _PhoneOrEmailInputFormatter(),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _openEmailResetPlaceholder,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Send Reset Link',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xffded8cc),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          'or',
                                          style: TextStyle(
                                            color: Color(0xff7a7a7a),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xffded8cc),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: _openOtpResetPlaceholder,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primaryGreen,
                                        side: const BorderSide(
                                          color: AppColors.primaryGreen,
                                          width: 1.2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Reset via Phone (OTP)',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Center(
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        const Text(
                                          'Remember your password? ',
                                          style: TextStyle(
                                            color: Color(0xff434343),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _goBackToLogin,
                                          child: const Text(
                                            'Login',
                                            style: TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset + 10,
                    left: 14,
                    child: IconButton(
                      onPressed: _goBackToLogin,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primaryGreen,
                        size: 26,
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset + 10,
                    right: 18,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'EN',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primaryGreen,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
  });

  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xff8a8a8a),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xff4b4b4b), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffdbd8cf)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffdbd8cf)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _PhoneOrEmailInputFormatter extends TextInputFormatter {
  const _PhoneOrEmailInputFormatter();

  bool _looksLikeEmail(String value) {
    return value.contains('@') || RegExp(r'[A-Za-z]').hasMatch(value);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trimmed = newValue.text.trimLeft();
    if (trimmed.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (_looksLikeEmail(trimmed)) {
      return newValue;
    }

    return const TzPhoneInputFormatter().formatEditUpdate(oldValue, newValue);
  }
}

class ResetFlowPlaceholderScreen extends StatelessWidget {
  const ResetFlowPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String details;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfffbfbf7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryGreen,
          title: const Text(
            'Reset Password',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffe6e0d3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(31, 43, 33, 0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xffeef6ee),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: AppColors.primaryGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff202124),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Color(0xff5f6368),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xfff4efe2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    details,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xff4f4a3f),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
