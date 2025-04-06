import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/authentication/presentation/screens/home_screen.dart';
import 'routes.dart';
import 'shared/themes/app_theme.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'shared/widgets/navigation/taqwa_time_drawer.dart'; // Import du nouveau widget Drawer

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaqwaTime',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Utilisez le thème clair pour le mode sombre
      themeMode: ThemeMode.light,
      home: AuthenticationWrapper(), // Utilisez un wrapper plutôt que initialRoute
      routes: AppRoutes.routes,
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page non trouvée'),
            ),
            body: Center(
              child: Text('La page "${settings.name}" n\'existe pas.'),
            ),
          ),
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("Auth state changed: ${snapshot.connectionState}, hasData: ${snapshot.hasData}");
        if (snapshot.hasData) {
          print("User is authenticated: ${snapshot.data?.email}");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Scaffold(
            drawer: const TaqwaTimeDrawer(),
            body: const HomeScreen(),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}