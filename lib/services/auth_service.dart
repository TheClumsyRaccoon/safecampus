import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inscription avec Email/Mot de passe
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseError(e.code);
    }
  }

  // Connexion
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseError(e.code);
    }
  }

  // Connexion/Inscription avec Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e, stackTrace) {
      dev.log(
        "Échec de la connexion Google",
        name: "AuthService",
        error: e,
        stackTrace: stackTrace,
      );
      throw "Une erreur est survenue avec la connexion Google.";
    }
  }

  // Connexion/Inscription avec Apple (fonctionnel mais non implementé dans l'app pour l'instant)
  Future<User?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
        nonce: nonce,
      );
      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e, stackTrace) {
      dev.log(
        "Échec de la connexion Apple",
        name: "AuthService",
        error: e,
        stackTrace: stackTrace,
      );
      throw "Une erreur est survenue avec la connexion Apple.";
    }
  }

  /// Génère un nonce sécurisé pour la connexion Apple
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Trad. des erreurs Firebase
  static String mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return "Aucun utilisateur trouvé avec cet email.";
      case 'invalid-credential':
        return "Email ou mot de passe incorrect.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'email-already-in-use':
        return "Cet email est déjà utilisé.";
      case 'invalid-email':
        return "L'adresse email est invalide.";
      case 'weak-password':
        return "Le mot de passe est trop faible.";
      default:
        return "Une erreur est survenue ($code).";
    }
  }
}
