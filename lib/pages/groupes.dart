import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safecampus/models/group_model.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/pages/groupe_detail.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:safecampus/widgets/custom_text_field.dart';
import 'package:safecampus/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safecampus/main.dart'; // Import pour pseudoNotifier

class GroupesPage extends StatefulWidget {
  const GroupesPage({super.key});

  @override
  State<GroupesPage> createState() => _GroupesPageState();
}

class _GroupesPageState extends State<GroupesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Key _streamKey = UniqueKey();

  // Forcer la création d'un pseudo si manquant
  Future<bool> _checkAndPromptForPseudo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    String? pseudo = prefs.getString('${user.uid}_user_pseudo');

    if (pseudo == null || pseudo.isEmpty) {
      if (!mounted) return false;
      final newPseudo = await showDialog<String>(
        context: context,
        barrierDismissible: false, // L'utilisateur doit choisir un pseudo
        builder: (context) => const _PseudoDialog(),
      );

      if (newPseudo != null) {
        await prefs.setString('${user.uid}_user_pseudo', newPseudo);
        pseudoNotifier.value = newPseudo; // Mise à jour globale

        return true;
      }
      return false;
    }
    return true;
  }

  void _createGroup(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Utiliser le pseudoNotifier qui est à jour immédiatement après la saisie
    // Si null, on fallback sur les prefs, puis sur 'Utilisateur'
    final prefs = await SharedPreferences.getInstance();
    final pseudo = pseudoNotifier.value ??
        prefs.getString('${user.uid}_user_pseudo') ??
        'Utilisateur';

    await _firestoreService.createGroup(name, pseudo);
  }

  void _showCreateGroupDialog() async {
    final hasPseudo = await _checkAndPromptForPseudo();
    if (!mounted || !hasPseudo) return;

    final groupName = await showDialog<String>(
      context: context,
      builder: (context) => const _CreateGroupDialog(),
    );

    if (groupName != null && groupName.isNotEmpty) {
      _createGroup(groupName);
    }
  }

  void _showJoinGroupDialog() async {
    final hasPseudo = await _checkAndPromptForPseudo();
    if (!mounted || !hasPseudo) return;

    // Récupération du pseudo ici pour l'injecter dans le dialogue
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final pseudo = pseudoNotifier.value ??
        prefs.getString('${user!.uid}_user_pseudo') ??
        'Utilisateur';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => _JoinGroupDialog(currentUserPseudo: pseudo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Mes groupes",
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active,
                color: theme.colorScheme.secondary),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AlertePage())),
          ),
        ],
      ),
      body: StreamBuilder<List<Group>>(
        key: _streamKey,
        stream: _firestoreService.getUserGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 60, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 20),
                    const Text(
                      "Impossible de charger les groupes",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _streamKey = UniqueKey()),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Réessayer")),
                  ],
                ),
              ),
            );
          }

          final groupes = snapshot.data ?? [];

          if (groupes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  "Vous n'avez rejoint aucun groupe.\nRejoignez ou créez un groupe pour organiser des trajets sécurisés à plusieurs.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: groupes.length,
            itemBuilder: (context, index) {
              final group = groupes[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                        color: theme.colorScheme.onSurfaceVariant, width: 0.5)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.group, color: theme.colorScheme.primary),
                  ),
                  title: Text(group.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("${group.members.length} membres",
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    if (await _checkAndPromptForPseudo()) {
                      if (!mounted) return;
                      navigator.push(MaterialPageRoute(
                          builder: (context) =>
                              GroupeDetailPage(group: group)));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "join",
            onPressed: _showJoinGroupDialog,
            label: const Text("Rejoindre"),
            icon: const Icon(Icons.login),
            backgroundColor: theme.cardTheme.color,
            foregroundColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "create",
            onPressed: _showCreateGroupDialog,
            label: const Text("Créer"),
            icon: const Icon(Icons.add),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PseudoDialog extends StatefulWidget {
  const _PseudoDialog();
  @override
  State<_PseudoDialog> createState() => _PseudoDialogState();
}

class _PseudoDialogState extends State<_PseudoDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pseudo requis"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              "Veuillez définir un pseudo pour pouvoir utiliser les groupes."),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _controller,
            labelText: "Pseudo",
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text("Enregistrer"),
        )
      ],
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();
  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
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
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text("Créer un groupe",
          style: TextStyle(color: theme.colorScheme.primary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              "Créez un groupe fermé pour organiser des retours avec vos connaissances."),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _controller,
            labelText: "Nom du groupe (ex: Asso Sport)",
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler",
                style: TextStyle(color: theme.colorScheme.onSurface))),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary),
          child: const Text("Créer"),
        ),
      ],
    );
  }
}

class _JoinGroupDialog extends StatefulWidget {
  final String currentUserPseudo;
  const _JoinGroupDialog({required this.currentUserPseudo});
  @override
  State<_JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<_JoinGroupDialog> {
  final _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text("Rejoindre un groupe",
          style: TextStyle(color: theme.colorScheme.primary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              "Entrez le code d'invitation fourni par un administrateur du groupe."),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _controller,
            labelText: "Code d'invitation",
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler",
                style: TextStyle(color: theme.colorScheme.onSurface))),
        _isLoading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              )
            : ElevatedButton(
                onPressed: () async {
                  final code = _controller.text.trim();
                  if (code.isEmpty) return;

                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  setState(() => _isLoading = true);

                  try {
                    await _firestoreService.joinGroupWithCode(
                        code, widget.currentUserPseudo);
                    if (mounted) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(SnackBar(
                          content: const Text("Groupe rejoint !"),
                          backgroundColor: theme.colorScheme.primary));
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                            content: Text("Erreur: $e"),
                            backgroundColor: theme.colorScheme.error),
                      );
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary),
                child: const Text("Rejoindre"),
              ),
      ],
    );
  }
}
