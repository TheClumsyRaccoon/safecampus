import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/pages/annuaire.dart';
import 'package:safecampus/pages/connexion.dart';
import 'package:safecampus/pages/contacts.dart';
import 'package:safecampus/pages/faux_appel.dart';
import 'package:safecampus/pages/groupes.dart';
import 'package:safecampus/pages/journal.dart';
import 'package:safecampus/pages/orientation.dart';
import 'package:safecampus/pages/trajet.dart';
import 'package:safecampus/pages/parametres.dart';
import 'package:safecampus/pages/signup.dart';
import 'package:safecampus/widgets/feature_card.dart';
import 'package:safecampus/widgets/quick_action_button.dart';
import 'package:safecampus/services/secure_storage_service.dart';
import 'package:safecampus/services/sms_service.dart';
import 'package:safecampus/main.dart'; // Import pour pseudoNotifier

class Accueil extends StatefulWidget {
  final bool isGuest;
  const Accueil({super.key, this.isGuest = false});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  int _selectedIndex = 0;

  void _sendCheckIn() async {
    // Récupération des contacts
    final box = SecureStorageService.contactsBox;
    final user = FirebaseAuth.instance.currentUser;
    final String key = user != null
        ? '${user.uid}_trusted_contacts'
        : 'guest_trusted_contacts';
    final contacts = box.get(key);

    if (contacts != null && (contacts as List).isNotEmpty) {
      final recipients = (contacts)
          .map((e) => (e['phone'] as String).replaceAll(' ', ''))
          .toList();

      try {
        await SmsService.sendSms(recipients,
            "Je vais bien, je suis en sécurité. (Message envoyé via safecampus)");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Message 'Je vais bien' ouvert dans l'app SMS."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        dev.log("Erreur envoi SMS", error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text(
                    "Impossible d'ouvrir l'application SMS. Vérifiez vos contacts."),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun contact de confiance configuré."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  Widget _buildGreeting() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: pseudoNotifier,
          builder: (context, pseudo, _) {
            return Text(
              pseudo != null ? "Bonjour, $pseudo" : "Bonjour !",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        if (widget.isGuest)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupPage())),
                        child: Text(
                          "Mode invité. Créez un compte pour sauvegarder vos données en ligne.",
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const Connexion())),
                child: Text("Retour à la connexion",
                    style:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAlertButton() {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlertePage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.notifications_active_outlined, size: 28),
        label: const Text(
          "Alerte",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.phone_callback,
                label: "Faux appel",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FauxAppelPage()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionButton(
                icon: Icons.send,
                label: "Je vais bien",
                onPressed: _sendCheckIn,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrientationPage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.cardTheme.color,
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              side: BorderSide(color: theme.colorScheme.onSurfaceVariant),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: Icon(Icons.help_outline, color: theme.colorScheme.primary),
            label: Text("Que faire ? (Orientation)",
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          "Accès rapide",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
        children: [
          if (!widget.isGuest)
            FeatureCard(
              icon: Icons.map_outlined,
              title: "Trajet\nSécurisé",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const TrajetPage())),
            ),
          if (!widget.isGuest)
            FeatureCard(
              icon: Icons.book_outlined,
              title: "Journal\nde bord",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const JournalPage())),
            ),
          FeatureCard(
            icon: Icons.contact_phone_outlined,
            title: "Annuaire\nd'aide",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AnnuairePage())),
          ),
          FeatureCard(
            icon: Icons.people_outline,
            title: "Contacts\nde confiance",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ContactsPage())),
          ),
          if (!widget.isGuest)
            FeatureCard(
              icon: Icons.group_outlined,
              title: "Trajets\nGroupés",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const GroupesPage())),
            ),
          if (widget.isGuest)
            FeatureCard(
              icon: Icons.person_add,
              title: "Créer un\ncompte",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SignupPage())),
            ),
        ],
      ),
    );
  }

  // Contenu du tableau de bord
  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildGreeting(),
              _buildAlertButton(),
              const SizedBox(height: 15),
              _buildQuickActions(),
            ]),
          ),
        ),
        _buildFeaturesGrid(),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      //AppBar affichée que sur l'onglet Accueil
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                "safecampus",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              actions: [
                if (!widget.isGuest)
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: theme.colorScheme.primary),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ParametresPage()),
                      );
                    },
                  ),
              ],
            )
          : null,
      // IndexedStack pour préserver l'état des pages
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(child: _buildDashboard()),
          const AlertePage(showBackButton: false),
          const AnnuairePage(showBackButton: false),
        ],
      ),
      floatingActionButton: _selectedIndex != 1
          ? FloatingActionButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              backgroundColor: theme.colorScheme.secondary,
              child:
                  const Icon(Icons.notifications_active, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: theme.cardTheme.color,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded), label: "Alerte"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_library_outlined), label: "Ressources"),
        ],
      ),
    );
  }
}
