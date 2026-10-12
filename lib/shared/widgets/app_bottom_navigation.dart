import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// The app's bottom bar: Home, Tasks, Create (raised "+" button), Community,
/// and Profile.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  static const createIndex = 2;

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x140F1C2E),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        // The Create button has its own look; never draw the pill behind it.
        indicatorColor: selectedIndex == createIndex
            ? Colors.transparent
            : null,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_box_outlined),
            selectedIcon: const Icon(Icons.check_box_rounded),
            label: l10n.navTasks,
          ),
          NavigationDestination(
            icon: const _CreateButton(),
            label: l10n.navCreate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: l10n.navCommunity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

/// Navy "+" circle that sits slightly above the other icons.
class _CreateButton extends StatelessWidget {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    // Takes the same layout space as a normal 24px icon so the "Create" label
    // lines up with the others, but paints a larger raised circle.
    return SizedBox.square(
      dimension: 24,
      child: OverflowBox(
        maxWidth: 52,
        maxHeight: 52,
        child: Transform.translate(
          offset: const Offset(0, -10),
          child: _circle(),
        ),
      ),
    );
  }

  Widget _circle() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }
}
