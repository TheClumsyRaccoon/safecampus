# SafeCampus

SafeCampus est une application mobile de sécurité personnelle développée en flutter, destinée aux étudiants, pour lutter contre l'insécurité et les VSS.

NB : Le projet est un WIP, tout est susceptible de changer.  
NB1 : Le premier commit comportait un projet déjà bien rempli car ça fait 2 petites semaines que je travaille dessus (et que l'idée de rendre SafeCampus open source ne m'a été suggéré il n'y a que quelques jours).

---

## Architecture

```
lib/
├── main.dart                        # Point d'entrée, init, routage
│
├── pages/
│   ├── a_propos.dart                # Page d'Infos
│   ├── accueil.dart                 # Tableau de bord principal
│   ├── alerte.dart                  # Bouton SOS
│   ├── annuaire.dart                # Annuaire d'urgence
│   ├── confidentialite.dart         # Politique de confidentialité   
│   ├── connexion.dart               # Authentification
│   ├── contacts.dart                # Gestion des contacts de confiance
│   ├── faux_appel.dart              # Simulation d'appel entrant
│   ├── groupe_detail.dart           # Détail d'un groupe de trajet
│   ├── groupes.dart                 # Liste des groupes
│   ├── journal.dart                 # Journal de bord
│   ├── nouveau_trajet_groupe.dart   # Formulaire de création de trajet
│   ├── nouvelle_entree.dart         # Édition d'une entrée journal
│   ├── onboarding.dart              # Écrans d'introduction
│   ├── orientation.dart             # Guide "Que faire ?"
│   ├── parametres.dart              # Paramètres du compte
│   ├── signup.dart                  # Création de compte
│   └── trajet.dart                  # Trajet sécurisé
│
├── services/
│   ├── auth_service.dart            # Authentification Firebase
│   ├── firestore_service.dart       # Service Firestore (lecture, écriture..)
│   ├── secure_storage_service.dart  # Initialisation du stockage chiffré
│   └── sms_service.dart             # Envoi via l'app SMS native
│
├── models/
│   ├── group_model.dart             # Group, GroupMember, GroupTrip, GroupRole
│   ├── invitation_code.dart         # Code d'invitation de groupe
│   └── journal_entry.dart           # Entrée de journal
│
├── widgets/                         # Tout widget qui se répète
│   ├── custom_app_bar.dart
│   ├── custom_text_field.dart
│   ├── feature_card.dart
│   ├── journal_entry_card.dart
│   ├── journal_pin_screen.dart
│   ├── primary_button.dart
│   └── quick_action_button.dart
│
└── utils/
    └── app_colors.dart              # Palette de couleurs (clair / sombre)
```

---

## Tech Stack

| Domaine | Technologie |
|---|---|
| Framework | Flutter (Dart) |
| Authentification | Firebase Auth — email, Google, Apple |
| Base de données cloud | Cloud Firestore |
| Stockage local chiffré | Hive + Flutter Secure Storage (AES-256) |
| Notifications locales | Flutter Local Notifications |
| Géolocalisation | Geolocator |
| SMS | URL Launcher (délégation à l'application SMS native) |

---

## Prérequis

- Flutter SDK 3.x ou supérieur
- Un projet Firebase avec Authentication et Firestore activés
- Le fichier `google-services.json` placé dans `android/app/`
- Pour la connexion Apple : bundle ID configuré et capability Sign In with Apple activée dans Xcode

---

## Installation

```bash
git clone https://github.com/TheClumsyRaccoon/safecampus.git
cd safecampus
flutter pub get
flutter run
```

Le fichier `firebase_options.dart` doit être présent avant le premier lancement. Il est généré via la CLI Firebase :

```bash
flutterfire configure
```

---

Développée par TheClumsyRaccoon.
