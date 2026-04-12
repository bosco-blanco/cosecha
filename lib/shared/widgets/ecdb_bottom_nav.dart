import 'package:flutter/material.dart';
import '../../core/theme/ecdb_colors.dart';

/// Navegación inferior ECDB — 5 tabs con FAB central.
/// Tabs: Inicio, Tracker, + (FAB), Agenda, Más
class ECDBBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;

  const ECDBBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Barra de navegación
        Container(
          decoration: BoxDecoration(
            color: ECDBColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Inicio',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.track_changes_outlined,
                    activeIcon: Icons.track_changes,
                    label: 'Tracker',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  // Espacio para el FAB
                  const SizedBox(width: 56),
                  _NavItem(
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    label: 'Agenda',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.more_horiz_outlined,
                    activeIcon: Icons.more_horiz,
                    label: 'Más',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
        // FAB central (+)
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          child: GestureDetector(
            onTap: onFabPressed,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ECDBColors.gold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ECDBColors.gold.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: ECDBColors.textPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? ECDBColors.wine : ECDBColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? ECDBColors.wine : ECDBColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
