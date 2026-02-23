import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safecampus/pages/a_propos.dart';
import 'package:safecampus/pages/connexion.dart';
import 'package:flutter/services.dart';
import 'package:safecampus/pages/confidentialite.dart';
import 'package:safecampus/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:safecampus/services/firestore_service.dart';
import 'package:safecampus/services/auth_service.dart';
import 'package:safecampus/services/secure_storage_service.dart';

class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  String? _pseudo;
  final _pseudoController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadPseudo();
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  Future<void> _loadPseudo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pseudo = prefs.getString('${user.uid}_user_pseudo');
      _pseudoController.text = _pseudo ?? '';
    });
  }

  void _showEditPseudoDialog() {
    // Assure que le contrôleur a la dernière valeur avant d'afficher la boîte de dialogue
    _pseudoController.text = _pseudo ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Modifier mon pseudo"),
        content: TextField(
          controller: _pseudoController,
          decoration: const InputDecoration(labelText: "Pseudo"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final newPseudo = _pseudoController.text.trim();
              final prefs = await SharedPreferences.getInstance();

              if (newPseudo.isNotEmpty) {
                await prefs.setString('${user.uid}_user_pseudo', newPseudo);
                pseudoNotifier.value = newPseudo; // Mise à jour globale

                await _firestoreService.updatePseudoInGroups(newPseudo);
              } else {
                await prefs.remove('${user.uid}_user_pseudo');
                pseudoNotifier.value = null; // Mise à jour globale
              }

              if (!mounted) return;
              setState(() => _pseudo = newPseudo.isNotEmpty ? newPseudo : null);
              if (navigator.mounted) navigator.pop();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                    content: const Text("Pseudo mis à jour."),
                    backgroundColor: Theme.of(scaffoldMessenger.context)
                        .colorScheme
                        .primary),
              );
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pinKey = '${user.uid}_journal_pin';
    final box = SecureStorageService.journalBox;

    if (!box.containsKey(pinKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Aucun code PIN n'est défini. Veuillez en créer un dans le journal.")),
      );
      return;
    }

    final isVerified = await showDialog<bool>(
      context: context,
      builder: (context) => _VerifyPinDialog(storedPin: box.get(pinKey)),
    );

    if (isVerified != true) return;
    if (!mounted) return;

    final newPin = await showDialog<String>(
      context: context,
      builder: (context) => const _NewPinDialog(),
    );

    if (newPin != null && newPin.length == 4) {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await box.put(pinKey, newPin);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text("Code PIN du journal mis à jour."),
            backgroundColor: Colors.green),
      );
    }
  }

  void _showDeleteDataConfirmationDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Supprimer le compte ?",
            style: TextStyle(color: theme.colorScheme.error)),
        content: const Text(
            "Cette action est irréversible. Toutes vos données (compte, journal, contacts) seront définitivement effacées. Voulez-vous continuer ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError),
            onPressed: _deleteUserData,
            child: const Text("Supprimer"),
          )
        ],
      ),
    );
  }

  void _deleteUserData() async {
    Navigator.pop(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
        context: context,
        builder: (_) => const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);

    try {
      final uid = user.uid;
      // Supprimer les données locales
      final journalBox = SecureStorageService.journalBox;
      await journalBox.delete('${uid}_journal_pin');
      await journalBox.delete('${uid}_entries');
      final contactsBox = SecureStorageService.contactsBox;
      await contactsBox.delete('${uid}_trusted_contacts');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${uid}_user_pseudo');

      // Supprimer les données des groupes Firestore
      await _firestoreService.deleteUserGroupData();

      // Supprimer l'utilisateur Firebase
      await user.delete();

      // Naviguer vers l'écran de connexion
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Connexion()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Votre compte et vos données ont été supprimés."),
            backgroundColor: Colors.green),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      if (e.code == 'requires-recent-login') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Connexion()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text(
                  "Pour supprimer votre compte, veuillez vous reconnecter puis réessayer."),
              duration: const Duration(seconds: 5),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur: ${AuthService.mapFirebaseError(e.code)}"),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text("Une erreur inattendue est survenue."),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Paramètres"),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle("Préférences"),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              return _buildSwitchTile(
                title: "Mode Sombre",
                subtitle: "Thème visuel de l'application",
                value: currentMode == ThemeMode.dark,
                onChanged: (isDark) async {
                  themeNotifier.value =
                      isDark ? ThemeMode.dark : ThemeMode.light;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(
                      'theme_mode', isDark ? 'dark' : 'light');
                },
                icon: Icons.dark_mode_outlined,
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("Sécurité du compte"),
          _buildActionTile(
            title: "Mon pseudo",
            subtitle: _pseudo ?? "Non défini",
            icon: Icons.person_outline,
            onTap: _showEditPseudoDialog,
          ),
          _buildActionTile(
            title: "Changer le code PIN",
            icon: Icons.lock_outline,
            onTap: _showChangePinDialog,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("Vos données"),
          _buildActionTile(
            title: "Confidentialité",
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConfidentialitePage()),
              );
            },
          ),
          _buildActionTile(
            title: "À propos",
            icon: Icons.info_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AProposPage()),
              );
            },
          ),
          _buildActionTile(
            title: "Supprimer mes données",
            icon: Icons.delete_forever_outlined,
            color: theme.colorScheme.secondary,
            onTap: _showDeleteDataConfirmationDialog,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () async {
                pseudoNotifier.value = null; // Réinitialiser le pseudo global
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Connexion()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Se déconnecter",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "safecampus v1.0.0",
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final tileColor = color ?? theme.colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon,
              color: color == null ? theme.colorScheme.primary : tileColor),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: tileColor)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
            : null,
        trailing: Icon(Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _VerifyPinDialog extends StatefulWidget {
  final String storedPin;
  const _VerifyPinDialog({required this.storedPin});

  @override
  State<_VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<_VerifyPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text("Changer le code PIN"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Veuillez entrer votre code PIN actuel pour continuer."),
          const SizedBox(height: 15),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: "Code PIN actuel"),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            if (_controller.text == widget.storedPin) {
              Navigator.pop(context, true);
            } else {
              Navigator.pop(context, false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text("Code PIN actuel incorrect."),
                    backgroundColor: theme.colorScheme.error),
              );
            }
          },
          child: const Text("Vérifier"),
        ),
      ],
    );
  }
}

class _NewPinDialog extends StatefulWidget {
  const _NewPinDialog();

  @override
  State<_NewPinDialog> createState() => _NewPinDialogState();
}

class _NewPinDialogState extends State<_NewPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nouveau code PIN"),
      content: TextField(
        controller: _controller,
        decoration:
            const InputDecoration(labelText: "Nouveau code PIN (4 chiffres)"),
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        autofocus: true,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.length == 4) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }
}
