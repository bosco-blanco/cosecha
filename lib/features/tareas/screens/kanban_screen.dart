import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/tarea.dart';
import '../../../core/providers/tareas_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_loading.dart';
import '../widgets/tarea_card.dart';
import '../widgets/columna_kanban.dart';

/// Tablero Kanban con 4 columnas y drag & drop.
class KanbanScreen extends ConsumerWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tareasState = ref.watch(tareasProvider);

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Tareas',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tareasProvider.notifier).loadTareas(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/tareas/crear'),
          ),
        ],
      ),
      body: tareasState.isLoading && tareasState.todas.isEmpty
          ? const ECDBLoadingIndicator(message: 'Cargando tareas...')
          : RefreshIndicator(
              onRefresh: () => ref.read(tareasProvider.notifier).loadTareas(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColumnaKanban(
                      titulo: 'Backlog',
                      color: ECDBColors.textMuted,
                      columna: ColumnaTarea.backlog,
                      tareas: tareasState.backlog,
                      onMover: (id, col) =>
                          ref.read(tareasProvider.notifier).moverTarea(id, col),
                    ),
                    const SizedBox(width: 12),
                    ColumnaKanban(
                      titulo: 'En Progreso',
                      color: ECDBColors.info,
                      columna: ColumnaTarea.enProgreso,
                      tareas: tareasState.enProgreso,
                      onMover: (id, col) =>
                          ref.read(tareasProvider.notifier).moverTarea(id, col),
                    ),
                    const SizedBox(width: 12),
                    ColumnaKanban(
                      titulo: 'Revisión',
                      color: ECDBColors.warning,
                      columna: ColumnaTarea.revision,
                      tareas: tareasState.revision,
                      onMover: (id, col) =>
                          ref.read(tareasProvider.notifier).moverTarea(id, col),
                    ),
                    const SizedBox(width: 12),
                    ColumnaKanban(
                      titulo: 'Completado',
                      color: ECDBColors.success,
                      columna: ColumnaTarea.completado,
                      tareas: tareasState.completado,
                      onMover: (id, col) =>
                          ref.read(tareasProvider.notifier).moverTarea(id, col),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
