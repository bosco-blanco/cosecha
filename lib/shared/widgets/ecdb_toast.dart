import 'package:flutter/material.dart';
import '../../core/theme/ecdb_colors.dart';

enum ToastType { success, error, warning, info }

/// Toast / Snackbar ECDB con colores semánticos.
class ECDBToast {
  ECDBToast._();

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (bgColor, iconData, iconColor) = switch (type) {
      ToastType.success => (ECDBColors.success, Icons.check_circle, Colors.white),
      ToastType.error => (ECDBColors.error, Icons.error, Colors.white),
      ToastType.warning => (ECDBColors.warning, Icons.warning_amber, Colors.white),
      ToastType.info => (ECDBColors.info, Icons.info, Colors.white),
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
}
