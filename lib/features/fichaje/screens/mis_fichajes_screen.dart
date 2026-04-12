import 'package:flutter/material.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';

/// Mis Fichajes — historial personal con calendario visual.
/// Placeholder para Sprint 2.
class MisFichajesScreen extends StatelessWidget {
  const MisFichajesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Mis Fichajes'),
      body: const ECDBEmptyState(
        icon: Icons.history,
        title: 'Historial de fichajes',
        description: 'Aquí verás tu historial de entradas y salidas con un calendario visual.\nDisponible en Sprint 2.',
      ),
    );
  }
}
