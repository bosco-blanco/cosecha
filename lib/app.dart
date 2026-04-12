import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/ecdb_theme.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/tareas/screens/kanban_screen.dart';
import 'features/agenda/screens/agenda_screen.dart';
import 'features/portal/screens/portal_screen.dart';
import 'features/crm/screens/pipeline_screen.dart';
import 'shared/widgets/ecdb_bottom_nav.dart';
import 'shared/widgets/ecdb_toast.dart';
import 'core/theme/ecdb_colors.dart';

/// Clave del navigator para el shell.
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
                  icon: Icons.access_time,
                  label: 'Fichar',
                  color: ECDBColors.success,
                  onTap: () {
                    Navigator.pop(context);
                    ECDBToast.show(
                      context,
                      message: 'Fichaje disponible en Sprint 2',
                      type: ToastType.info,
                    );
                  },
                ),
                _QuickActionTile(
                  icon: Icons.add_task,
                  label: 'Nueva Tarea',
                  color: ECDBColors.wine,
                  onTap: () {
                    Navigator.pop(context);
                    ECDBToast.show(
                      context,
                      message: 'Tareas disponibles en Sprint 3',
                      type: ToastType.info,
                    );
                  },
                ),
                _QuickActionTile(
                  icon: Icons.person_add,
                  label: 'Nuevo Contacto',
                  color: ECDBColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    ECDBToast.show(
                      context,
                      message: 'CRM disponible en Sprint 4',
                      type: ToastType.info,
                    );
                  },
                ),
                _QuickActionTile(
                  icon: Icons.help_outline,
                  label: 'Nueva Solicitud',
                  color: ECDBColors.gold,
                  onTap: () {
                    Navigator.pop(context);
                    ECDBToast.show(
                      context,
                      message: 'Portal disponible en Sprint 5',
                      type: ToastType.info,
                    );
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
