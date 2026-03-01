import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_tokens.dart';

enum GlassButtonVariant { primary, secondary, danger }

class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppTokens.animFast),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color _getFillColor() {
    switch (widget.variant) {
      case GlassButtonVariant.primary:
        return AppColors.primary.withValues(alpha: 0.85);
      case GlassButtonVariant.secondary:
        return Colors.white.withValues(alpha: 0.12);
      case GlassButtonVariant.danger:
        return AppColors.alert.withValues(alpha: 0.85);
    }
  }

  Color _getTextColor() {
    switch (widget.variant) {
      case GlassButtonVariant.primary:
      case GlassButtonVariant.danger:
        return Colors.white;
      case GlassButtonVariant.secondary:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.primary;
    }
  }

  Color _getBorderColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.variant) {
      case GlassButtonVariant.primary:
        return AppColors.primaryLight.withValues(alpha: 0.4);
      case GlassButtonVariant.secondary:
        return isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;
      case GlassButtonVariant.danger:
        return AppColors.alertLight.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          HapticFeedback.lightImpact();
          widget.onPressed?.call();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusMD),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: AppTokens.glassLightBlur, sigmaY: AppTokens.glassLightBlur),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: _getFillColor(),
                borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                border: Border.all(
                  color: _getBorderColor(),
                  width: AppTokens.glassBorderWidth,
                ),
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _getTextColor(),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: _getTextColor(), size: 20),
                            const SizedBox(width: AppTokens.spacingSM),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
