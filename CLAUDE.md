# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TaqwaTime is a Flutter mobile application designed to help Muslims maintain their daily prayer practices with intelligent reminders and personalized tracking. The app calculates prayer times based on geolocation, sends persistent notifications, and tracks prayer completion statistics.

## Development Commands

### Setup and Installation
```bash
# Install dependencies
flutter pub get

# Configure Firebase
# Add google-services.json to android/app/
# Add GoogleService-Info.plist to ios/Runner/
```

### Running the Application
```bash
# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

### Build Commands
```bash
# Build Android APK (release)
flutter build apk --release

# Build iOS (release)
flutter build ios --release
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

## Architecture Overview

### Core Layer (`lib/core/`)
The core layer contains business logic, data models, and services that are used throughout the application.

**Key Services:**
- `NotificationService`: Manages three notification channels (prayer_channel, reminder_channel, preparation_channel). Implements intelligent reminder system with escalating intervals (5, 3, 2, 1 minutes) up to MAX_REMINDERS (5). Uses SharedPreferences to persist reminder counts.
- `RealtimePrayerService`: Singleton service using RxDart BehaviorSubjects for reactive state management. Monitors connectivity status, manages prayer data cache, and provides real-time streams for current prayer, next prayer time, and spiritual messages.
- `PrayerTimeService`: Integrates with the `adhan` package to calculate Islamic prayer times based on geolocation data from `geolocator`.
- `AuthService`: Firebase Authentication wrapper providing auth state changes stream.
- `CacheService`: Handles local data caching and persistence.
- `PerformanceService`: Application performance monitoring.
- `LocationService`: GPS-based location services for prayer time calculations.

**Repositories:**
- `PrayerRepository`: Firestore operations for prayer data. Uses batch writes for multiple prayers. Implements cache invalidation on data mutations.
- `SettingsRepository`: Manages user settings and preferences in Firestore.

**Models:**
- `PrayerModel`: Core domain model with enums `PrayerType` (fajr, dhuhr, asr, maghrib, isha) and `PrayerStatus` (onTime, late, missed, notYet). Immutable model with methods like `markAsCompleted()` and `markAsMissed()`.
- `UserModel`: User profile and authentication data.
- `UserSettingsModel`: User preferences and configuration.

### Features Layer (`lib/features/`)
Organized by feature using a clean architecture approach:
- `authentication/`: Login, registration, profile, home screen, settings, statistics
- `prayer_notification/`: Fullscreen prayer alerts and notification UI
- `prayer_tracking/`: Prayer completion tracking screens
- `quran_reading/`: Quran reading features
- `notifications/`: Notification-related features
- `statistics/`: Prayer statistics and analytics

### Shared Layer (`lib/shared/`)
- `themes/`: App-wide theming including `AppTheme` and `AppColors`
- `constants.dart`: Application constants
- `utils/`: Utility functions
- `widgets/`: Reusable UI components

### State Management
The app uses **Provider** for dependency injection and state management:
- Services are provided at the root level in `main.dart` using `MultiProvider`
- `StreamProvider` is used for auth state changes
- UI screens use `Provider.of<T>(context)` to access services

### Notification Architecture
Critical implementation detail: notification action handlers are defined at the app level to survive when the app is in background/terminated state.

**Global Notification Handler Pattern:**
1. `globalNotificationService` variable in `main.dart` holds the NotificationService instance
2. `onNotificationActionReceived()` function in `main.dart` is marked with `@pragma('vm:entry-point')` to be called from native code
3. `appActionReceivedMethod()` in `app.dart` handles in-app notification actions
4. Both handlers access the global service to maintain reminder state consistency

**Notification Channels:**
- `prayer_channel`: Initial prayer time notifications (High importance)
- `reminder_channel`: Escalating reminders for missed prayers (Max importance, uses Alarm ringtone)
- `preparation_channel`: Pre-prayer preparation reminders at 30, 15, 5 minutes before prayer

