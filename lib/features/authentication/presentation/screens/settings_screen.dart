import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';
import 'settings_notifications_screen.dart';
import 'settings_prayer_screen.dart';
import 'settings_appearance_screen.dart';
import 'settings_language_screen.dart';
import 'settings_support_screen.dart';
import 'settings_about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AuthService _authService;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _authService.currentUser;
    if (user != null && !_authService.isGuestUser) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) setState(() => _currentUser = userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spacingMD, AppTokens.spacingSM,
                AppTokens.spacingMD, 40,
              ),
              child: Column(
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: AppTokens.spacingMD),
                  _buildMenuSection(),
                  const SizedBox(height: AppTokens.spacingMD),
                  _buildLogoutTile(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = _authService.currentUser;
    final isGuest = _authService.isGuestUser;
    final displayName = _currentUser?.name
        ?? user?.displayName
        ?? user?.email?.split('@').first
        ?? 'Utilisateur';
    final email = user?.email ?? '';
    final initial = isGuest ? '?' : (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U');

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      tintColor: AppColors.primary.withValues(alpha: 0.12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? 'Invité' : displayName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isGuest ? 'Mode invité' : email,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isGuest)
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Modifier',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    final items = [
      _MenuItem(
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF5B8AF7),
        title: 'Notifications',
        subtitle: 'Rappels, vibration, volume, intervalles',
        onTap: () => _push(const SettingsNotificationsScreen()),
      ),
      _MenuItem(
        icon: Icons.mosque_rounded,
        color: const Color(0xFF4CAF7D),
        title: 'Prière',
        subtitle: 'Méthode de calcul, madhab, ajustements',
        onTap: () => _push(const SettingsPrayerScreen()),
      ),
      _MenuItem(
        icon: Icons.palette_rounded,
        color: const Color(0xFFE77C40),
        title: 'Apparence',
        subtitle: 'Thème sombre, couleurs',
        onTap: () => _push(const SettingsAppearanceScreen()),
      ),
      _MenuItem(
        icon: Icons.language_rounded,
        color: const Color(0xFF9B59B6),
        title: 'Langue et région',
        subtitle: 'Français, العربية, English, Español',
        onTap: () => _push(const SettingsLanguageScreen()),
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        color: const Color(0xFF1ABC9C),
        title: 'Support',
        subtitle: 'Aide, contact, évaluer l\'application',
        onTap: () => _push(const SettingsSupportScreen()),
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF95A5A6),
        title: 'À propos',
        subtitle: 'Version, conditions, confidentialité',
        onTap: () => _push(const SettingsAboutScreen()),
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildMenuTile(item),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                  indent: 68,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.35), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    final isGuest = _authService.isGuestUser;
    return GlassCard(
      tintColor: AppColors.alert.withValues(alpha: 0.06),
      borderColor: AppColors.alert.withValues(alpha: 0.22),
      child: InkWell(
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A2A3A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMD)),
              title: Text(
                isGuest ? 'Quitter le mode invité' : 'Déconnexion',
                style: const TextStyle(color: Colors.white),
              ),
              content: Text(
                isGuest
                    ? 'Voulez-vous vous connecter ou créer un compte ?'
                    : 'Voulez-vous vous déconnecter ?',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmer', style: TextStyle(color: AppColors.alertLight)),
                ),
              ],
            ),
          );
          if (confirm == true && mounted) {
            await _authService.signOut();
            if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        },
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isGuest ? Icons.login_rounded : Icons.logout_rounded, color: AppColors.alertLight, size: 22),
              const SizedBox(width: 10),
              Text(
                isGuest ? 'Se connecter / Créer un compte' : 'Se déconnecter',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.alertLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
