import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../routes.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';

class SettingsSupportScreen extends StatelessWidget {
  const SettingsSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  _sectionLabel('Aide'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _buildTile(
                          context,
                          icon: Icons.help_rounded,
                          iconColor: const Color(0xFF1ABC9C),
                          title: 'Centre d\'aide',
                          subtitle: 'FAQ et guides d\'utilisation',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.help),
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08), indent: 68, endIndent: 16),
                        _buildTile(
                          context,
                          icon: Icons.contact_support_rounded,
                          iconColor: const Color(0xFF5B8AF7),
                          title: 'Contacter le support',
                          subtitle: 'Envoyer un message à notre équipe',
                          onTap: () => _comingSoon(context, 'Contact support'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingMD),
                  _sectionLabel('Communauté'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _buildTile(
                          context,
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFE77C40),
                          title: 'Évaluer TaqwaTime',
                          subtitle: 'Laisser un avis sur le store',
                          onTap: () => _comingSoon(context, 'Évaluation'),
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08), indent: 68, endIndent: 16),
                        _buildTile(
                          context,
                          icon: Icons.share_rounded,
                          iconColor: const Color(0xFF9B59B6),
                          title: 'Partager l\'application',
                          subtitle: 'Recommander TaqwaTime à vos proches',
                          onTap: () => _comingSoon(context, 'Partage'),
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08), indent: 68, endIndent: 16),
                        _buildTile(
                          context,
                          icon: Icons.bug_report_rounded,
                          iconColor: const Color(0xFFE74C3C),
                          title: 'Signaler un problème',
                          subtitle: 'Nous aider à améliorer l\'application',
                          onTap: () => _comingSoon(context, 'Signalement'),
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

  Widget _buildTile(
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
