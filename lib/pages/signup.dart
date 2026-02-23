import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safecampus/pages/accueil.dart';
import 'package:safecampus/pages/connexion.dart';
import 'package:safecampus/services/auth_service.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:safecampus/widgets/custom_text_field.dart';
import 'package:safecampus/widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safecampus/main.dart'; // Import pour pseudoNotifier

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pseudoController = TextEditingController();
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final theme = Theme.of(context);
      setState(() => _isLoading = true);
      try {
        // Création du compte Firebase
        User? user = await _authService.signUp(
            _emailController.text.trim(), _passwordController.text.trim());

        if (user != null) {
          await user.sendEmailVerification();

          // sauvegarde locale du pseudo
          final prefs = await SharedPreferences.getInstance();
          if (_pseudoController.text.isNotEmpty) {
            await prefs.setString(
                '${user.uid}_user_pseudo', _pseudoController.text.trim());
            pseudoNotifier.value = _pseudoController.text.trim();
          }

          if (!mounted) return;

          // Affichage de la confirmation
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text("Vérification requise",
                  style: TextStyle(color: theme.colorScheme.primary)),
              content: Text(
                  "Un email de confirmation a été envoyé à ${_emailController.text}.\nVeuillez cliquer sur le lien pour activer votre compte."),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary),
                  child: const Text("Compris"),
                )
              ],
            ),
          );

          // Déconnexion (signUp connecte automatiquement)
          await FirebaseAuth.instance.signOut();

          // Redirect. vers la page de connexion
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Connexion()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: theme.colorScheme.error),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignup() async {
    setState(() => _isLoading = true);
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        final navigator = Navigator.of(context);
        // Sauvegarde du pseudo si fourni par Google
        if (user.displayName != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('${user.uid}_user_pseudo', user.displayName!);
          pseudoNotifier.value = user.displayName;
        }
        navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Accueil()),
            (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Inscription via Apple (TODO)
  void _handleAppleSignup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text("L'inscription via Apple n'est pas encore disponible."),
        duration: const Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Inscription"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rejoignez safecampus",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  "Créez un compte pour accéder aux fonctionnalités de suivi et de communauté.",
                  style: TextStyle(
                      color: theme.colorScheme.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Mail
                CustomTextField(
                  controller: _emailController,
                  labelText: "Email (Obligatoire)",
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Mdp
                CustomTextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  labelText: "Mot de passe (Obligatoire)",
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  validator: (value) => (value != null && value.length < 6)
                      ? 'Le mot de passe doit contenir au moins 6 caractères'
                      : null,
                ),
                const SizedBox(height: 20),

                // Pseudo (Optionnel)
                CustomTextField(
                  controller: _pseudoController,
                  labelText: "Prénom ou Pseudo (Optionnel)",
                  prefixIcon: Icons.person_outline,
                ),

                const SizedBox(height: 30),

                // Disclaimer Données
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "🔒 Vos données personnelles (email, pseudo) ne sont utilisées que pour votre authentification. Vos trajets et journaux restent privés.",
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: "Créer mon compte",
                        onPressed: _handleSignup,
                      ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Ou continuer avec",
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Boutons Sociaux
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleGoogleSignup,
                        icon: Image.asset('assets/image/google.png',
                            height: 24, width: 24),
                        label: const Text("Google"),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ),

                    // Afficher le bouton Apple uniquement sur iOS
                    if (Platform.isIOS) ...[
                      const SizedBox(width: 15),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleAppleSignup,
                          icon: Icon(Icons.apple,
                              size: 28, color: theme.colorScheme.onSurface),
                          label: const Text("Apple"),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
