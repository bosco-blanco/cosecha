import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/tarea.dart';
import '../../../core/models/comentario.dart';
import '../../../core/providers/tareas_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_toast.dart';

class TareaDetalleScreen extends ConsumerStatefulWidget {
  final Tarea tarea;
  const TareaDetalleScreen({super.key, required this.tarea});

  @override
  ConsumerState<TareaDetalleScreen> createState() => _TareaDetalleScreenState();
}

class _TareaDetalleScreenState extends ConsumerState<TareaDetalleScreen> {
  final _commentCtrl = TextEditingController();
  List<Comentario> _comentarios = [];

  @override
  void initState() {
    super.initState();
    _loadComentarios();
  }

  Future<void> _loadComentarios() async {
    try {
      final data = await SupabaseService.client
          .from('comentarios')
          .select()
          .eq('entidad_tipo', 'tarea')
          .eq('entidad_id', widget.tarea.id)
          .order('created_at', ascending: true);

      setState(() {
        _comentarios = (data as List).map((j) => Comentario.fromJson(j)).toList();
      });
    } catch (_) {}
  }

  Future<void> _enviarComentario() async {
    final texto = _commentCtrl.text.trim();
    if (texto.isEmpty) return;

    final empleado = ref.read(currentEmpleadoProvider);
    if (empleado == null) return;

    try {
      await SupabaseService.client.from('comentarios').insert({
        'entidad_tipo': 'tarea',
        'entidad_id': widget.tarea.id,
        'autor_id': empleado.id,
        'autor_nombre': empleado.nombre,
        'texto': texto,
      });
      _commentCtrl.clear();
      await _loadComentarios();
    } catch (e) {
      if (mounted) ECDBToast.show(context, message: 'Error: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tarea;
    final prioridadColor = switch (t.prioridad) {
      PrioridadTarea.critica => ECDBColors.error,
      PrioridadTarea.alta => ECDBColors.warning,
      PrioridadTarea.normal => ECDBColors.info,
      PrioridadTarea.baja => ECDBColors.textMuted,
    };

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Detalle',
        actions: [
          PopupMenuButton<ColumnaTarea>(
            icon: const Icon(Icons.more_vert),
            onSelected: (col) {
              ref.read(tareasProvider.notifier).moverTarea(t.id, col);
              ECDBToast.show(context, message: 'Movida a ${col.name}', type: ToastType.success);
            },
            itemBuilder: (_) => ColumnaTarea.values.map((c) => PopupMenuItem(
              value: c,
              child: Text('Mover a ${c.name}'),
            )).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Título
                Text(t.titulo, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),

                // Metadatos
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _Chip(label: t.columna.name, color: ECDBColors.wine),
                    _Chip(label: t.prioridad.name, color: prioridadColor),
                    if (t.fechaLimite != null)
                      _Chip(label: CosechaDateUtils.formatDate(t.fechaLimite!), color: ECDBColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),

                // Descripción
                if (t.descripcion != null && t.descripcion!.isNotEmpty) ...[
                  Text('Descripción', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(t.descripcion!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],

                // Etiquetas
                if (t.etiquetas.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    children: t.etiquetas.map((e) => Chip(label: Text(e))).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const SizedBox(height: 8),

                // Comentarios
                Text('Comentarios (${_comentarios.length})',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),

                ..._comentarios.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ECDBCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: ECDBColors.wine.withOpacity(0.1),
                              child: Text(c.autorNombre[0],
                                  style: const TextStyle(fontSize: 12, color: ECDBColors.wine, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Text(c.autorNombre,
                                style: Theme.of(context).textTheme.labelLarge),
                            const Spacer(),
                            Text(CosechaDateUtils.timeAgo(c.creado),
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(c.texto, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )),

                if (_comentarios.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Sin comentarios todavía',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ECDBColors.textMuted)),
                  ),
              ],
            ),
          ),

          // Input de comentario
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ECDBColors.surface,
              border: Border(top: BorderSide(color: ECDBColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _enviarComentario(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: ECDBColors.wine),
                    onPressed: _enviarComentario,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
