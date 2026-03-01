import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'cache_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '449012546233-8806vv2pprf5eat4201nrprk7md797fl.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour suivre les changements d'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inscription avec email et mot de passe
  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      User? user = result.user;
      if (user != null) {
        // Mettre à jour le displayName de l'utilisateur
        await user.updateDisplayName(name);

        // Créer un profil utilisateur dans Firestore
        UserModel newUser = UserModel(
          id: user.uid,
          email: email,
          name: name,
          latitude: 0.0, // Valeurs par défaut
          longitude: 0.0, // À mettre à jour avec la géolocalisation
          timezone: 'UTC', // À mettre à jour avec le fuseau horaire détecté
          notificationSettings: {
            'enabled': true,
            'intensity': 'medium',
            'sound': 'default',
            'vibration': true,
          },
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
        return newUser;
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Connexion avec email et mot de passe
  Future<UserModel?> signIn(String email, String password) async {
    try {

      // Persistance définie sur SESSION (par défaut) pour maintenir l'utilisateur connecté
      // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      User? user = result.user;
      if (user != null) {
        // Récupérer les données utilisateur de Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Connexion avec Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          UserModel newUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'Utilisateur',
            latitude: 0.0,
            longitude: 0.0,
            timezone: 'UTC',
            notificationSettings: {
              'enabled': true,
              'intensity': 'medium',
              'sound': 'default',
              'vibration': true,
            },
          );
          
          await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
          return newUser;
        } else {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Erreur Google Sign-In: $e');
      return null;
    }
  }

  // Accès invité (sans authentification)
  Future<bool> continueAsGuest() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user != null;
    } catch (e) {
      print('Erreur accès invité: $e');
      return false;
    }
  }

  // Vérifier si l'utilisateur est un invité
  bool get isGuestUser => _auth.currentUser?.isAnonymous ?? false;

  // Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Méthode optimisée avec cache
  Future<UserModel?> getUserData(String userId) async {
    try {
      // Vérifier d'abord le cache
      final cachedUser = await CacheService.instance.getUserData(userId);
      if (cachedUser != null) {
        return UserModel.fromJson(cachedUser);
      }

      // Si pas en cache, récupérer depuis Firestore
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userData);
        
        // Mettre en cache pour les prochaines fois
        await CacheService.instance.putUserData(userId, userData);
        
        return userModel;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

}