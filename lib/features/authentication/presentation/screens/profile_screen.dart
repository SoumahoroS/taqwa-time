import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthService _authService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      if (_authService.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      final userId = _authService.currentUser!.uid;
      await _authService.getUserData(userId);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(label: 'Réessayer', onPressed: _loadUserData, textColor: Colors.white),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: _isLoading
                ? Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppTokens.spacingLG),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: AppTokens.spacingMD),
                          Text(
                            'Chargement...',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTokens.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppTokens.spacingMD),
                        _buildUserInfoSection(),
                        const SizedBox(height: AppTokens.spacingLG),
                        _buildActionButtons(),
                        const SizedBox(height: AppTokens.spacingLG),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final user = _authService.currentUser;
    final emailPrefix = user?.email?.split('@')[0] ?? 'Utilisateur';
    final userName = user?.displayName ?? emailPrefix;
    final userEmail = user?.email ?? 'Pas d\'email';

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: AppTokens.spacingSM),
              Text(
                'Informations utilisateur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingLG),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 35,
                  child: Stack(
                    children: [
                      const Icon(Icons.person, size: 35, color: Colors.white),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingSM),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 16, color: AppColors.accentLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            userEmail,
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.spacingLG),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.alert.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                ),
                child: const Icon(Icons.logout, color: AppColors.alertLight, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Actions du compte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingLG),
          GlassButton(
            label: 'Se déconnecter',
            onPressed: _signOut,
            variant: GlassButtonVariant.danger,
            icon: Icons.logout,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
