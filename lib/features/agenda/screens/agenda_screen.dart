import 'package:flutter/material.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';

/// Agenda / Calendario — placeholder.
class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Agenda'),
      body: const ECDBEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Tu agenda',
        description: 'Calendario y reuniones.\nDisponible próximamente.',
      ),
    );
  }
}
