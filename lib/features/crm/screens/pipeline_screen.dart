import 'package:flutter/material.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';

/// Pipeline CRM Comercial — placeholder Sprint 4.
class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'CRM Comercial'),
      body: const ECDBEmptyState(
        icon: Icons.trending_up,
        title: 'Pipeline comercial',
        description:
            'Gestiona oportunidades CODEBA y Eventos.\nDisponible en Sprint 4.',
      ),
    );
  }
}
