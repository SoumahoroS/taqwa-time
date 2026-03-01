import 'package:flutter/material.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () => _fadeController.forward());
    Future.delayed(const Duration(milliseconds: 400), () => _slideController.forward());
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Centre d\'aide',
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTokens.spacingMD),
                  child: Column(
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: AppTokens.spacingLG),
                      _buildQuickActions(),
                      const SizedBox(height: AppTokens.spacingLG),
                      _buildFAQSection(),
                      const SizedBox(height: AppTokens.spacingLG),
                      _buildContactSection(),
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

  Widget _buildWelcomeCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.mosque, color: Colors.white, size: 40),
          ),
          const SizedBox(height: AppTokens.spacingMD),
          const Text(
            'Bienvenue dans TaqwaTime',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.spacingSM),
          Text(
            'Votre compagnon spirituel pour un rappel efficace et persistant de vos obligations religieuses',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'title': 'Configurer les notifications', 'description': 'Personnalisez vos rappels de prière', 'icon': Icons.notifications_active, 'color': AppColors.primaryLight, 'action': () => _showFeatureComingSoon('Configuration des notifications')},
      {'title': 'Ajuster la localisation', 'description': 'Définissez votre position géographique', 'icon': Icons.location_on, 'color': AppColors.accentLight, 'action': () => _showFeatureComingSoon('Réglages de localisation')},
      {'title': 'Horaires de prière', 'description': 'Consultez les horaires du jour', 'icon': Icons.schedule, 'color': Colors.white, 'action': () => _showFeatureComingSoon('Horaires de prière')},
      {'title': 'Statistiques', 'description': 'Suivez votre assiduité religieuse', 'icon': Icons.analytics, 'color': AppColors.alertLight, 'action': () => _showFeatureComingSoon('Statistiques')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: AppTokens.spacingMD),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              title: action['title'] as String,
              description: action['description'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: action['action'] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title, required String description,
    required IconData icon, required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppTokens.spacingMD),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.2)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppTokens.spacingSM),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(description, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {'question': 'Comment configurer mes premières notifications ?', 'answer': 'Allez dans Paramètres > Notifications pour personnaliser vos rappels de prière selon vos préférences.'},
      {'question': 'Pourquoi les horaires de prière ne correspondent pas ?', 'answer': 'Vérifiez que votre localisation est correctement configurée dans Paramètres > Localisation.'},
      {'question': 'Comment modifier ma méthode de calcul ?', 'answer': 'Dans Paramètres > Calculs, vous pouvez choisir entre différentes méthodes de calcul des horaires.'},
      {'question': 'Puis-je utiliser l\'app sans connexion internet ?', 'answer': 'Oui, une fois configurée, l\'application fonctionne entièrement hors ligne.'},
      {'question': 'Comment sauvegarder mes données ?', 'answer': 'Connectez-vous avec votre compte Google pour synchroniser automatiquement vos données.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Questions fréquentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: AppTokens.spacingMD),
        ...faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          return _buildFAQItem(question: faq['question']!, answer: faq['answer']!, index: index);
        }),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer, required int index}) {
    final isExpanded = _expandedIndex == index;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            leading: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.2)),
              child: const Icon(Icons.help_outline, color: AppColors.primaryLight, size: 18),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryLight),
            ),
            onExpansionChanged: (expanded) {
              setState(() => _expandedIndex = expanded ? index : null);
            },
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(answer, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      tintColor: AppColors.primary.withValues(alpha: 0.1),
      child: Column(
        children: [
          const Icon(Icons.support_agent, color: AppColors.primaryLight, size: 48),
          const SizedBox(height: AppTokens.spacingMD),
          const Text(
            'Besoin d\'aide supplémentaire ?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: AppTokens.spacingSM),
          Text(
            'Notre équipe est là pour vous accompagner dans votre parcours spirituel',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.spacingLG),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  onPressed: () => _showFeatureComingSoon('Contact par email'),
                  variant: GlassButtonVariant.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassButton(
                  label: 'Chat',
                  icon: Icons.chat_outlined,
                  onPressed: () => _showFeatureComingSoon('Chat en direct'),
                  variant: GlassButtonVariant.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeatureComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMD)),
        title: const Row(
          children: [
            Icon(Icons.construction, color: AppColors.accentLight),
            SizedBox(width: 8),
            Text('Bientôt disponible', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '$feature sera disponible dans une prochaine mise à jour.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }
}
