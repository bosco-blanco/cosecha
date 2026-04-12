import 'package:flutter/material.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';

/// Control Horario — vista de manager con tabla de empleados.
/// Placeholder para Sprint 2.
class ControlHorarioScreen extends StatelessWidget {
  const ControlHorarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Control Horario'),
      body: const ECDBEmptyState(
        icon: Icons.supervisor_account,
        title: 'Control horario del equipo',
        description: 'Vista para managers: tabla de empleados, filtros y exportar CSV.\nDisponible en Sprint 2.',
      ),
    );
  }
}
