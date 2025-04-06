import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/user_settings_model.dart';
import '../../../../core/repositories/settings_repository.dart';
import '../../../../shared/themes/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthService _authService;
  late SettingsRepository _settingsRepository;
  UserSettingsModel? _userSettings;
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _settingsRepository = Provider.of<SettingsRepository>(context, listen: false);
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser!.uid;

      // Charger les paramètres utilisateur
      final settings = await _settingsRepository.getUserSettings(userId);

      // Charger les données utilisateur avec votre nouvelle méthode
      final userData = await _authService.getUserData(userId);

      setState(() {
        _userSettings = settings;
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final userId = _authService.currentUser!.uid;
      await _settingsRepository.updateSetting(userId, key, value);
      await _loadUserSettings(); // Recharger les paramètres
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userSettings == null
          ? const Center(child: Text('Impossible de charger les paramètres'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(),
            const SizedBox(height: 24),
            _buildNotificationSection(),
            const SizedBox(height: 24),
            _buildPrayerCalculationSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {

    final user = _authService.currentUser;

    // Utiliser le nom du userSettings si disponible, sinon utiliser le nom de Firebase Auth
    final emailPrefix = user?.email?.split('@')[0] ?? 'Utilisateur';
    final userName = user?.displayName ?? emailPrefix;
    final userEmail = user?.email ?? 'Pas d\'email';


    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations utilisateur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 30,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres de notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer les notifications'),
              value: _userSettings!.notificationsEnabled,
              onChanged: (value) {
                _updateSetting('notificationsEnabled', value);
              },
              activeColor: AppColors.primary,
            ),
            const Divider(),
            ListTile(
              title: const Text('Intensité des rappels'),
              subtitle: Text(_getIntensityLabel(_userSettings!.notificationIntensity)),
              trailing: SizedBox(
                width: 120,
                child: DropdownButton<NotificationIntensity>(
                  isDense: true,
                  isExpanded: true,
                  value: _userSettings!.notificationIntensity,
                  onChanged: _userSettings!.notificationsEnabled
                      ? (value) {
                    if (value != null) {
                      _updateSetting('notificationIntensity', value.name);
                    }
                  }
                      : null,
                  items: NotificationIntensity.values.map((intensity) {
                    return DropdownMenuItem<NotificationIntensity>(
                      value: intensity,
                      child: Text(
                        _getIntensityLabel(intensity),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Vibration'),
              value: _userSettings!.vibrationEnabled,
              onChanged: _userSettings!.notificationsEnabled
                  ? (value) {
                _updateSetting('vibrationEnabled', value);
              }
                  : null,
              activeColor: AppColors.primary,
            ),
            const Divider(),
            ListTile(
              title: const Text('Intervalle de rappel'),
              subtitle: Text('${_userSettings!.reminderInterval} minutes'),
              trailing: SizedBox(
                width: 120,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _userSettings!.notificationsEnabled &&
                          _userSettings!.reminderInterval > 1
                          ? () {
                        _updateSetting('reminderInterval',
                            _userSettings!.reminderInterval - 1);
                      }
                          : null,
                    ),
                    Text('${_userSettings!.reminderInterval}'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _userSettings!.notificationsEnabled
                          ? () {
                        _updateSetting('reminderInterval',
                            _userSettings!.reminderInterval + 1);
                      }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCalculationSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calcul des horaires de prière',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            // Utilisation d'un widget personnalisé au lieu de ListTile pour le menu déroulant
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Méthode de calcul',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_getCalculationMethodLabel(_userSettings!.calculationMethod)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButton<CalculationMethod>(
                    isExpanded: true,
                    value: _userSettings!.calculationMethod,
                    onChanged: (value) {
                      if (value != null) {
                        _updateSetting('calculationMethod', value.name);
                      }
                    },
                    items: CalculationMethod.values.map((method) {
                      return DropdownMenuItem<CalculationMethod>(
                        value: method,
                        child: Text(_getCalculationMethodLabel(method)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Utilisation d'un widget personnalisé au lieu de ListTile pour le menu déroulant
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Madhab',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_getMadhabLabel(_userSettings!.madhab)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButton<Madhab>(
                    isExpanded: true,
                    value: _userSettings!.madhab,
                    onChanged: (value) {
                      if (value != null) {
                        _updateSetting('madhab', value.name);
                      }
                    },
                    items: Madhab.values.map((madhab) {
                      return DropdownMenuItem<Madhab>(
                        value: madhab,
                        child: Text(_getMadhabLabel(madhab)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Utiliser la localisation'),
              subtitle: const Text('Calculer les horaires selon votre position'),
              value: _userSettings!.useLocation,
              onChanged: (value) {
                _updateSetting('useLocation', value);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getIntensityLabel(NotificationIntensity intensity) {
    switch (intensity) {
      case NotificationIntensity.low:
        return 'Faible';
      case NotificationIntensity.medium:
        return 'Moyenne';
      case NotificationIntensity.high:
        return 'Élevée';
    }
  }

  String _getCalculationMethodLabel(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.mwl:
        return 'Muslim World League';
      case CalculationMethod.isna:
        return 'Islamic Society of North America';
      case CalculationMethod.egypt:
        return 'Egyptian General Authority of Survey';
      case CalculationMethod.karachi:
        return 'University of Islamic Sciences, Karachi';
      case CalculationMethod.tehran:
        return 'Institute of Geophysics, University of Tehran';
      case CalculationMethod.jafari:
        return 'Shia Ithna-Ashari, Leva Research Institute, Qum';
    }
  }

  String _getMadhabLabel(Madhab madhab) {
    switch (madhab) {
      case Madhab.shafi:
        return 'Shafi\'i';
      case Madhab.hanafi:
        return 'Hanafi';
    }
  }
}