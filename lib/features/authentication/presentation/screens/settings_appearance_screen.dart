import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';

class SettingsAppearanceScreen extends StatelessWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Apparence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Thème'),
                  GlassCard(
                    padding: const EdgeInsets.all(AppTokens.spacingMD),
                    child: Column(
                      children: [
                        _buildThemeTile(
                          context,
                          icon: Icons.light_mode_rounded,
                          title: 'Clair',
                          subtitle: 'Fond lumineux',
                          selected: !isDark,
                          onTap: () => themeService.setThemeMode(ThemeMode.light),
                        ),
                        Divider(height: 20, color: Colors.white.withValues(alpha: 0.1)),
                        _buildThemeTile(
                          context,
                          icon: Icons.dark_mode_rounded,
                          title: 'Sombre',
                          subtitle: 'Fond sombre (recommandé)',
                          selected: isDark,
                          onTap: () => themeService.setThemeMode(ThemeMode.dark),
                        ),
                        Divider(height: 20, color: Colors.white.withValues(alpha: 0.1)),
                        _buildThemeTile(
                          context,
                          icon: Icons.brightness_auto_rounded,
                          title: 'Automatique',
                          subtitle: 'Suit les paramètres du système',
                          selected: themeService.themeMode == ThemeMode.system,
                          onTap: () => themeService.setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingMD),
                  _sectionLabel('Personnalisation'),
                  GlassCard(
                    padding: const EdgeInsets.all(AppTokens.spacingMD),
                    child: _buildComingSoon(
                      icon: Icons.color_lens_rounded,
                      title: 'Couleurs et polices',
                      subtitle: 'Personnaliser l\'apparence de l\'application',
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.white.withValues(alpha: 0.55)),
    ),
  );

  Widget _buildThemeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusSM),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (selected ? AppColors.primary : Colors.white).withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: selected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.55), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
              ],
            ),
          ),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.3),
                width: selected ? 2 : 1.5,
              ),
              color: selected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryLight)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.45), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.55))),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Bientôt', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
