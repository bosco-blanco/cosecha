import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/fichaje_provider.dart';
import '../../../core/utils/date_utils.dart';

/// Tarjetas KPI del día — horas trabajadas, estado, fichajes del día.
class KpiCards extends ConsumerWidget {
  const KpiCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fichaje = ref.watch(fichajeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              label: 'Horas hoy',
              value: CosechaDateUtils.formatDuration(fichaje.tiempoTrabajado),
              icon: Icons.schedule,
              color: ECDBColors.wine,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              label: 'Fichajes',
              value: '${fichaje.fichajesHoy.length}',
              icon: Icons.fingerprint,
              color: ECDBColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ECDBColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ECDBColors.border, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
