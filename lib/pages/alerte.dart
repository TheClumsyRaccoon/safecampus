import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safecampus/services/secure_storage_service.dart';
import 'package:safecampus/services/sms_service.dart';

class AlertePage extends StatefulWidget {
  final bool showBackButton;
  const AlertePage({super.key, this.showBackButton = true});

  @override
  State<AlertePage> createState() => _AlertePageState();
}

class _AlertePageState extends State<AlertePage> {
  bool _isAlertActive = false;
  bool _isSending = false;
  String? _locationMessage;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les permissions de localisation sont refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showPermissionDialog();
      return Future.error(
          'Les permissions de localisation sont refusées définitivement.');
    }

    // Timeout de 10 secondes pour éviter le blocage infini
    return await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw 'Position introuvable (Délai dépassé)',
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Localisation requise"),
        content: const Text(
            "La localisation est nécessaire pour envoyer votre position exacte.\nVeuillez l'activer dans les paramètres de l'application."),
        actions: <Widget>[
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Ouvrir les paramètres"),
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _toggleAlert() async {
    if (!_isAlertActive) {
      setState(() => _isSending = true);

      String messageBody = "ALERTE safecampus ! Je suis en danger.";
      String statusMsg = "";

      // Tentative de localisation (isolée pour ne pas bloquer l'envoi)
      try {
        Position position = await _determinePosition();
        messageBody +=
            " Ma position : https://maps.google.com/?q=${position.latitude},${position.longitude}";
        statusMsg =
            "Position : ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
      } catch (e) {
        // En cas d'échec GPS on continue quand même
        messageBody += " (Position introuvable)";
        statusMsg = "⚠️ Position introuvable ($e). Envoi du SMS de secours...";
      }

      try {
        // Récupération des contacts
        final box = SecureStorageService.contactsBox;
        final user = FirebaseAuth.instance.currentUser;
        final String key = user != null
            ? '${user.uid}_trusted_contacts'
            : 'guest_trusted_contacts';
        final contacts = box.get(key);

        List<String> recipients = [];
        if (contacts != null && (contacts as List).isNotEmpty) {
          recipients = (contacts)
              .map((e) => (e['phone'] as String).replaceAll(' ', ''))
              .toList();
        } else {
          statusMsg += "\n\nAucun contact configuré !";
        }

        // Envoi du SMS (même si aucun destinataire n'est configuré)
        try {
          await SmsService.sendSms(recipients, messageBody);
          statusMsg += "\n\nAppli SMS ouverte (${recipients.length} contacts).";
        } catch (e) {
          statusMsg += "\n\nErreur : $e";
        }

        _locationMessage = statusMsg;
      } catch (e) {
        _locationMessage = "Erreur système : $e";
      }

      if (!mounted) {
        return;
      }
      setState(() => _isSending = false);
    }

    setState(() {
      _isAlertActive = !_isAlertActive;
      if (!_isAlertActive) _locationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color activeColor = theme.colorScheme.error;
    final Color inactiveColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.close,
                    size: 30, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (widget.showBackButton)
            IconButton(
              icon:
                  Icon(Icons.home, size: 30, color: theme.colorScheme.primary),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
        ],
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Text(
                _isSending
                    ? "ENVOI EN COURS..."
                    : _isAlertActive
                        ? "ALERTE EN COURS"
                        : "URGENCE",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color:
                      _isAlertActive ? activeColor : theme.colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _isSending
                      ? "Récupération de votre position GPS"
                      : _isAlertActive
                          ? "Application SMS ouverte.\n$_locationMessage"
                          : "Appuyez sur le bouton pour déclencher l'alerte et partager votre position.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                      height: 1.5),
                ),
              ),
              const Spacer(flex: 2),

              // --- BOUTON SOS ---
              GestureDetector(
                onTap: _toggleAlert,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAlertActive ? activeColor : inactiveColor,
                    boxShadow: [
                      BoxShadow(
                        color: (_isAlertActive ? activeColor : inactiveColor)
                            .withOpacity(0.4),
                        blurRadius: _isAlertActive ? 50 : 30,
                        spreadRadius: _isAlertActive ? 20 : 10,
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isAlertActive
                          ? Icons.notifications_active
                          : Icons.touch_app,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),

              if (_isAlertActive)
                TextButton.icon(
                  onPressed: _toggleAlert,
                  icon: Icon(Icons.check_circle_outline,
                      color: theme.colorScheme.primary),
                  label: Text(
                    "Je suis en sécurité (Annuler)",
                    style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
