# TaqwaTime

**Système de rappel efficace et persistant pour les obligations religieuses musulmanes**

Une application mobile Flutter développée pour aider les musulmans à maintenir leurs pratiques religieuses quotidiennes avec des rappels intelligents et un suivi personnalisé des prières.

## 📱 Fonctionnalités

### 🕐 Calcul des Heures de Prière
- Calcul automatique des heures de prière basé sur la géolocalisation
- Support pour différentes méthodes de calcul (MWL, ISNA, etc.)
- Affichage en temps réel du temps restant avant la prochaine prière

### 🔔 Notifications Intelligentes
- Notifications push persistantes pour chaque prière
- Rappels personnalisables avant l'heure de prière
- Notifications contextuelles avec messages spirituels

### 📊 Suivi et Statistiques
- Suivi des prières accomplies
- Statistiques de performance spirituelle
- Indicateurs visuels de progression

### 🔐 Authentification
- Connexion sécurisée avec Firebase Auth
- Support Google Sign-In
- Gestion des profils utilisateur

### 🌍 Géolocalisation
- Détection automatique de la position
- Calcul précis des heures de prière selon la location
- Support pour différents fuseaux horaires

## 🛠 Technologies Utilisées

### Frontend
- **Flutter** (SDK ^3.5.3)
- **Dart** - Langage de développement

### Backend & Services
- **Firebase Core** - Infrastructure backend
- **Firebase Auth** - Authentification
- **Cloud Firestore** - Base de données NoSQL
- **Firebase Analytics** - Analyse d'utilisation
- **Firebase Messaging** - Notifications push

### Packages Principaux
- **adhan** (^2.0.0) - Calcul des heures de prière
- **awesome_notifications** (^0.10.1) - Gestion des notifications
- **geolocator** (^12.0.0) - Services de géolocalisation
- **provider** (^6.0.5) - Gestion d'état
- **shared_preferences** (^2.2.0) - Stockage local
- **google_sign_in** (^6.2.1) - Authentification Google

## 🏗 Architecture du Projet

```
lib/
├── core/                    # Couche métier
│   ├── models/             # Modèles de données
│   ├── repositories/       # Repositories
│   └── services/           # Services métier
├── features/               # Fonctionnalités par domaine
│   ├── authentication/    # Authentification
│   ├── prayer_tracking/   # Suivi des prières
│   ├── notifications/     # Gestion des notifications
│   └── statistics/        # Statistiques
├── shared/                # Éléments partagés
│   ├── constants.dart     # Constantes
│   ├── themes/           # Thèmes et couleurs
│   ├── utils/            # Utilitaires
│   └── widgets/          # Widgets réutilisables
├── config/               # Configuration
├── routes.dart          # Routage
└── main.dart           # Point d'entrée
```

## 🚀 Installation et Configuration

### Prérequis
- Flutter SDK ^3.5.3
- Dart SDK
- Android Studio / Xcode
- Compte Firebase

### Étapes d'installation

1. **Cloner le repository**
   ```bash
   git clone <repository-url>
   cd taqwatime
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configuration Firebase**
   - Créer un projet Firebase
   - Ajouter les fichiers de configuration :
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Lancer l'application**
   ```bash
   flutter run
   ```

### Configuration des notifications
L'application utilise awesome_notifications pour les notifications persistantes. Assurez-vous que les permissions sont accordées sur l'appareil.

## 📱 Plateformes Supportées

- ✅ Android (API 21+)
- ✅ iOS (12.0+)

## 🔧 Scripts de Développement

```bash
# Lancer l'application en mode debug
flutter run

# Construire pour la production
flutter build apk --release     # Android
flutter build ios --release     # iOS

# Tests
flutter test

# Analyser le code
flutter analyze

# Formater le code
dart format lib/
```

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

## 📞 Support

Pour toute question ou support technique, veuillez ouvrir une issue sur le repository GitHub.

---

**Développé avec ❤️ pour la communauté musulmane par Soumaila Soumahoro - Développeur Backend & Mobile**