**Reminder System Flow:**
1. User receives prayer notification with "Mark Done" and "Remind Later" buttons
2. If "Remind Later" is pressed, system schedules next reminder using REMINDER_INTERVALS
3. Reminder count is stored in SharedPreferences with key `reminder_count_{notificationId}`
4. System stops after MAX_REMINDERS or when user marks prayer as complete
5. When app is in foreground, `FullscreenPrayerAlert` dialog is shown instead of notification

### Firebase Integration
- **Firebase Auth**: User authentication with Google Sign-In support
- **Cloud Firestore**: NoSQL database for prayers, users, and settings
- **Firebase Analytics**: Usage tracking
- **Firebase Messaging**: Push notification infrastructure (though awesome_notifications is used for local notifications)

### Prayer Time Calculation
Uses the `adhan` package (v2.0.0-nullsafety.2) which supports multiple calculation methods (MWL, ISNA, etc.). Prayer times are calculated daily based on:
- User's GPS coordinates (from geolocator)
- Selected calculation method
- Timezone information

## Important Implementation Notes

### Notification Action Handlers
When modifying notification actions, always update both handlers:
- `main.dart:onNotificationActionReceived()` for background/terminated state
- `app.dart:appActionReceivedMethod()` for foreground state

Both must access `globalNotificationService` to maintain state consistency.

### Service Initialization Order
In `main.dart`, the initialization order is critical:
1. Firebase initialization
2. CacheService and PerformanceService
3. SettingsRepository creation
4. NotificationService initialization and global assignment
5. Notification action listeners setup
6. Provider setup with all services

### Dependency Injection
RealtimePrayerService requires manual initialization with dependencies:
```dart
realtimePrayerService.initialize(
  authService: authService,
  settingsRepository: settingsRepository,
);
```

### Data Persistence Strategy
- **Firestore**: Persistent cloud storage for prayers, users, settings
- **SharedPreferences**: Local storage for notification state, reminder counts
- **CacheService**: Intelligent caching layer for offline support
- Prayer data is cached daily and invalidated on date change

### Connectivity Handling
RealtimePrayerService monitors connectivity using `connectivity_plus` and switches between online/offline modes. When connection is restored, it automatically syncs data.

## Common Development Patterns

### Adding a New Prayer-Related Feature
1. Define the model in `lib/core/models/` if needed
2. Add repository methods in `lib/core/repositories/prayer_repository.dart`
3. Implement business logic in appropriate service in `lib/core/services/`
4. Create UI screens in `lib/features/<feature_name>/presentation/screens/`
5. Add route in `lib/routes.dart`
6. Update Provider setup in `main.dart` if new service is needed

### Working with Streams
The app heavily uses reactive streams (RxDart):
- Use `BehaviorSubject` for stateful streams that need initial value
- Use `.distinct()` to prevent duplicate events
- Remember to dispose streams and timers in service cleanup methods

### Notification Development
Test notifications on physical devices as emulators have limited notification support. Use the three notification channels appropriately based on urgency and context.

## Firebase Configuration Files
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Platform options: `lib/firebase_options.dart` (auto-generated via FlutterFire CLI)

## Assets
- Logo assets: `assets/images/logos/`
- Configured in `pubspec.yaml` under `flutter.assets`

## Platform Support
- Android: API 21+ (Android 5.0 Lollipop)
- iOS: 12.0+

## Key Dependencies
- `adhan: ^2.0.0-nullsafety.2` - Prayer time calculations
- `awesome_notifications: ^0.10.1` - Local notifications with actions
- `provider: ^6.0.5` - State management and dependency injection
- `rxdart: ^0.27.7` - Reactive extensions for streams
- `geolocator: ^12.0.0` - GPS location services
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase integration
- `shared_preferences: ^2.2.0` - Local key-value storage
- `connectivity_plus: ^5.0.0` - Network connectivity monitoring
