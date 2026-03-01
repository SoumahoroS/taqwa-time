import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_tokens.dart';

class GlassBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const GlassBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassBottomNavItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark
        ? AppColors.darkGlassTint
        : Colors.white.withValues(alpha: 0.7);
    final border = isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTokens.glassBlurSigma, sigmaY: AppTokens.glassBlurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(
              top: BorderSide(color: border, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = index == currentIndex;
                  return _NavItem(
                    item: item,
                    isActive: isActive,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(index);
                    },
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final GlassBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: AppTokens.animNormal),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
              ),
              child: Icon(
                isActive ? (item.activeIcon ?? item.icon) : item.icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
