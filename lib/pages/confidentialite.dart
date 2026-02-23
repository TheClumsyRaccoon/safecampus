import 'package:flutter/material.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';

class ConfidentialitePage extends StatelessWidget {
  const ConfidentialitePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Vos données"),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Transparence et Sécurité",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            "Chez safecampus, nous croyons que votre sécurité ne doit pas se faire au détriment de votre vie privée.",
            style: TextStyle(
                fontSize: 16, color: theme.colorScheme.onSurface, height: 1.5),
          ),
          const SizedBox(height: 30),
          _buildInfoSection(
            icon: Icons.storage_outlined,
            title: "Stockage Local",
            content:
                "Votre journal de bord et vos contacts de confiance sont stockés uniquement sur votre téléphone. Nous n'y avons pas accès.",
            context: context,
          ),
          _buildInfoSection(
            icon: Icons.location_on_outlined,
            title: "Géolocalisation",
            content:
                "Votre position n'est partagée qu'au moment où vous déclenchez une alerte ou un trajet sécurisé, et uniquement avec vos contacts choisis.",
            context: context,
          ),
          _buildInfoSection(
            icon: Icons.lock_outline,
            title: "Anonymat",
            content:
                "Les statistiques d'utilisation (si activées) sont totalement anonymisées et servent uniquement à améliorer l'application.",
            context: context,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: Text(
              "Vous pouvez à tout moment supprimer l'intégralité de vos données locales depuis les paramètres.",
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      {required IconData icon,
      required String title,
      required String content,
      required BuildContext context}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.onSurfaceVariant),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 5),
                Text(content,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
