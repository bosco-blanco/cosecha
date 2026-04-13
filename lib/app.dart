import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/ecdb_theme.dart';
import 'core/theme/ecdb_colors.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/qr_clock_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/tareas/screens/kanban_screen.dart';
import 'features/agenda/screens/agenda_screen.dart';
import 'features/portal/screens/portal_screen.dart';
import 'features/crm/screens/pipeline_screen.dart';
import 'features/fichaje/screens/mis_fichajes_screen.dart';
import 'features/fichaje/screens/control_horario_screen.dart';
import 'features/fichaje/screens/fichaje_detalle_screen.dart';
import 'features/fichaje/screens/kiosk_screen.dart';
import 'features/tareas/screens/crear_tarea_screen.dart';
import 'features/tareas/screens/tarea_detalle_screen.dart';
import 'features/crm/screens/contactos_screen.dart';
import 'features/portal/screens/solicitudes_screen.dart';
import 'features/portal/screens/ofertas_empleo_screen.dart';
import 'features/portal/screens/referidos_screen.dart';
import 'features/admin/screens/admin_panel_screen.dart';
import 'features/admin/screens/empleados_admin_screen.dart';
import 'core/models/fichaje.dart';
import 'core/models/tarea.dart';
import 'shared/widgets/ecdb_bottom_nav.dart';
import 'shared/widgets/ecdb_toast.dart';

/// Claves del navigator.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider con redirección basada en auth.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isKiosk = state.matchedLocation.startsWith('/kiosk/');

      // Kiosk mode no requiere login (es pantalla pública en el local)
      if (isKiosk) return null;
      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/';
      return null;
    },
    routes: [
      // Login — fuera del shell (sin bottom nav)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Modo Kiosco — se abre al escanear QR del local
      // URL: /kiosk/{ubicacionId}
      GoRoute(
        path: '/kiosk/:ubicacionId',
        builder: (context, state) {
          final ubicacionId = state.pathParameters['ubicacionId']!;
          return KioskScreen(ubicacionId: ubicacionId);
        },
      ),

      // Fichaje QR — fuera del shell (pantalla completa con cámara)
      GoRoute(
        path: '/fichaje/qr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QrClockScreen(),
      ),

      // Fichaje historial
      GoRoute(
        path: '/fichaje/historial',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MisFichajesScreen(),
      ),

      // Control horario (manager)
      GoRoute(
        path: '/fichaje/control',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ControlHorarioScreen(),
      ),

      // Detalle de fichaje
      GoRoute(
        path: '/fichaje/detalle',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final fichaje = state.extra as Fichaje;
          return FichajeDetalleScreen(fichaje: fichaje);
        },
      ),

      // Tareas
      GoRoute(
        path: '/tareas/crear',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CrearTareaScreen(),
      ),
      GoRoute(
        path: '/tareas/detalle',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final tarea = state.extra as Tarea;
          return TareaDetalleScreen(tarea: tarea);
        },
      ),

      // CRM
      GoRoute(
        path: '/crm/contactos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContactosScreen(),
      ),

      // Portal del Empleado
      GoRoute(
        path: '/portal/solicitudes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SolicitudesScreen(),
      ),
      GoRoute(
        path: '/portal/ofertas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OfertasEmpleoScreen(),
      ),
      GoRoute(
        path: '/portal/referidos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReferidosScreen(),
      ),

      // Admin panel
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/admin/empleados',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmpleadosAdminScreen(),
      ),

      // Shell con bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/tracker',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: KanbanScreen(),
            ),
          ),
          GoRoute(
            path: '/agenda',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AgendaScreen(),
            ),
          ),
          GoRoute(
            path: '/mas',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PortalScreen(),
            ),
          ),
          GoRoute(
            path: '/crm',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PipelineScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// App principal con tema ECDB.
class CosechaApp extends ConsumerWidget {
  const CosechaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cosecha',
      debugShowCheckedModeBanner: false,
      theme: ECDBTheme.light,
      routerConfig: router,
      locale: const Locale('es', 'ES'),
    );
  }
}

/// Scaffold con bottom navigation — envuelve las rutas del shell.
class ScaffoldWithNav extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends ConsumerState<ScaffoldWithNav> {
  int _currentIndex = 0;

  static const _routes = ['/', '/tracker', '/agenda', '/mas'];

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      context.go(_routes[index]);
    }
  }

  void _onFabPressed() {
    _showQuickActions(context);
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuickActionTile(
                  icon: Icons.fingerprint,
                  label: 'Fichar',
                  color: ECDBColors.success,
                  onTap: () {
                    Navigator.pop(context);
                    // El fichaje se hace desde el dashboard (ClockWidget)
                  },
                ),
                _QuickActionTile(
                  icon: Icons.qr_code_scanner,
                  label: 'Fichar con QR',
                  color: ECDBColors.wine,
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/fichaje/qr');
                  },
                ),
                _QuickActionTile(
                  icon: Icons.add_task,
                  label: 'Nueva Tarea',
                  color: ECDBColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/tareas/crear');
                  },
                ),
                _QuickActionTile(
                  icon: Icons.person_add,
                  label: 'Nuevo Contacto',
                  color: ECDBColors.gold,
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/crm/contactos');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: ECDBBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onFabPressed: _onFabPressed,
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: ECDBColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
      ),
      onTap: onTap,
    );
  }
}
