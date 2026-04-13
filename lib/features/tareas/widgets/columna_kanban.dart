import 'package:flutter/material.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/tarea.dart';
import 'tarea_card.dart';

/// Columna del Kanban con DragTarget para mover tareas.
class ColumnaKanban extends StatelessWidget {
  final String titulo;
  final Color color;
  final ColumnaTarea columna;
  final List<Tarea> tareas;
  final void Function(String tareaId, ColumnaTarea nuevaColumna) onMover;

  const ColumnaKanban({
    super.key,
    required this.titulo,
    required this.color,
    required this.columna,
    required this.tareas,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        onMover(details.data, columna);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: isHovering
                ? color.withOpacity(0.05)
                : ECDBColors.bgAlt.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: isHovering
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ECDBColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tareas.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Cards
              ...tareas.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TareaCard(tarea: t),
                  )),
              if (tareas.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Arrastra tareas aquí',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ECDBColors.textMuted,
                        ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
