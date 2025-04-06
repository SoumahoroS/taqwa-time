// import 'package:geolocator/geolocator.dart';
// import 'package:flutter/material.dart';
//
// class LocationService {
//   // Vérifier si les services de localisation sont activés
//   Future<bool> isLocationServiceEnabled() async {
//     return await Geolocator.isLocationServiceEnabled();
//   }
//
//   // Vérifier les permissions de localisation
//   Future<LocationPermission> checkPermission() async {
//     return await Geolocator.checkPermission();
//   }
//
//   // Demander les permissions de localisation
//   Future<LocationPermission> requestPermission() async {
//     return await Geolocator.requestPermission();
//   }
//
//   // Obtenir la position actuelle
//   Future<Position?> getCurrentPosition() async {
//     bool serviceEnabled = await isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return null;
//     }
//
//     LocationPermission permission = await checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await requestPermission();
//       if (permission == LocationPermission.denied) {
//         return null;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       return null;
//     }
//
//     return await Geolocator.getCurrentPosition();
//   }
//
//   // Obtenir les coordonnées (latitude, longitude)
//   Future<(double, double)?> getCoordinates() async {
//     final position = await getCurrentPosition();
//     if (position != null) {
//       return (position.latitude, position.longitude);
//     }
//     return null;
//   }
//
//   // Afficher une boîte de dialogue pour demander l'accès à la localisation
//   Future<bool> showLocationDialog(BuildContext context) async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Localisation requise'),
//           content: Text(
//               'TaqwaTime a besoin d\'accéder à votre position pour calculer '
//                   'les horaires de prière avec précision. Voulez-vous '
//                   'activer les services de localisation?'
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Non, merci'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Activer'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     ) ?? false;
//   }
// }

// lib/core/services/location_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String PREF_LATITUDE = 'user_latitude';
  static const String PREF_LONGITUDE = 'user_longitude';

  // Valeurs par défaut pour Abidjan, Côte d'Ivoire
  static const double DEFAULT_LATITUDE = 5.3599;
  static const double DEFAULT_LONGITUDE = -4.0083;

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(PREF_LATITUDE, latitude);
      await prefs.setDouble(PREF_LONGITUDE, longitude);
    } catch (e) {
      print('Erreur lors de l\'enregistrement des coordonnées: $e');
    }
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
                'Exemples:\nParis: 48.8566, 2.3522\nMarseille: 43.2965, 5.3698\nLyon: 45.7640, 4.8357',
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