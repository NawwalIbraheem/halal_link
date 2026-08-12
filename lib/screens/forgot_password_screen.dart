import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/auth_api_service.dart';
import '../services/phone_reset_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/auth_input_utils.dart';
import 'login_screen.dart';

enum _ResetMethod { email, phone }

enum _ResetStep { chooseMethod, enterContact, verifyOtp, setNewPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _contactFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ResetMethod _method = _ResetMethod.email;
  _ResetStep _step = _ResetStep.chooseMethod;
  bool _isSubmitting = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _resetToken = '';
  String _verificationId = '';
  String _successMessage = '';

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goBackToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          initialIdentifier: _identifierController.text.trim(),
        ),
      ),
      (route) => false,
    );
  }

  String get _normalizedPhone {
    final local = _identifierController.text.trim();
    return '+255 ${local.replaceAll(RegExp(r'\s+'), ' ').trim()}';
  }

  String get _backendPhone {
    return _normalizedPhone.replaceAll(' ', '');
  }

  Future<void> _sendCode() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_contactFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_method == _ResetMethod.email) {
        await AuthApiService.requestEmailPasswordReset(
          email: _identifierController.text.trim(),
        );
        if (!mounted) {
          return;
        }
        AppSnackbar.show(
          context,
          'Reset email sent successfully. Please check your inbox.',
        );
        setState(() {
          _successMessage =
              'We sent a password reset link to your email. Open the link in your inbox to reset your password.';
          _step = _ResetStep.success;
        });
      } else {
        await PhoneResetService.sendCode(
          phoneNumber: _backendPhone,
          onCodeSent: (verificationId, resendToken) {
            if (!mounted) {
              return;
            }
            setState(() {
              _verificationId = verificationId;
              _step = _ResetStep.verifyOtp;
            });
            AppSnackbar.show(
              context,
              'Verification code sent to $_backendPhone.',
            );
          },
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_method == _ResetMethod.email) {
        final response = await AuthApiService.verifyEmailOtp(
          email: _identifierController.text.trim(),
          otp: _otpController.text.trim(),
        );
        _resetToken = response['reset_token']?.toString() ?? '';
      } else {
        final verificationResult = await PhoneResetService.verifyCode(
          verificationId: _verificationId,
          smsCode: _otpController.text.trim(),
        );
        final response = await AuthApiService.verifyPhoneReset(
          firebaseIdToken: verificationResult['id_token'] ?? '',
          phoneNumber: verificationResult['phone_number'] ?? '',
        );
        _resetToken = response['reset_token']?.toString() ?? '';
        if (!mounted) {
          return;
        }
        setState(() {
          _successMessage =
              'Phone verified successfully. We sent a password reset link to ${(response['email'] ?? '').toString().trim()}.';
          _step = _ResetStep.success;
        });
        AppSnackbar.show(
          context,
          response['message']?.toString() ??
              'Phone verified successfully. Reset email sent.',
        );
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _step = _ResetStep.setNewPassword;
      });
      AppSnackbar.show(context, 'Verification successful.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthApiService.resetPassword(
        resetToken: _resetToken,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _successMessage =
            'Your password has been reset successfully. You can now log in.';
        _step = _ResetStep.success;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _chooseMethod(_ResetMethod method) {
    setState(() {
      _method = method;
      _step = _ResetStep.enterContact;
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _resetToken = '';
      _verificationId = '';
      _successMessage = '';
    });
  }

  void _goToContactStep() {
    setState(() {
      _step = _ResetStep.enterContact;
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _resetToken = '';
      _verificationId = '';
    });
  }

  void _handleBackArrow() {
    switch (_step) {
      case _ResetStep.chooseMethod:
      case _ResetStep.enterContact:
      case _ResetStep.success:
        _goBackToLogin();
        break;
      case _ResetStep.verifyOtp:
      case _ResetStep.setNewPassword:
        _goToContactStep();
        break;
    }
  }

  String _titleText() {
    switch (_step) {
      case _ResetStep.chooseMethod:
        return 'Forgot Password?';
      case _ResetStep.enterContact:
        return _method == _ResetMethod.email
            ? 'Reset with Email'
            : 'Reset with Phone';
      case _ResetStep.verifyOtp:
        return 'Verify Code';
      case _ResetStep.setNewPassword:
        return 'Create New Password';
      case _ResetStep.success:
        return 'Password Reset';
    }
  }

  String _subtitleText() {
    switch (_step) {
      case _ResetStep.chooseMethod:
        return 'Choose how you want to reset your password.';
      case _ResetStep.enterContact:
        return _method == _ResetMethod.email
            ? 'Enter your registered email and we will send a password reset link.'
            : 'Enter your registered phone number and we will send an SMS verification code.';
      case _ResetStep.verifyOtp:
        return _method == _ResetMethod.email
            ? 'Enter the 6-digit code sent to your email.'
            : 'Enter the 6-digit code sent to your phone.';
      case _ResetStep.setNewPassword:
        return 'Choose a new password for your account.';
      case _ResetStep.success:
        return _successMessage;
    }
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
        backgroundColor: context.appBackground,
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
                                Text(
                                  _titleText(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff202124),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _subtitleText(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Color(0xff5f6368),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildCurrentStep(),
                                const Spacer(),
                              ],
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
                      onPressed: _handleBackArrow,
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case _ResetStep.chooseMethod:
        return Column(
          children: [
            _MethodButton(
              label: 'Reset using Email',
              onTap: () => _chooseMethod(_ResetMethod.email),
            ),
            const SizedBox(height: 14),
            _MethodButton(
              label: 'Reset using Phone Number',
              outlined: true,
              onTap: () => _chooseMethod(_ResetMethod.phone),
            ),
          ],
        );
      case _ResetStep.enterContact:
        return Form(
          key: _contactFormKey,
          child: Column(
            children: [
              _AuthField(
                hintText: _method == _ResetMethod.email
                    ? 'Email address'
                    : 'Phone number',
                prefixIcon: _method == _ResetMethod.email
                    ? Icons.mail_outline
                    : Icons.phone_outlined,
                controller: _identifierController,
                keyboardType: _method == _ResetMethod.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                validator: _method == _ResetMethod.email
                    ? AuthInputUtils.validateEmailRequired
                    : AuthInputUtils.validatePhoneRequired,
                prefixText: _method == _ResetMethod.phone ? '+255 ' : null,
                inputFormatters: _method == _ResetMethod.phone
                    ? const [TzPhoneInputFormatter()]
                    : null,
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: _isSubmitting
                    ? 'Sending...'
                    : _method == _ResetMethod.email
                    ? 'Send Reset Link'
                    : 'Send Code',
                onPressed: _sendCode,
              ),
            ],
          ),
        );
      case _ResetStep.verifyOtp:
        return Form(
          key: _otpFormKey,
          child: Column(
            children: [
              _AuthField(
                hintText: '6-digit verification code',
                prefixIcon: Icons.verified_user_outlined,
                controller: _otpController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final input = (value ?? '').trim();
                  if (input.length != 6 || int.tryParse(input) == null) {
                    return 'Enter the 6-digit verification code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: _isSubmitting ? 'Verifying...' : 'Verify Code',
                onPressed: _verifyCode,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting ? null : _sendCode,
                child: const Text(
                  'Resend code',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      case _ResetStep.setNewPassword:
        return Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              _AuthField(
                hintText: 'New password',
                prefixIcon: Icons.lock_outline,
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                validator: AuthInputUtils.validatePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xff7a7a7a),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AuthField(
                hintText: 'Confirm password',
                prefixIcon: Icons.lock_outline,
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  final error = AuthInputUtils.validatePassword(value);
                  if (error != null) {
                    return error;
                  }
                  if ((value ?? '') != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xff7a7a7a),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: _isSubmitting ? 'Saving...' : 'Reset Password',
                onPressed: _resetPassword,
              ),
            ],
          ),
        );
      case _ResetStep.success:
        return Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xffeef6ee),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primaryGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'Back to Login',
              onPressed: _goBackToLogin,
            ),
          ],
        );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
    this.prefixText,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
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
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Color(0xff202124),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: suffixIcon,
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
