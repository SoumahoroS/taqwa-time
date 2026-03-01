import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/themes/app_tokens.dart';
import '../glass/glass_card.dart';
import '../glass/gradient_mesh_background.dart';

class TaqwaTimeDrawer extends StatelessWidget {
  final UserModel? currentUser;

  const TaqwaTimeDrawer({
    super.key,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingMD),
              child: Column(
                children: [
                  // Header
                  GlassCard(
                    padding: const EdgeInsets.all(AppTokens.spacingLG),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            radius: 35,
                            child: Icon(
                              authService.currentUser == null
                                  ? Icons.person_outline
                                  : Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.spacingSM),
                        Text(
                          authService.currentUser == null
                              ? 'Invité'
                              : currentUser?.name ?? 'Utilisateur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService.currentUser == null
                              ? 'Non connecté'
                              : currentUser?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (authService.currentUser != null) ...[
                          const SizedBox(height: AppTokens.spacingSM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              '🕌 Connecté',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTokens.spacingLG),

                  // Menu items
                  _buildMenuItem(
                    context,
                    Icons.person_outline,
                    'Profil',
                    () {
                      Navigator.pop(context);
                      _navigateToProfile(context, authService);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.help_outline,
                    'Aide',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/help');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.settings_outlined,
                    'Paramètres',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),

                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingMD,
                      vertical: AppTokens.spacingMD,
                    ),
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),

                  if (authService.currentUser == null)
                    _buildMenuItem(
                      context,
                      Icons.login_outlined,
                      'Se connecter',
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      isAction: true,
                    )
                  else
                    _buildMenuItem(
                      context,
                      Icons.logout_outlined,
                      'Se déconnecter',
                      () async {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      isAction: true,
                      isDangerous: true,
                    ),

                  const Spacer(),

                  // App version
                  Text(
                    'TaqwaTime v1.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingSM),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isAction = false,
    bool isDangerous = false,
  }) {
    final itemColor = isDangerous
        ? AppColors.alertLight
        : isAction
            ? AppColors.primaryLight
            : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacingXS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusMD),
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingMD,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusMD),
              color: isDangerous
                  ? AppColors.alert.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: itemColor, size: 20),
                ),
                const SizedBox(width: AppTokens.spacingMD),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: itemColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, AuthService authService) {
    if (authService.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      Navigator.pushNamed(context, '/profile');
    }
  }
}
