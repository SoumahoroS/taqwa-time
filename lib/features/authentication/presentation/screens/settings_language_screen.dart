import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/user_settings_model.dart';
import '../../../../core/repositories/settings_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';

class SettingsLanguageScreen extends StatefulWidget {
  const SettingsLanguageScreen({super.key});

  @override
  State<SettingsLanguageScreen> createState() => _SettingsLanguageScreenState();
}

class _SettingsLanguageScreenState extends State<SettingsLanguageScreen> {
  late SettingsRepository _repo;
  late AuthService _authService;
  UserSettingsModel? _settings;
  bool _isLoading = true;

  static const _languages = [
    ('fr', 'Français', '🇫🇷', 'Langue par défaut'),
    ('ar', 'العربية', '🇸🇦', 'اللغة العربية'),
    ('en', 'English', '🇬🇧', 'Default language'),
    ('es', 'Español', '🇪🇸', 'Idioma español'),
  ];

  @override
  void initState() {
    super.initState();
    _repo = Provider.of<SettingsRepository>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _load();
  }

  Future<void> _load() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final s = await _repo.getUserSettings(uid);
      if (mounted) setState(() { _settings = s; _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLanguage(String code) async {
    HapticFeedback.selectionClick();
    final uid = _authService.currentUser?.uid;
    if (uid == null || _settings == null) return;
    setState(() {
      final map = _settings!.toJson();
      map['language'] = code;
      _settings = UserSettingsModel.fromJson(map);
    });
    await _repo.updateSetting(uid, 'language', code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Langue enregistrée. Redémarrez l\'app pour appliquer.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _settings?.language ?? 'fr';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Langue et région', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTokens.spacingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Langue de l\'application'),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: _languages.asMap().entries.map((entry) {
                              final i = entry.key;
                              final lang = entry.value;
                              final isSelected = lang.$1 == selected;
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () => _selectLanguage(lang.$1),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
                                            ),
                                            child: Center(
                                              child: Text(lang.$3, style: const TextStyle(fontSize: 24)),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lang.$2,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  lang.$4,
                                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              width: 26, height: 26,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primary.withValues(alpha: 0.3),
                                                border: Border.all(color: AppColors.primaryLight, width: 2),
                                              ),
                                              child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryLight),
                                            )
                                          else
                                            Container(
                                              width: 26, height: 26,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (i < _languages.length - 1)
                                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.08), indent: 74, endIndent: 16),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: AppTokens.spacingMD),
                        GlassCard(
                          padding: const EdgeInsets.all(AppTokens.spacingMD),
                          tintColor: AppColors.accent.withValues(alpha: 0.06),
                          borderColor: AppColors.accent.withValues(alpha: 0.2),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'La traduction complète sera disponible dans une prochaine mise à jour. Redémarrez l\'application après avoir changé la langue.',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75), height: 1.5),
                                ),
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
}
