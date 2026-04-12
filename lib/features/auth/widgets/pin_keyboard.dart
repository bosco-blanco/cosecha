import 'package:flutter/material.dart';
import '../../../core/theme/ecdb_colors.dart';

/// Teclado numérico grande para fichaje por PIN.
/// Diseñado para uso con guantes, pantallas mojadas, prisa.
class PinKeyboard extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const PinKeyboard({
    super.key,
    required this.onDigit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Espacio vacío
            const SizedBox(width: 72, height: 72),
            const SizedBox(width: 16),
            // 0
            _PinKey(label: '0', onTap: () => onDigit('0')),
            const SizedBox(width: 16),
            // Borrar
            SizedBox(
              width: 72,
              height: 72,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(36),
                  child: const Center(
                    child: Icon(
                      Icons.backspace_outlined,
                      color: ECDBColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits
          .map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _PinKey(label: d, onTap: () => onDigit(d)),
              ))
          .toList(),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: ECDBColors.surface,
        borderRadius: BorderRadius.circular(36),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(36),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: ECDBColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
