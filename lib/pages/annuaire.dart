import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnuairePage extends StatelessWidget {
  final bool showBackButton;
  const AnnuairePage({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Annuaire d'aide",
        showBackButton: showBackButton,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(context, "Urgences"),
          _buildContactCard(
            context: context,
            title: "Numéro d'urgence européen",
            number: "112",
            description: "Valable dans toute l'UE. Gratuit.",
            isEmergency: true,
          ),
          _buildContactCard(
            title: "SAMU (Urgence médicale)",
            context: context,
            number: "15",
            description: "En cas de détresse vitale.",
            isEmergency: true,
          ),
          _buildContactCard(
            context: context,
            title: "Police Secours",
            number: "17",
            description: "En cas de danger immédiat.",
            isEmergency: true,
          ),
          _buildContactCard(
            context: context,
            title: "Pompiers",
            number: "18",
            description: "Incendie, accident, péril.",
            isEmergency: true,
          ),
          _buildContactCard(
            context: context,
            title: "Urgence SMS",
            number: "114",
            description: "Pour sourds et malentendants.",
            isEmergency: true,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, "Campus & Écoute"),
          _buildContactCard(
            context: context,
            title: "Référent VSS Campus",
            number: "01 23 45 67 89",
            description: "Écoute confidentielle et orientation.",
            isEmergency: false,
          ),
          _buildContactCard(
            title: "Violences Femmes Info",
            context: context,
            number: "3919",
            description: "Écoute anonyme et gratuite.",
            isEmergency: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
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

  Widget _buildContactCard({
    required String title,
    required BuildContext context,
    required String number,
    required String description,
    required bool isEmergency,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.colorScheme.onSurfaceVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEmergency
                    ? theme.colorScheme.secondary.withOpacity(0.2)
                    : theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmergency ? Icons.phone_in_talk : Icons.support_agent,
                color: isEmergency
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final Uri launchUri =
                    Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
                try {
                  // Ouverture de l'application Téléphone externe
                  await launchUrl(launchUri,
                      mode: LaunchMode.externalApplication);
                } catch (e) {
                  dev.log("Erreur lors de l'appel", error: e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: const Text(
                              "Impossible d'ouvrir l'application Téléphone."),
                          backgroundColor: theme.colorScheme.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmergency
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
