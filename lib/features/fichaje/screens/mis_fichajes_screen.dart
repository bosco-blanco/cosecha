import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/fichaje_provider.dart';
import '../../../core/models/fichaje.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_loading.dart';
import '../widgets/calendario_mensual.dart';
import '../widgets/resumen_semanal.dart';

/// Mis Fichajes — historial personal con calendario visual.
class MisFichajesScreen extends ConsumerStatefulWidget {
  const MisFichajesScreen({super.key});

  @override
  ConsumerState<MisFichajesScreen> createState() => _MisFichajesScreenState();
}

class _MisFichajesScreenState extends ConsumerState<MisFichajesScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  List<Fichaje> _fichajes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final empleado = ref.read(currentEmpleadoProvider);
    if (empleado == null) return;

    try {
      final desde = _selectedMonth;
      final hasta = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

      final data = await ref
          .read(fichajeProvider.notifier)
          .loadHistorial(desde: desde, hasta: hasta)
          .then((_) => ref.read(fichajeProvider).fichajesHistorial);

      if (mounted) {
        setState(() {
          _fichajes = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _selectedDay = null;
    });
    _loadMonth();
  }

  List<Fichaje> get _fichajesDia {
    if (_selectedDay == null) return [];
    return _fichajes.where((f) {
      final d = f.timestamp;
      return d.year == _selectedDay!.year &&
          d.month == _selectedDay!.month &&
          d.day == _selectedDay!.day;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    final fichajesState = ref.watch(fichajeProvider);

    return Scaffold(
      appBar: const ECDBAppBar(title: 'Mis Fichajes'),
      body: _loading
          ? const ECDBLoadingIndicator(message: 'Cargando fichajes...')
          : ListView(
              children: [
                // Navegación de mes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        _monthName(_selectedMonth),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _selectedMonth.month == DateTime.now().month &&
                                _selectedMonth.year == DateTime.now().year
                            ? null
                            : () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),

                // Calendario mensual
                CalendarioMensual(
                  mes: _selectedMonth,
                  fichajes: fichajesState.fichajesHistorial,
                  selectedDay: _selectedDay,
                  onDaySelected: (day) {
                    setState(() => _selectedDay = day);
                  },
                ),
                const SizedBox(height: 16),

                // Resumen semanal
                ResumenSemanal(fichajes: fichajesState.fichajesHistorial),
                const SizedBox(height: 16),

                // Detalle del día seleccionado
                if (_selectedDay != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      CosechaDateUtils.formatFullDate(_selectedDay!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_fichajesDia.isEmpty)
                    ECDBCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Sin fichajes este día',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ECDBColors.textMuted,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._fichajesDia.map((f) => _FichajeRow(fichaje: f)),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  String _monthName(DateTime d) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${meses[d.month - 1]} ${d.year}';
  }
}

class _FichajeRow extends StatelessWidget {
  final Fichaje fichaje;
  const _FichajeRow({required this.fichaje});

  @override
  Widget build(BuildContext context) {
    final esEntrada = fichaje.isEntrada;
    return ECDBCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (esEntrada ? ECDBColors.success : ECDBColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              esEntrada ? Icons.login : Icons.logout,
              color: esEntrada ? ECDBColors.success : ECDBColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esEntrada ? 'Entrada' : 'Salida',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ECDBColors.textPrimary,
                      ),
                ),
                Text(
                  '${fichaje.metodo.name.toUpperCase()} ${fichaje.valido ? "" : "- Fuera de rango"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            CosechaDateUtils.formatTime(fichaje.timestamp),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (!fichaje.valido) ...[
            const SizedBox(width: 8),
            const Icon(Icons.warning_amber, color: ECDBColors.warning, size: 18),
          ],
        ],
      ),
    );
  }
}
