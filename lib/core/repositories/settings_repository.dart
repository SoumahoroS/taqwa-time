import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings_model.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Référence à la collection des utilisateurs
  CollectionReference get _usersCollection =>
      _firestore.collection('users');

  // Obtenir les paramètres utilisateur depuis Firestore
  Future<UserSettingsModel?> getUserSettings(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('settings')) {
          return UserSettingsModel.fromJson({
            'userId': userId,
            ...data['settings'],
          });
        }
      }

      // Si les paramètres n'existent pas encore, créer les paramètres par défaut
      UserSettingsModel defaultSettings = UserSettingsModel(userId: userId);
      await saveUserSettings(defaultSettings);
      return defaultSettings;
    } catch (e) {
      print('Erreur lors de la récupération des paramètres: ${e.toString()}');
      return null;
    }
  }

  // Sauvegarder les paramètres utilisateur dans Firestore
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    try {
      await _usersCollection.doc(settings.userId).set({
        'settings': settings.toJson()..remove('userId'),
      }, SetOptions(merge: true));

      // Sauvegarder aussi localement pour l'accès hors ligne
      await _saveSettingsLocally(settings);
    } catch (e) {
      print('Erreur lors de la sauvegarde des paramètres: ${e.toString()}');
    }
  }

  // Sauvegarder les paramètres localement pour l'accès hors ligne
  // Sauvegarder les paramètres localement pour l'accès hors ligne
  Future<void> _saveSettingsLocally(UserSettingsModel settings) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String settingsJson = jsonEncode(settings.toJson());
      await prefs.setString('user_settings_${settings.userId}', settingsJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde locale: ${e.toString()}');
    }
  }

  // Récupérer les paramètres localement (pour l'accès hors ligne)
  Future<UserSettingsModel?> getLocalSettings(String userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? settingsJson = prefs.getString('user_settings_$userId');

      if (settingsJson != null) {
        Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        return UserSettingsModel.fromJson(settingsMap);
      }

      return null;
    } catch (e) {
      print('Erreur lors de la récupération locale: ${e.toString()}');
      return null;
    }
  }

  // Mettre à jour un paramètre spécifique
  Future<void> updateSetting(String userId, String key, dynamic value) async {
    try {
      UserSettingsModel? settings = await getUserSettings(userId);

      if (settings != null) {
        Map<String, dynamic> settingsMap = settings.toJson();
        settingsMap[key] = value;

        UserSettingsModel updatedSettings = UserSettingsModel.fromJson(settingsMap);
        await saveUserSettings(updatedSettings);
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du paramètre: ${e.toString()}');
    }
  }
}