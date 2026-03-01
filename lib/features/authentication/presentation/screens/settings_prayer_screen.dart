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

class SettingsPrayerScreen extends StatefulWidget {
  const SettingsPrayerScreen({super.key});

  @override
  State<SettingsPrayerScreen> createState() => _SettingsPrayerScreenState();
}

class _SettingsPrayerScreenState extends State<SettingsPrayerScreen> {
  late SettingsRepository _repo;
  late AuthService _authService;
  UserSettingsModel? _settings;
  bool _isLoading = true;

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

  Future<void> _update(String key, dynamic value) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null || _settings == null) return;
    setState(() {
      final map = _settings!.toJson();
      map[key] = value;
      _settings = UserSettingsModel.fromJson(map);
    });
    await _repo.updateSetting(uid, key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Paramètres de prière', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        _sectionLabel('Localisation'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppTokens.spacingMD),
                          child: _buildSwitch(
                            icon: Icons.location_on_rounded,
                            title: 'Localisation automatique',
                            subtitle: 'Détecter votre position pour les horaires',
                            value: _settings?.useLocation ?? true,
                            onChanged: (v) => _update('useLocation', v),
                          ),
                        ),
                        const SizedBox(height: AppTokens.spacingMD),
                        _sectionLabel('Calcul des horaires'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppTokens.spacingMD),
                          child: Column(
                            children: [
                              _buildDropdown(
                                icon: Icons.calculate_rounded,
                                title: 'Méthode de calcul',
                                subtitle: 'Choisir la méthode de calcul des horaires',
                                value: _settings?.calculationMethod.name ?? 'mwl',
                                items: const [
                                  ('mwl', 'Muslim World League'),
                                  ('isna', 'ISNA (Amérique du Nord)'),
                                  ('egypt', 'Autorité d\'Égypte'),
                                  ('karachi', 'Université de Karachi'),
                                  ('tehran', 'Géophysique de Téhéran'),
                                  ('jafari', 'Jafari (Chiite)'),
                                ],
                                onChanged: (v) => _update('calculationMethod', v),
                              ),
                              _divider(),
                              _buildDropdown(
                                icon: Icons.school_rounded,
                                title: 'Madhab (heure de Asr)',
                                subtitle: 'École juridique pour le calcul de Asr',
                                value: _settings?.madhab.name ?? 'shafi',
                                items: const [
                                  ('shafi', 'Shafi\'i — standard'),
                                  ('hanafi', 'Hanafi — tardif'),
                                ],
                                onChanged: (v) => _update('madhab', v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.spacingMD),
                        _sectionLabel('Ajustement des horaires'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppTokens.spacingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.12)),
                                    child: const Icon(Icons.tune_rounded, color: AppColors.primaryLight, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Décalage par prière', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                      Text('Ajuster en minutes (−30 à +30)', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...[
                                ('fajr', 'Fajr', Icons.wb_twilight_rounded),
                                ('dhuhr', 'Dhuhr', Icons.wb_sunny_rounded),
                                ('asr', 'Asr', Icons.wb_cloudy_rounded),
                                ('maghrib', 'Maghrib', Icons.nights_stay_outlined),
                                ('isha', 'Isha', Icons.nights_stay_rounded),
                              ].map((p) => _buildOffsetRow(p.$1, p.$2, p.$3)),
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

  Widget _divider() => Divider(height: 20, color: Colors.white.withValues(alpha: 0.1));

  Widget _buildSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (value ? AppColors.primary : Colors.white).withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: value ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.5), size: 20),
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
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: (v) { HapticFeedback.lightImpact(); onChanged(v); },
            activeColor: AppColors.primaryLight,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<(String, String)> items,
    required Function(String) onChanged,
  }) {
    final selectedLabel = items.firstWhere((i) => i.$1 == value, orElse: () => items.first).$2;

    return InkWell(
      onTap: () => _showPicker(title: title, items: items, selected: value, onChanged: onChanged),
      borderRadius: BorderRadius.circular(AppTokens.radiusSM),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.12)),
            child: Icon(icon, color: AppColors.primaryLight, size: 20),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryLight, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker({
    required String title,
    required List<(String, String)> items,
    required String selected,
    required Function(String) onChanged,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A3A).withValues(alpha: 0.97),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = item.$1 == selected;
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(item.$1);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.35)) : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded, color: AppColors.primaryLight, size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (i < items.length - 1)
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOffsetRow(String key, String label, IconData icon) {
    final val = _settings?.prayerOffsets[key] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500))),
          _stepBtn(Icons.remove, val > -30, () {
            HapticFeedback.lightImpact();
            final newOffsets = Map<String, int>.from(_settings?.prayerOffsets ?? {});
            newOffsets[key] = val - 1;
            _update('prayerOffsets', newOffsets);
          }),
          Container(
            width: 58, alignment: Alignment.center,
            child: Text(
              '${val >= 0 ? '+' : ''}$val min',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold,
                color: val == 0 ? Colors.white54 : AppColors.primaryLight,
              ),
            ),
          ),
          _stepBtn(Icons.add, val < 30, () {
            HapticFeedback.lightImpact();
            final newOffsets = Map<String, int>.from(_settings?.prayerOffsets ?? {});
            newOffsets[key] = val + 1;
            _update('prayerOffsets', newOffsets);
          }),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
      ),
      child: Icon(icon, size: 16, color: enabled ? Colors.white : Colors.white30),
    ),
  );
}
