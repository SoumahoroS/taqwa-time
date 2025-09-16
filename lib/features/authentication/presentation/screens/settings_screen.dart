import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Settings values
  bool _darkMode = false;
  bool _notifications = true;
  bool _vibration = true;
  bool _autoLocation = true;
  String _selectedLanguage = 'Francais';
  String _calculationMethod = 'MWL';
  double _notificationVolume = 0.8;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                      _buildNotificationSettings(),
                      const SizedBox(height: 16),
                      _buildPrayerSettings(),
                      const SizedBox(height: 16),
                      _buildAppearanceSettings(),
                      const SizedBox(height: 16),
                      _buildLanguageSettings(),
                      const SizedBox(height: 16),
                      _buildSupportSettings(),
                      const SizedBox(height: 16),
                      _buildAboutSettings(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Parametres',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 40,
                right: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.15),
                  ),
                ),
              ),
              const Positioned(
                bottom: 40,
                right: 20,
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Utilisateur TaqwaTime',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compte premium actif',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PRO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications_active,
      children: [
        _buildAnimatedSwitch(
          title: 'Rappels de priere',
          subtitle: 'Recevoir des notifications pour chaque priere',
          icon: Icons.notification_important,
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
        ),
        _buildAnimatedSwitch(
          title: 'Vibration',
          subtitle: 'Vibrer lors des notifications',
          icon: Icons.vibration,
          value: _vibration,
          onChanged: (value) => setState(() => _vibration = value),
        ),
        _buildVolumeSlider(),
      ],
    );
  }

  Widget _buildPrayerSettings() {
    return _buildSettingsCard(
      title: 'Parametres de priere',
      icon: Icons.mosque,
      children: [
        _buildAnimatedSwitch(
          title: 'Localisation automatique',
          subtitle: 'Detecter automatiquement votre position',
          icon: Icons.location_on,
          value: _autoLocation,
          onChanged: (value) => setState(() => _autoLocation = value),
        ),
        _buildDropdownTile(
          title: 'Methode de calcul',
          subtitle: 'Choisir la methode de calcul des horaires',
          icon: Icons.calculate,
          value: _calculationMethod,
          items: const [
            {'value': 'MWL', 'label': 'Muslim World League'},
            {'value': 'ISNA', 'label': 'Islamic Society of North America'},
            {'value': 'EGYPT', 'label': 'Egyptian General Authority'},
            {'value': 'MAKKAH', 'label': 'Umm Al-Qura University'},
          ],
          onChanged: (value) => setState(() => _calculationMethod = value),
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSettingsCard(
      title: 'Apparence',
      icon: Icons.palette,
      children: [
        _buildAnimatedSwitch(
          title: 'Mode sombre',
          subtitle: 'Activer le theme sombre',
          icon: Icons.dark_mode,
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
        ),
        _buildActionTile(
          title: 'Personnaliser le theme',
          subtitle: 'Choisir couleurs et polices',
          icon: Icons.color_lens,
          onTap: () => _showComingSoonDialog('Personnalisation du theme'),
        ),
      ],
    );
  }

  Widget _buildLanguageSettings() {
    return _buildSettingsCard(
      title: 'Langue et region',
      icon: Icons.language,
      children: [
        _buildDropdownTile(
          title: 'Langue de l\'application',
          subtitle: 'Changer la langue d\'affichage',
          icon: Icons.translate,
          value: _selectedLanguage,
          items: const [
            {'value': 'Francais', 'label': 'Francais'},
            {'value': 'العربية', 'label': 'العربية'},
            {'value': 'English', 'label': 'English'},
            {'value': 'Espanol', 'label': 'Espanol'},
          ],
          onChanged: (value) => setState(() => _selectedLanguage = value),
        ),
      ],
    );
  }

  Widget _buildSupportSettings() {
    return _buildSettingsCard(
      title: 'Support',
      icon: Icons.help_outline,
      children: [
        _buildActionTile(
          title: 'Centre d\'aide',
          subtitle: 'FAQ et guides d\'utilisation',
          icon: Icons.help,
          onTap: () => Navigator.pushNamed(context, AppRoutes.help),
        ),
        _buildActionTile(
          title: 'Contacter le support',
          subtitle: 'Envoyer un message au support',
          icon: Icons.contact_support,
          onTap: () => _showComingSoonDialog('Contact support'),
        ),
        _buildActionTile(
          title: 'Evaluer l\'application',
          subtitle: 'Laisser un avis sur le store',
          icon: Icons.star_rate,
          onTap: () => _showComingSoonDialog('Evaluation'),
        ),
      ],
    );
  }

  Widget _buildAboutSettings() {
    return _buildSettingsCard(
      title: 'A propos',
      icon: Icons.info_outline,
      children: [
        _buildInfoTile('Version', '1.0.0'),
        _buildInfoTile('Derniere mise a jour', '15 Sept 2025'),
        _buildActionTile(
          title: 'Conditions d\'utilisation',
          subtitle: 'Consulter les CGU',
          icon: Icons.description,
          onTap: () => _showComingSoonDialog('CGU'),
        ),
        _buildActionTile(
          title: 'Politique de confidentialite',
          subtitle: 'Comment nous protegeons vos donnees',
          icon: Icons.privacy_tip,
          onTap: () => _showComingSoonDialog('Politique de confidentialite'),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (value ? AppColors.primary : Colors.grey).withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primary : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(
                    item['label']!,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  HapticFeedback.selectionClick();
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up, color: AppColors.primary, size: 20),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Volume des notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              Text(
                '${(_notificationVolume * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _notificationVolume,
              onChanged: (value) {
                setState(() => _notificationVolume = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.construction, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('Bientot disponible'),
          ],
        ),
        content: Text(
          '$feature sera disponible dans une prochaine mise a jour.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Compris',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}