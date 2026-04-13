import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/tarea.dart';
import '../../../core/utils/date_utils.dart';

/// Card de tarea — draggable para el Kanban.
class TareaCard extends StatelessWidget {
  final Tarea tarea;

  const TareaCard({super.key, required this.tarea});

  @override
  Widget build(BuildContext context) {
    final prioridadColor = switch (tarea.prioridad) {
      PrioridadTarea.critica => ECDBColors.error,
      PrioridadTarea.alta => ECDBColors.warning,
      PrioridadTarea.normal => ECDBColors.info,
      PrioridadTarea.baja => ECDBColors.textMuted,
    };

    return LongPressDraggable<String>(
      data: tarea.id,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ECDBColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(tarea.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCard(context, prioridadColor),
      ),
      child: GestureDetector(
        onTap: () => context.push('/tareas/detalle', extra: tarea),
        child: _buildCard(context, prioridadColor),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color prioridadColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ECDBColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ECDBColors.border, width: 0.5),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: prioridadColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                tarea.prioridad.name.toUpperCase(),
                style: TextStyle(fontSize: 10, color: prioridadColor, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (tarea.fechaLimite != null)
                Text(
                  CosechaDateUtils.formatDayMonth(tarea.fechaLimite!),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tarea.titulo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tarea.descripcion!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ],
          if (tarea.etiquetas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: tarea.etiquetas.take(3).map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ECDBColors.bgAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(e, style: const TextStyle(fontSize: 10, color: ECDBColors.textSecondary)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
