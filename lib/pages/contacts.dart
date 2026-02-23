import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:safecampus/widgets/custom_text_field.dart';
import 'package:safecampus/services/secure_storage_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  String get _storageKey {
    final user = FirebaseAuth.instance.currentUser;
    return user != null
        ? '${user.uid}_trusted_contacts'
        : 'guest_trusted_contacts';
  }

  void _loadContacts() {
    final box = SecureStorageService.contactsBox;
    final stored = box.get(_storageKey);

    if (stored != null) {
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(
            (stored as List).map((e) => Map<String, dynamic>.from(e)));
      });
    }
  }

  Future<void> _saveContacts() async {
    final box = SecureStorageService.contactsBox;
    await box.put(_storageKey, _contacts);
  }

  void _addContact(String name, String phone) {
    setState(() {
      _contacts.add({'name': name, 'phone': phone});
    });
    _saveContacts();
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
  }

  void _showAddContactDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AddContactDialog(onAdd: _addContact),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Contacts de confiance",
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
      body: _contacts.isEmpty
          ? Center(
              child: Text(
                "Aucun contact défini.\nAjoutez des proches pour qu'ils reçoivent un SMS en cas d'urgence.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                        color: theme.colorScheme.onSurfaceVariant, width: 0.5),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.secondary.withOpacity(0.2),
                      child: Text(
                        contact['name'][0].toUpperCase(),
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(contact['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                    subtitle: Text(contact['phone'],
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.secondary),
                      onPressed: () => _deleteContact(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  final Function(String, String) onAdd;
  const _AddContactDialog({required this.onAdd});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text("Ajouter un contact",
          style: TextStyle(color: theme.colorScheme.primary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              if (await FlutterContacts.requestPermission(readonly: true)) {
                final contact = await FlutterContacts.openExternalPick();
                if (contact != null) {
                  _nameController.text = contact.displayName;
                  if (contact.phones.isNotEmpty) {
                    _phoneController.text = contact.phones.first.number;
                  }
                }
              }
            },
            icon: const Icon(Icons.contacts, size: 18),
            label: const Text("Importer du répertoire"),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _nameController,
            labelText: "Nom",
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            labelText: "Téléphone",
          ),
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
            final name = _nameController.text.trim();
            final phone = _phoneController.text.trim();

            if (name.isNotEmpty && phone.isNotEmpty) {
              final phoneRegex = RegExp(r'^\+?[0-9][0-9 ]{4,}[0-9]$');
              if (!phoneRegex.hasMatch(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text("Numéro de téléphone invalide"),
                    backgroundColor: theme.colorScheme.error));
                return;
              }

              widget.onAdd(name, phone);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary),
          child: const Text("Ajouter"),
        ),
      ],
    );
  }
}
