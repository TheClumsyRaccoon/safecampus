import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safecampus/services/auth_service.dart';
import 'package:safecampus/pages/accueil.dart';
import 'package:safecampus/pages/signup.dart';
import 'package:safecampus/widgets/custom_text_field.dart';
import 'package:safecampus/widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safecampus/main.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLoadingSocial = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        User? user = await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          // Vérification de l'email
          if (!user.emailVerified) {
            await FirebaseAuth.instance.signOut();
            throw "Veuillez valider votre email pour accéder à l'application.";
          }

          // Recharger le pseudo pour le nouvel utilisateur
          final prefs = await SharedPreferences.getInstance();
          pseudoNotifier.value = prefs.getString('${user.uid}_user_pseudo');

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const Accueil(isGuest: false)),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoadingSocial = true);
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        // Recharger le pseudo pour le nouvel utilisateur
        final prefs = await SharedPreferences.getInstance();
        pseudoNotifier.value =
            prefs.getString('${user.uid}_user_pseudo') ?? user.displayName;

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
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
      if (mounted) setState(() => _isLoadingSocial = false);
    }
  }

  void _handleAppleLogin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text("La connexion via Apple n'est pas encore disponible."),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Accès aide sans connexion
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const Accueil(isGuest: true)),
                        );
                      },
                      icon: Icon(Icons.emergency,
                          color: theme.colorScheme.secondary),
                      label: Text("Urgence",
                          style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "safecampus",
                    style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                  Text("Connectez-vous pour accéder à votre espace",
                      style: TextStyle(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 40),

                  // Champ mail
                  CustomTextField(
                    controller: _emailController,
                    labelText: "Email universitaire",
                    hintText: "exemple@univ.fr",
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

                  // Champ mdp
                  CustomTextField(
                    controller: _passwordController,
                    labelText: "Mot de passe",
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: theme.colorScheme.onSurfaceVariant),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          text: "Se connecter",
                          onPressed: _handleLogin,
                        ),
                  const SizedBox(height: 30),

                  if (_isLoadingSocial)
                    const Center(child: CircularProgressIndicator())
                  else ...[
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleGoogleLogin,
                            icon: Image.asset('assets/image/google.png',
                                height: 24, width: 24),
                            label: const Text("Google"),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ),
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(width: 15),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleAppleLogin,
                              icon: Icon(Icons.apple,
                                  size: 28, color: theme.colorScheme.onSurface),
                              label: const Text("Apple"),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.onSurface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupPage()),
                      );
                    },
                    child: Text("Pas de compte ? S'inscrire",
                        style: TextStyle(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
