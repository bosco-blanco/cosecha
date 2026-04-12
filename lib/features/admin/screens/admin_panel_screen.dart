import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../widgets/qr_generator.dart';

/// Panel de administración — gestión de QR, empleados, informes.
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleado = ref.watch(currentEmpleadoProvider);
    if (empleado?.isAdmin != true) {
      return Scaffold(
        appBar: const ECDBAppBar(title: 'Admin'),
        body: const Center(child: Text('Acceso denegado')),
      );
    }

    return Scaffold(
      appBar: const ECDBAppBar(title: 'Panel de Administración'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            icon: Icons.qr_code,
            label: 'Generar QR por ubicación',
            subtitle: 'Códigos QR para fichaje en cada local',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const QrGeneratorSheet(),
              );
            },
          ),
          _AdminTile(
            icon: Icons.people,
            label: 'Gestionar empleados',
            subtitle: 'Alta, baja, cambiar roles',
            onTap: () {},
          ),
          _AdminTile(
            icon: Icons.location_on,
            label: 'Gestionar ubicaciones',
            subtitle: 'Coordenadas, radios, activar/desactivar',
            onTap: () {},
          ),
          _AdminTile(
            icon: Icons.assessment,
            label: 'Informes y exportación',
            subtitle: 'CSV para inspección laboral',
            onTap: () => context.push('/fichaje/control'),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ECDBCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ECDBColors.wine.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ECDBColors.wine),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: ECDBColors.textMuted),
        ],
      ),
    );
  }
}
