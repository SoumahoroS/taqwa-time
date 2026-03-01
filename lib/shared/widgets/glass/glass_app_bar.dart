import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_tokens.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final double height;
  final VoidCallback? onBackPressed;

  const GlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.centerTitle = true,
    this.height = kToolbarHeight + 10,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? AppColors.darkGlassTint : AppColors.lightGlassTint;
    final border = isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;
    final canPop = Navigator.of(context).canPop();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTokens.glassBlurSigma, sigmaY: AppTokens.glassBlurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(
              bottom: BorderSide(color: border, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  if (showBackButton && canPop)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      color: Colors.white,
                      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(width: AppTokens.spacingMD),
                  if (centerTitle) const Spacer(),
                  titleWidget ??
                      Text(
                        title ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                  if (centerTitle) const Spacer(),
                  if (actions != null) ...actions!,
                  if (actions == null && centerTitle)
                    const SizedBox(width: AppTokens.spacing2XL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
