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

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() => _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState extends State<SettingsNotificationsScreen> {
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
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        _sectionLabel('Rappels'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppTokens.spacingMD),
                          child: Column(
                            children: [
                              _buildSwitch(
                                icon: Icons.notification_important_rounded,
                                title: 'Rappels de prière',
                                subtitle: 'Recevoir une notification pour chaque prière',
                                value: _settings?.notificationsEnabled ?? true,
                                onChanged: (v) => _update('notificationsEnabled', v),
                              ),
                              _divider(),
                              _buildSwitch(
                                icon: Icons.vibration_rounded,
                                title: 'Vibration',
                                subtitle: 'Vibrer lors des notifications',
                                value: _settings?.vibrationEnabled ?? true,
                                onChanged: (v) => _update('vibrationEnabled', v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.spacingMD),
                        _sectionLabel('Volume et intensité'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppTokens.spacingMD),
                          child: _buildVolumeSlider(),
                        ),
                        const SizedBox(height: AppTokens.spacingMD),
                        _sectionLabel('Rappels manqués'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppTokens.spacingMD),
                          child: Column(
                            children: [
                              _buildStepper(
                                icon: Icons.timer_outlined,
                                title: 'Intervalle entre rappels',
                                subtitle: 'Minutes entre chaque rappel si prière manquée',
                                value: _settings?.reminderInterval ?? 5,
                                min: 1, max: 30, unit: 'min',
                                onChanged: (v) => _update('reminderInterval', v),
                              ),
                              _divider(),
                              _buildStepper(
                                icon: Icons.repeat_rounded,
                                title: 'Nombre max de rappels',
                                subtitle: 'Arrêter les rappels après ce nombre',
                                value: _settings?.maxReminders ?? 3,
                                min: 1, max: 10, unit: 'fois',
                                onChanged: (v) => _update('maxReminders', v),
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

  Widget _buildVolumeSlider() {
    final intensity = _settings?.notificationIntensity ?? NotificationIntensity.medium;
    final labels = ['Faible', 'Moyen', 'Élevé'];
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.12)),
              child: const Icon(Icons.volume_up_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Volume des notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(labels[intensity.index], style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryLight,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
            thumbColor: AppColors.primaryLight,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: intensity.index / 2.0,
            divisions: 2,
            onChanged: (v) {
              final idx = (v * 2).round();
              setState(() {
                if (_settings != null) {
                  final map = _settings!.toJson();
                  map['notificationIntensity'] = NotificationIntensity.values[idx].name;
                  _settings = UserSettingsModel.fromJson(map);
                }
              });
            },
            onChangeEnd: (v) {
              final idx = (v * 2).round();
              _update('notificationIntensity', NotificationIntensity.values[idx].name);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Text(l, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)))).toList(),
        ),
      ],
    );
  }

  Widget _buildStepper({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required String unit,
    required Function(int) onChanged,
  }) {
    return Row(
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
        Row(
          children: [
            _stepBtn(Icons.remove, value > min, () { HapticFeedback.lightImpact(); onChanged(value - 1); }),
            Container(
              width: 52, alignment: Alignment.center,
              child: Text('$value $unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
            ),
            _stepBtn(Icons.add, value < max, () { HapticFeedback.lightImpact(); onChanged(value + 1); }),
          ],
        ),
      ],
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
