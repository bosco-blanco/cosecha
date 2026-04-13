import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/tarea.dart';
import '../../../core/providers/tareas_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_button.dart';
import '../../../shared/widgets/ecdb_toast.dart';

class CrearTareaScreen extends ConsumerStatefulWidget {
  const CrearTareaScreen({super.key});

  @override
  ConsumerState<CrearTareaScreen> createState() => _CrearTareaScreenState();
}

class _CrearTareaScreenState extends ConsumerState<CrearTareaScreen> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _etiquetaCtrl = TextEditingController();
  PrioridadTarea _prioridad = PrioridadTarea.normal;
  DateTime? _fechaLimite;
  final List<String> _etiquetas = [];
  bool _saving = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _etiquetaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      ECDBToast.show(context, message: 'El título es obligatorio', type: ToastType.warning);
      return;
    }

    setState(() => _saving = true);
    await ref.read(tareasProvider.notifier).crearTarea(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      prioridad: _prioridad,
      fechaLimite: _fechaLimite,
      etiquetas: _etiquetas,
    );

    if (mounted) {
      ECDBToast.show(context, message: 'Tarea creada', type: ToastType.success);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Nueva Tarea'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _tituloCtrl,
            decoration: const InputDecoration(labelText: 'Título *'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Prioridad
          Text('Prioridad', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<PrioridadTarea>(
            segments: const [
              ButtonSegment(value: PrioridadTarea.baja, label: Text('Baja')),
              ButtonSegment(value: PrioridadTarea.normal, label: Text('Normal')),
              ButtonSegment(value: PrioridadTarea.alta, label: Text('Alta')),
              ButtonSegment(value: PrioridadTarea.critica, label: Text('Crítica')),
            ],
            selected: {_prioridad},
            onSelectionChanged: (s) => setState(() => _prioridad = s.first),
          ),
          const SizedBox(height: 16),

          // Fecha límite
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(_fechaLimite != null
                ? '${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}'
                : 'Sin fecha límite'),
            trailing: _fechaLimite != null
                ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _fechaLimite = null))
                : null,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _fechaLimite = d);
            },
          ),
          const SizedBox(height: 16),

          // Etiquetas
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _etiquetaCtrl,
                  decoration: const InputDecoration(labelText: 'Etiqueta', hintText: 'ej: urgente'),
                  onSubmitted: _addEtiqueta,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: ECDBColors.wine),
                onPressed: () => _addEtiqueta(_etiquetaCtrl.text),
              ),
            ],
          ),
          if (_etiquetas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _etiquetas.map((e) => Chip(
                label: Text(e),
                onDeleted: () => setState(() => _etiquetas.remove(e)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 32),
          ECDBButton(
            label: 'Crear Tarea',
            isExpanded: true,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  void _addEtiqueta(String text) {
    final tag = text.trim().toLowerCase();
    if (tag.isNotEmpty && !_etiquetas.contains(tag)) {
      setState(() {
        _etiquetas.add(tag);
        _etiquetaCtrl.clear();
      });
    }
  }
}
