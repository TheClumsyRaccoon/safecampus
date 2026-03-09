# SafeCampus

SafeCampus est une application mobile de sécurité personnelle développée en flutter, destinée aux étudiants, pour lutter contre l'insécurité et les VSS.

NB : Le projet est un WIP, tout est susceptible de changer.  
NB1 : Le premier commit comportait un projet déjà bien rempli car ça fait 2 petites semaines que je travaille dessus (et que l'idée de rendre SafeCampus open source ne m'a été suggéré il n'y a que quelques jours).

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
