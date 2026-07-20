import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
        ),
      );
  }
}
