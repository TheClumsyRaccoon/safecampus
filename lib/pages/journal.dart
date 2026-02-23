import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safecampus/models/journal_entry.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/pages/nouvelle_entree.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:safecampus/services/secure_storage_service.dart';
import 'package:safecampus/widgets/journal_entry_card.dart';
import 'package:safecampus/widgets/journal_pin_screen.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<JournalEntry> _entries = [];
  bool _isUnlocked = false;
  bool _hasPin = false;
  String _pinInput = "";
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _checkPinStatus();
  }

  String get _entriesKey {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? '${user.uid}_entries' : 'guest_entries';
  }

  String get _pinKey {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? '${user.uid}_journal_pin' : 'guest_journal_pin';
  }

  Future<void> _loadEntries() async {
    final box = SecureStorageService.journalBox;
    final stored = box.get(_entriesKey);

    if (stored != null) {
      setState(() {
        _entries = (stored as List).map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return JournalEntry.fromMap(map);
        }).toList();
      });
    }
  }

  Future<void> _saveEntries() async {
    final box = SecureStorageService.journalBox;
    final dataToSave = _entries.map((e) => e.toMap()).toList();
    await box.put(_entriesKey, dataToSave);
  }

  void _createNewEntry() {
    final newEntry = JournalEntry(
      date: DateTime.now(),
      content: "",
    );
    setState(() {
      _entries.insert(0, newEntry);
    });
    _saveEntries();
    _editEntry(0);
  }

  void _updateEntry(int index, JournalEntry updatedEntry) {
    setState(() {
      _entries[index] = updatedEntry;
    });
    _saveEntries();
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
    _saveEntries();
  }

  void _checkPinStatus() {
    final box = SecureStorageService.journalBox;
    setState(() {
      _hasPin = box.containsKey(_pinKey);
    });
  }

  void _onKeyTap(String value) {
    if (_pinInput.length < 4) {
      setState(() {
        _pinInput += value;
      });
      if (_pinInput.length == 4) {
        _validatePin();
      }
    }
  }

  void _onDeleteTap() {
    if (_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      });
    }
  }

  void _validatePin() {
    final box = SecureStorageService.journalBox;

    // Vérification du verrouillage
    if (_lockoutEndTime != null) {
      if (DateTime.now().isBefore(_lockoutEndTime!)) {
        final remaining = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Trop d'essais. Réessayez dans $remaining s"),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(milliseconds: 1000),
          ),
        );
        setState(() => _pinInput = "");
        return;
      }
      setState(() => _lockoutEndTime = null); // Reset si le temps est écoulé
    }

    if (!_hasPin) {
      // Création du PIN
      box.put(_pinKey, _pinInput);
      setState(() {
        _hasPin = true;
        _isUnlocked = true;
        _pinInput = "";
      });
    } else {
      // Vérification du PIN
      final String? storedPin = box.get(_pinKey);
      if (_pinInput == storedPin) {
        setState(() {
          _isUnlocked = true;
          _pinInput = "";
          _failedAttempts = 0;
        });
      } else {
        // Erreur
        final newFailedAttempts = _failedAttempts + 1;
        setState(() {
          _failedAttempts = newFailedAttempts;
          if (newFailedAttempts >= 3) {
            _lockoutEndTime = DateTime.now().add(const Duration(seconds: 60));
          }
          _pinInput = "";
        });

        if (newFailedAttempts >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text("Trop d'erreurs. Journal verrouillé 1 minute."),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Code incorrect (${3 - newFailedAttempts} essais restants)"),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    }
  }

  void _resetJournal() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Réinitialiser le journal ?",
            style: TextStyle(color: theme.colorScheme.error)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "Attention : Si vous avez oublié votre code, la seule solution est de réinitialiser le journal."),
            SizedBox(height: 10),
            Text("Toutes vos entrées seront définitivement effacées.",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler",
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              // Suppression totale
              final box = SecureStorageService.journalBox;
              box.delete(_pinKey);
              box.delete(_entriesKey);

              setState(() {
                _hasPin = false;
                _pinInput = "";
                _entries = [];
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text("Journal réinitialisé."),
                    backgroundColor: theme.colorScheme.primary),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError),
            child: const Text("Tout effacer"),
          ),
        ],
      ),
    );
  }

  void _editEntry(int index) {
    final entryToEdit = _entries[index];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NouvelleEntreePage(
          entry: entryToEdit,
          onSave: (content, updatedAt) {
            final updatedEntry = entryToEdit.copyWith(
              content: content,
              updatedAt: updatedAt,
            );
            _updateEntry(index, updatedEntry);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Text(
          "Ce journal est votre espace personnel.\nNotez-y vos ressentis, incidents ou observations.",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        return JournalEntryCard(
          entry: _entries[index],
          onTap: () => _editEntry(index),
          onDelete: () => _deleteEntry(index),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Journal de bord",
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active,
                color: theme.colorScheme.secondary),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AlertePage()));
            },
          ),
        ],
      ),
      body: !_isUnlocked
          ? JournalPinScreen(
              hasPin: _hasPin,
              pinInput: _pinInput,
              onKeyTap: _onKeyTap,
              onDeleteTap: _onDeleteTap,
              onReset: _resetJournal,
            )
          : (_entries.isEmpty ? _buildEmptyState() : _buildEntriesList()),
      floatingActionButton: _isUnlocked
          ? FloatingActionButton(
              onPressed: _createNewEntry,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    );
  }
}
