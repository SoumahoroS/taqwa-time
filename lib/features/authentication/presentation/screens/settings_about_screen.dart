import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';

class SettingsAboutScreen extends StatelessWidget {
  const SettingsAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('À propos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  // App identity card
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    tintColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'TaqwaTime',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Votre compagnon de prière quotidien',
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.65)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            'Version 1.0.0',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingMD),
                  _sectionLabel('Informations'),
                  GlassCard(
                    padding: const EdgeInsets.all(AppTokens.spacingMD),
                    child: Column(
                      children: [
                        _buildInfoRow('Version', '1.0.0'),
                        _divider(),
                        _buildInfoRow('Dernière mise à jour', '15 Sept 2025'),
                        _divider(),
                        _buildInfoRow('Plateforme', 'Android & iOS'),
                        _divider(),
                        _buildInfoRow('Développeur', 'Équipe TaqwaTime'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingMD),
                  _sectionLabel('Légal'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _buildLegalTile(
                          context,
                          icon: Icons.description_rounded,
                          iconColor: const Color(0xFF5B8AF7),
                          title: 'Conditions d\'utilisation',
                          subtitle: 'Consulter les CGU',
                          onTap: () => _comingSoon(context, 'CGU'),
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08), indent: 68, endIndent: 16),
                        _buildLegalTile(
                          context,
                          icon: Icons.privacy_tip_rounded,
                          iconColor: const Color(0xFF4CAF7D),
                          title: 'Politique de confidentialité',
                          subtitle: 'Comment nous protégeons vos données',
                          onTap: () => _comingSoon(context, 'Politique de confidentialité'),
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08), indent: 68, endIndent: 16),
                        _buildLegalTile(
                          context,
                          icon: Icons.code_rounded,
                          iconColor: const Color(0xFF95A5A6),
                          title: 'Licences open source',
                          subtitle: 'Bibliothèques et licences tierces',
                          onTap: () => showLicensePage(context: context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingMD),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '© 2025 TaqwaTime — Fait avec ❤️ pour la Oumma',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
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

  Widget _divider() => Divider(height: 16, color: Colors.white.withValues(alpha: 0.1));

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLegalTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: iconColor.withValues(alpha: 0.18),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMD)),
        title: const Row(
          children: [
            Icon(Icons.construction_rounded, color: AppColors.accentLight),
            SizedBox(width: 8),
            Text('Bientôt disponible', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '$feature sera disponible dans une prochaine mise à jour.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }
}
