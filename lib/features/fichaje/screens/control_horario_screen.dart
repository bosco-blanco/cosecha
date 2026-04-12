import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/fichaje.dart';
import '../../../core/providers/fichaje_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/csv_export.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_loading.dart';
import '../../../shared/widgets/ecdb_toast.dart';

/// Control Horario — vista manager con tabla de empleados, filtros, export CSV.
class ControlHorarioScreen extends ConsumerStatefulWidget {
  const ControlHorarioScreen({super.key});

  @override
  ConsumerState<ControlHorarioScreen> createState() =>
      _ControlHorarioScreenState();
}

class _ControlHorarioScreenState extends ConsumerState<ControlHorarioScreen> {
  DateTime _desde = CosechaDateUtils.startOfWeek();
  DateTime _hasta = DateTime.now();
  String? _filtroEmpleado;

  @override
  Widget build(BuildContext context) {
    final fichajesAsync = ref.watch(
      fichajesEquipoProvider((desde: _desde, hasta: _hasta)),
    );

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Control Horario',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar CSV',
            onPressed: () => _exportCsv(fichajesAsync),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: fichajesAsync.when(
        data: (fichajes) {
          if (fichajes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 64, color: ECDBColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Sin fichajes en este periodo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          // Agrupar por empleado
          final porEmpleado = <String, List<Fichaje>>{};
          for (final f in fichajes) {
            final key = f.empleadoNombre;
            if (_filtroEmpleado != null &&
                !key.toLowerCase().contains(_filtroEmpleado!.toLowerCase())) {
              continue;
            }
            porEmpleado.putIfAbsent(key, () => []).add(f);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Periodo seleccionado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 16, color: ECDBColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      '${CosechaDateUtils.formatDate(_desde)} — ${CosechaDateUtils.formatDate(_hasta)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ECDBColors.textSecondary,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${porEmpleado.length} empleados',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Tabla por empleado
              ...porEmpleado.entries.map((entry) {
                final nombre = entry.key;
                final fs = entry.value;
                final entradas = fs.where((f) => f.isEntrada).length;
                final salidas = fs.where((f) => f.isSalida).length;
                final anomalias = fs.where((f) => !f.valido).length;

                // Calcular horas totales
                Duration horasTotales = Duration.zero;
                final sorted = [...fs]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                for (int i = 0; i < sorted.length - 1; i++) {
                  if (sorted[i].isEntrada && sorted[i + 1].isSalida) {
                    horasTotales += sorted[i + 1].timestamp.difference(sorted[i].timestamp);
                    i++; // Skip the salida
                  }
                }

                return ECDBCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: ECDBColors.wine.withOpacity(0.1),
                            child: Text(
                              nombre.isNotEmpty ? nombre[0] : '?',
                              style: const TextStyle(
                                color: ECDBColors.wine,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nombre,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: ECDBColors.textPrimary,
                                  ),
                            ),
                          ),
                          if (anomalias > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: ECDBColors.warningLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$anomalias anomalías',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ECDBColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.schedule,
                            label: CosechaDateUtils.formatDuration(horasTotales),
                            color: ECDBColors.wine,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.login,
                            label: '$entradas entradas',
                            color: ECDBColors.success,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.logout,
                            label: '$salidas salidas',
                            color: ECDBColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const ECDBLoadingIndicator(message: 'Cargando fichajes del equipo...'),
        error: (err, _) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Periodo', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _PeriodChip('Hoy', () {
                    final hoy = DateTime.now();
                    setState(() {
                      _desde = DateTime(hoy.year, hoy.month, hoy.day);
                      _hasta = hoy;
                    });
                    Navigator.pop(ctx);
                  }),
                  _PeriodChip('Esta semana', () {
                    setState(() {
                      _desde = CosechaDateUtils.startOfWeek();
                      _hasta = DateTime.now();
                    });
                    Navigator.pop(ctx);
                  }),
                  _PeriodChip('Este mes', () {
                    setState(() {
                      _desde = CosechaDateUtils.startOfMonth();
                      _hasta = DateTime.now();
                    });
                    Navigator.pop(ctx);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportCsv(AsyncValue<List<Fichaje>> fichajesAsync) {
    fichajesAsync.when(
      data: (fichajes) {
        if (fichajes.isEmpty) {
          ECDBToast.show(context, message: 'No hay datos para exportar', type: ToastType.warning);
          return;
        }
        final csv = CsvExport.fichajesACsv(fichajes);
        // En producción: usar share_plus para compartir/descargar el CSV
        ECDBToast.show(
          context,
          message: 'CSV generado (${fichajes.length} registros)',
          type: ToastType.success,
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ECDBColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PeriodChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
