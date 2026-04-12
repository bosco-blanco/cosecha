import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';

/// Portal del empleado — hub de opciones "Más".
class PortalScreen extends ConsumerWidget {
  const PortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleado = ref.watch(currentEmpleadoProvider);

    return Scaffold(
      appBar: const ECDBAppBar(title: 'Más'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Perfil del empleado
          ECDBCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ECDBColors.wine,
                  child: Text(
                    empleado?.nombre.isNotEmpty == true
                        ? empleado!.nombre[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empleado?.nombre ?? 'Usuario',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        empleado?.rol.name.toUpperCase() ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ECDBColors.wine,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: ECDBColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Secciones
          _SectionHeader(title: 'Fichaje'),
          _MenuTile(
            icon: Icons.access_time,
            label: 'Mis Fichajes',
            subtitle: 'Historial y calendario',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'CRM'),
          _MenuTile(
            icon: Icons.people_outline,
            label: 'Contactos',
            subtitle: 'Gestión de contactos',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.trending_up,
            label: 'Pipeline',
            subtitle: 'Oportunidades comerciales',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Portal del Empleado'),
          _MenuTile(
            icon: Icons.help_outline,
            label: 'Solicitudes',
            subtitle: 'IT, RRHH, Mantenimiento',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.work_outline,
            label: 'Bolsa de Empleo',
            subtitle: 'Ofertas internas ECDB',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.group_add_outlined,
            label: 'Referidos',
            subtitle: 'Programa de referidos',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.folder_outlined,
            label: 'Documentos',
            subtitle: 'Nóminas, contratos, políticas',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Cuenta'),
          _MenuTile(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            color: ECDBColors.error,
            onTap: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ECDBColors.textMuted,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ECDBCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? ECDBColors.wine, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: color ?? ECDBColors.textPrimary,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (color == null) const Icon(Icons.chevron_right, color: ECDBColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
