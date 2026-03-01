import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';

class GradientMeshBackground extends StatelessWidget {
  final bool useUrgentColors;

  const GradientMeshBackground({
    super.key,
    this.useUrgentColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = useUrgentColors
        ? [
            AppColors.alert,
            AppColors.alert.withValues(alpha: 0.8),
            AppColors.secondary,
            AppColors.primaryDark,
          ]
        : isDark
            ? AppColors.darkMeshGradient
            : AppColors.lightMeshGradient;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors[0], colors[1]],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: _blurredCircle(220, colors[2].withValues(alpha: 0.3)),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: _blurredCircle(200, colors[3].withValues(alpha: 0.25)),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              right: 30,
              child: _blurredCircle(140, colors[0].withValues(alpha: 0.15)),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: -40,
              child: _blurredCircle(100, colors[2].withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurredCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
