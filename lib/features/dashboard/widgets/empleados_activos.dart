import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/fichaje_provider.dart';
import '../../../core/utils/date_utils.dart';

/// Widget "Quién está fichado ahora" — realtime via Supabase.
class EmpleadosActivos extends ConsumerWidget {
  const EmpleadosActivos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activosAsync = ref.watch(empleadosActivosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Quién está fichado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ECDBColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'En tiempo real',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ECDBColors.success,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        activosAsync.when(
          data: (fichajes) {
            // Agrupar por empleado — quedarnos con el último fichaje
            final porEmpleado = <String, Map<String, dynamic>>{};
            for (final f in fichajes) {
              final empId = f['empleado_id'] as String;
              if (!porEmpleado.containsKey(empId)) {
                porEmpleado[empId] = f;
              }
            }

            // Filtrar solo los que están "fichados" (último tipo = entrada)
            final activos = porEmpleado.values
                .where((f) => f['tipo'] == 'entrada')
                .toList();

            if (activos.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ECDBColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ECDBColors.border, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    'Nadie fichado ahora mismo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ECDBColors.textMuted,
                        ),
                  ),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                children: [
                  ...activos.take(5).map((f) {
                    final nombre = f['empleado_nombre'] as String? ?? '';
                    final hora = DateTime.parse(f['timestamp'] as String);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: ECDBColors.wine.withOpacity(0.1),
                            child: Text(
                              nombre.isNotEmpty ? nombre[0] : '?',
                              style: const TextStyle(
                                color: ECDBColors.wine,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nombre,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            'desde ${CosechaDateUtils.formatTime(hora)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ECDBColors.textMuted,
                                    ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (activos.length > 5) ...[
                    const Divider(),
                    Text(
                      '+${activos.length - 5} más',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ECDBColors.wine,
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
