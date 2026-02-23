import 'package:flutter/material.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';

class AProposPage extends StatelessWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "À propos"),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Icon(Icons.security,
                size: 80, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              "safecampus",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
            Text(
              "Version 1.0.0",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            Text(
              "safecampus est une initiative étudiante pour lutter contre les Violences Sexistes et Sexuelles (VSS) en milieu universitaire.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 20),
            Text(
              "Notre objectif est de fournir des outils simples, discrets et efficaces pour sécuriser vos déplacements et faciliter l'accès aux ressources d'aide.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: theme.colorScheme.onSurface),
            ),
            const Spacer(),
            Text(
              "Développé avec ❤️ pour la communauté.",
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              "2026 safecampus par TheClumsyRaccoon",
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
