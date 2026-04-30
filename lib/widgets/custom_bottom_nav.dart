import 'package:flutter/material.dart';

// Model untuk item navigasi
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final Function(int) onTap;
  final Color primaryColor;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.primaryColor = const Color(0xFF4E73DF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(
              items.length,
              (i) => Expanded(
                child: _NavTile(
                  index: i,
                  item: items[i],
                  isActive: currentIndex == i,
                  onTap: () => onTap(i),
                  primaryColor: primaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final int index;
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Color primaryColor;

  const _NavTile({
    required this.index,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: isActive ? primaryColor : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? primaryColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
