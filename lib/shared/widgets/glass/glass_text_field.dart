import 'dart:ui';
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_tokens.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? AppColors.darkGlassTint : Colors.white.withValues(alpha: 0.15);
    final border = isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final hintColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusMD),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTokens.glassLightBlur, sigmaY: AppTokens.glassLightBlur),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: TextStyle(color: textColor, fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            labelStyle: TextStyle(color: hintColor),
            hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.6)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.primary, size: 22)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: tint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingMD,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMD),
              borderSide: BorderSide(color: border, width: AppTokens.glassBorderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMD),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMD),
              borderSide: const BorderSide(color: AppColors.alert, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMD),
              borderSide: const BorderSide(color: AppColors.alert, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
