import 'package:flutter/material.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';

/// Tablero Kanban — placeholder Sprint 3.
class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Tracker'),
      body: const ECDBEmptyState(
        icon: Icons.view_kanban_outlined,
        title: 'Tablero de tareas',
        description: 'Aquí verás tus tareas organizadas en columnas.\nDisponible en Sprint 3.',
        ctaLabel: 'Nueva Tarea',
      ),
    );
  }
}
