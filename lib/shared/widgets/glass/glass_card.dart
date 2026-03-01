import 'dart:ui';
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final bool hasShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppTokens.radiusLG,
    this.blurSigma = AppTokens.glassBlurSigma,
    this.tintColor,
    this.borderColor,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = tintColor ?? (isDark ? AppColors.darkGlassTint : AppColors.lightGlassTint);
    final border = borderColor ?? (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder);
    final shadow = isDark ? AppColors.darkGlassShadow : AppColors.lightGlassShadow;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: AppTokens.glassBorderWidth),
              boxShadow: hasShadow
                  ? [
                      BoxShadow(
                        color: shadow,
                        blurRadius: AppTokens.shadowBlurMD,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
