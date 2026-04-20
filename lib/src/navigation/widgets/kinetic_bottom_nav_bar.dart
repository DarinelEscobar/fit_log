import 'package:flutter/material.dart';
import '../../theme/kinetic_noir.dart';

class KineticBottomNavItem {
  const KineticBottomNavItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class KineticBottomNavBar extends StatelessWidget {
  const KineticBottomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
    super.key,
  });

  final int selectedIndex;
  final List<KineticBottomNavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: KineticNoirSpacing.floatingNav,
        child: Container(
          decoration: kineticFloatingNavDecoration,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _NavButton(
                    item: items[index],
                    isSelected: selectedIndex == index,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final KineticBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? KineticNoirPalette.primary
        : KineticNoirPalette.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? KineticNoirPalette.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: foregroundColor, size: 22),
                const SizedBox(height: 6),
                Text(
                  item.label.toUpperCase(),
                  style: KineticNoirTypography.body(
                    size: 10,
                    weight: FontWeight.w800,
                    color: foregroundColor,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
