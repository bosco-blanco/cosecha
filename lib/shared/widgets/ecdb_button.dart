import 'package:flutter/material.dart';
import '../../core/theme/ecdb_colors.dart';

enum ECDBButtonVariant { primary, secondary, outlined, danger, ghost }

/// Botón ECDB con variantes y estado de carga.
class ECDBButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ECDBButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double? height;

  const ECDBButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ECDBButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);
    if (isExpanded) {
      return SizedBox(
        width: double.infinity,
        height: height ?? 52,
        child: button,
      );
    }
    return SizedBox(height: height, child: button);
  }

  Widget _buildButton(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    switch (variant) {
      case ECDBButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ECDBButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ECDBColors.bgAlt,
            foregroundColor: ECDBColors.textPrimary,
          ),
          child: child,
        );
      case ECDBButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ECDBButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ECDBColors.error,
            foregroundColor: Colors.white,
          ),
          child: child,
        );
      case ECDBButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}
