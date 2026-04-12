import 'package:flutter/material.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/fichaje.dart';

/// Calendario mensual con colores por estado de fichaje.
/// Verde = fichado correctamente, naranja = anomalía, rojo = sin fichar.
class CalendarioMensual extends StatelessWidget {
  final DateTime mes;
  final List<Fichaje> fichajes;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;

  const CalendarioMensual({
    super.key,
    required this.mes,
    required this.fichajes,
    this.selectedDay,
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final primerDia = DateTime(mes.year, mes.month, 1);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0);
    final diasEnMes = ultimoDia.day;
    // Lunes = 1, ajustar para que la semana empiece en lunes
    final offsetInicio = (primerDia.weekday - 1) % 7;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ECDBColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ECDBColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Cabecera días de la semana
          Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Días del mes
          ...List.generate(
            ((diasEnMes + offsetInicio) / 7).ceil(),
            (week) {
              return Row(
                children: List.generate(7, (weekday) {
                  final dayIndex = week * 7 + weekday - offsetInicio + 1;
                  if (dayIndex < 1 || dayIndex > diasEnMes) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final dia = DateTime(mes.year, mes.month, dayIndex);
                  final hoy = DateTime.now();
                  final esPasado = dia.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
                  final esHoy = dia.year == hoy.year &&
                      dia.month == hoy.month &&
                      dia.day == hoy.day;
                  final esSeleccionado = selectedDay != null &&
                      dia.year == selectedDay!.year &&
                      dia.month == selectedDay!.month &&
                      dia.day == selectedDay!.day;

                  // Estado del día
                  final fichajesDia = fichajes.where((f) {
                    final d = f.timestamp;
                    return d.year == dia.year &&
                        d.month == dia.month &&
                        d.day == dia.day;
                  }).toList();

                  Color? dotColor;
                  if (fichajesDia.isNotEmpty) {
                    final tieneEntrada = fichajesDia.any((f) => f.isEntrada);
                    final tieneSalida = fichajesDia.any((f) => f.isSalida);
                    final tieneAnomalia = fichajesDia.any((f) => !f.valido);

                    if (tieneAnomalia) {
                      dotColor = ECDBColors.warning;
                    } else if (tieneEntrada && tieneSalida) {
                      dotColor = ECDBColors.success;
                    } else if (tieneEntrada) {
                      dotColor = ECDBColors.info;
                    }
                  } else if (esPasado && dia.weekday < 6) {
                    // Día laborable pasado sin fichaje
                    dotColor = ECDBColors.error.withOpacity(0.5);
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDaySelected?.call(dia),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: esSeleccionado
                              ? ECDBColors.wine
                              : esHoy
                                  ? ECDBColors.wine.withOpacity(0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayIndex',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: esHoy || esSeleccionado
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: esSeleccionado
                                    ? Colors.white
                                    : dia.weekday >= 6
                                        ? ECDBColors.textMuted
                                        : ECDBColors.textPrimary,
                              ),
                            ),
                            if (dotColor != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: esSeleccionado
                                      ? Colors.white
                                      : dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Leyenda
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: ECDBColors.success, label: 'Completo'),
              const SizedBox(width: 16),
              _Legend(color: ECDBColors.warning, label: 'Anomalía'),
              const SizedBox(width: 16),
              _Legend(color: ECDBColors.error.withOpacity(0.5), label: 'Sin fichar'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
