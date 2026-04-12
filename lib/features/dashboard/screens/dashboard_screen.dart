import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../widgets/clock_widget.dart';
import '../widgets/kpi_cards.dart';
import '../widgets/empleados_activos.dart';

/// Dashboard — pantalla principal con fichaje real + resumen del día.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleado = ref.watch(currentEmpleadoProvider);
    final nombre = empleado?.nombre ?? 'Usuario';
    final hora = TimeOfDay.now().hour;
    final saludo = hora < 12
        ? 'Buenos días'
        : hora < 20
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Cosecha',
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Fichar con QR',
            onPressed: () => context.push('/fichaje/qr'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: ECDBColors.wine,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            onPressed: () => context.push('/mas'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: ECDBColors.wine,
        onRefresh: () async {
          // Refrescar fichajes
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Saludo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$saludo,',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ECDBColors.textSecondary,
                        ),
                  ),
                  Text(
                    nombre.split(' ').first,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Widget de fichaje REAL
            const ClockWidget(),
            const SizedBox(height: 16),

            // KPIs del día (horas + fichajes)
            const KpiCards(),
            const SizedBox(height: 8),

            // Acceso rápido a historial
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () => context.push('/fichaje/historial'),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Ver mis fichajes'),
              ),
            ),

            const SizedBox(height: 16),

            // Empleados activos (realtime)
            if (empleado?.canManage == true) ...[
              const EmpleadosActivos(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: () => context.push('/fichaje/control'),
                  icon: const Icon(Icons.supervisor_account, size: 18),
                  label: const Text('Control horario del equipo'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Anuncios
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Anuncios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            ECDBCard(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ECDBColors.wine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido a Cosecha',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: ECDBColors.textPrimary,
                                  ),
                        ),
                        Text(
                          'Fichaje digital activo. Usa tu PIN o QR para fichar.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
