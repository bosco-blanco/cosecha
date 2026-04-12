import 'package:flutter/material.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/fichaje.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_constants.dart';

/// Resumen semanal de horas — muestra horas por día + total + horas extra.
class ResumenSemanal extends StatelessWidget {
  final List<Fichaje> fichajes;

  const ResumenSemanal({super.key, required this.fichajes});

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final inicioSemana = CosechaDateUtils.startOfWeek(ahora);
    final horasPorDia = <int, Duration>{};
    final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    // Calcular horas por día de la semana actual
    for (int d = 0; d < 7; d++) {
      final dia = inicioSemana.add(Duration(days: d));
      final fichajesDia = fichajes.where((f) {
        final t = f.timestamp;
        return t.year == dia.year && t.month == dia.month && t.day == dia.day;
      }).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      Duration total = Duration.zero;
      for (int i = 0; i < fichajesDia.length - 1; i += 2) {
        if (fichajesDia[i].isEntrada &&
            i + 1 < fichajesDia.length &&
            fichajesDia[i + 1].isSalida) {
          total += fichajesDia[i + 1].timestamp.difference(fichajesDia[i].timestamp);
        }
      }
      horasPorDia[d] = total;
    }

    final totalSemana = horasPorDia.values.fold(Duration.zero, (a, b) => a + b);
    final horasExtra = CosechaDateUtils.calcularHorasExtra(
      horasPorDia.values.toList(),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ECDBColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ECDBColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Esta semana',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ECDBColors.textPrimary,
                    ),
              ),
              Text(
                CosechaDateUtils.formatDuration(totalSemana),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (horasExtra > Duration.zero) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.warning_amber, size: 14, color: ECDBColors.warning),
                const SizedBox(width: 4),
                Text(
                  '${CosechaDateUtils.formatDuration(horasExtra)} horas extra',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ECDBColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Barras por día
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final horas = horasPorDia[i] ?? Duration.zero;
              final horasNum = horas.inMinutes / 60;
              final maxHeight = 60.0;
              final barHeight = horasNum > 0 ? (horasNum / 10 * maxHeight).clamp(4.0, maxHeight) : 0.0;
              final esHoy = i == (ahora.weekday - 1);

              return Expanded(
                child: Column(
                  children: [
                    if (horasNum > 0)
                      Text(
                        '${horasNum.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: esHoy ? ECDBColors.wine : ECDBColors.textMuted,
                            ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      height: barHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: horasNum > 8
                            ? ECDBColors.warning
                            : esHoy
                                ? ECDBColors.wine
                                : ECDBColors.gold.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      diasSemana[i],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: esHoy ? FontWeight.w700 : FontWeight.w400,
                            color: esHoy ? ECDBColors.wine : ECDBColors.textMuted,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Línea de 8h objetivo
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Objetivo: ${AppConstants.standardWeeklyHours}h/semana',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ECDBColors.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
