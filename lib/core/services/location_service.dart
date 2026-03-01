// lib/core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/settings_repository.dart';

class LocationService {
  static const String PREF_LATITUDE = 'user_latitude';
  static const String PREF_LONGITUDE = 'user_longitude';

  // Valeurs par défaut pour Abidjan, Côte d'Ivoire
  static const double DEFAULT_LATITUDE = 5.3599;
  static const double DEFAULT_LONGITUDE = -4.0083;

  // Vérifier si les services de localisation sont activés
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Vérifier les permissions de localisation
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Demander les permissions de localisation
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Obtenir la position actuelle avec géolocalisation
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  // Obtenir les coordonnées avec géolocalisation automatique
  Future<(double, double)?> getCoordinatesWithLocation() async {
    final position = await getCurrentPosition();
    if (position != null) {
      // Sauvegarder automatiquement les nouvelles coordonnées
      await saveCoordinates(position.latitude, position.longitude);
      return (position.latitude, position.longitude);
    }
    return null;
  }

  // Obtenir les coordonnées stockées ou les valeurs par défaut
  Future<(double, double)> getCoordinates() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      double latitude = prefs.getDouble(PREF_LATITUDE) ?? DEFAULT_LATITUDE;
      double longitude = prefs.getDouble(PREF_LONGITUDE) ?? DEFAULT_LONGITUDE;

      return (latitude, longitude);
    } catch (e) {
      print('Erreur lors de la récupération des coordonnées: $e');
      return (DEFAULT_LATITUDE, DEFAULT_LONGITUDE);
    }
  }

  // Enregistrer les coordonnées manuellement
  Future<void> saveCoordinates(double latitude, double longitude) async {
    try {
      // Sauvegarder localement
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(PREF_LATITUDE, latitude);
      await prefs.setDouble(PREF_LONGITUDE, longitude);

      // Sauvegarder dans Firebase si l'utilisateur est connecté
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.isAnonymous) {
        final settingsRepository = SettingsRepository();
        await settingsRepository.updateSetting(currentUser.uid, 'latitude', latitude);
        await settingsRepository.updateSetting(currentUser.uid, 'longitude', longitude);
      }
    } catch (e) {
      print('Erreur lors de l\'enregistrement des coordonnées: $e');
    }
  }

  // Afficher une boîte de dialogue pour demander l'accès à la localisation
  Future<bool> showLocationPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Localisation requise',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'TaqwaTime a besoin d\'accéder à votre position pour calculer les horaires de prière avec précision selon votre localisation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Vous pourrez modifier cette permission plus tard dans les paramètres.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Plus tard',
                style: TextStyle(color: Colors.grey[600]),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('Autoriser'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Demander la localisation avec boîte de dialogue lors de la connexion
  Future<(double, double)?> requestLocationOnLogin(BuildContext context) async {
    // Demander d'abord à l'utilisateur s'il souhaite activer la localisation
    bool userAccepted = await showLocationPermissionDialog(context);
    
    if (userAccepted) {
      // Essayer d'obtenir la position avec géolocalisation
      final coordinates = await getCoordinatesWithLocation();
      return coordinates;
    }
    
    // Si l'utilisateur refuse, utiliser les coordonnées par défaut
    return null;
  }

  // Interface pour définir manuellement la position
  Future<bool> showLocationSettingDialog(BuildContext context) async {
    double? latitude = DEFAULT_LATITUDE;
    double? longitude = DEFAULT_LONGITUDE;

    // Récupérer les valeurs actuelles
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      latitude = prefs.getDouble(PREF_LATITUDE) ?? DEFAULT_LATITUDE;
      longitude = prefs.getDouble(PREF_LONGITUDE) ?? DEFAULT_LONGITUDE;
    } catch (e) {
      print('Erreur lors de la récupération: $e');
    }

    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Définir votre position'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pour le MVP, veuillez entrer vos coordonnées :'),
              SizedBox(height: 16),
              TextFormField(
                initialValue: latitude.toString(),
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  try {
                    latitude = double.parse(value);
                  } catch (e) {
                    // Ignorer la conversion si ce n'est pas un nombre
                  }
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                initialValue: longitude.toString(),
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  try {
                    longitude = double.parse(value);
                  } catch (e) {
                    // Ignorer la conversion si ce n'est pas un nombre
                  }
                },
              ),
              SizedBox(height: 8),
              Text(
                'Exemples:\nAbidjan: 5.3599, -4.0083\nBouake: 7.6939, -5.0308\nYamoussoukro: 6.8276, -5.2893',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Enregistrer'),
              onPressed: () {
                if (latitude != null && longitude != null) {
                  saveCoordinates(latitude!, longitude!);
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}