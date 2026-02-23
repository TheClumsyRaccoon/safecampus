import 'package:flutter/material.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/pages/annuaire.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';

enum TypeConseil { victime, temoin, insecurite }

class OrientationPage extends StatelessWidget {
  const OrientationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Que faire ?",
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
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: theme.colorScheme.secondary),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.secondary),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "En cas de danger immédiat, contactez le 17 ou le 112.",
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildOptionCard(
            context,
            title: "Je viens de subir une violence",
            icon: Icons.shield_outlined,
            onTap: () => _showAdvice(context, TypeConseil.victime),
          ),
          _buildOptionCard(
            context,
            title: "Je suis témoin d'une situation",
            icon: Icons.visibility_outlined,
            onTap: () => _showAdvice(context, TypeConseil.temoin),
          ),
          _buildOptionCard(
            context,
            title: "Je ne me sens pas en sécurité",
            icon: Icons.lock_open_outlined,
            onTap: () => _showAdvice(context, TypeConseil.insecurite),
          ),
          _buildOptionCard(
            context,
            title: "J'ai besoin de parler",
            icon: Icons.record_voice_over_outlined,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnnuairePage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.colorScheme.onSurfaceVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Icon(icon, size: 24, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvice(BuildContext context, TypeConseil type) {
    String title = "";
    String content = "";
    List<Widget> actions = [];
    final theme = Theme.of(context);

    if (type == TypeConseil.victime) {
      title = "Mettez-vous en sécurité";
      content =
          "1. Quittez les lieux si possible.\n2. Rejoignez un endroit fréquenté ou une personne de confiance.\n3. Ne restez pas seul(e).\n4. Si vous êtes blessé(e), allez aux urgences.";
      actions = [
        ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AnnuairePage()));
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary),
          child: const Text("Appeler de l'aide"),
        )
      ];
    } else if (type == TypeConseil.temoin) {
      title = "Intervenir sans danger";
      content =
          "1. Ne vous mettez pas en danger physique.\n2. Si possible, distrayez l'agresseur (demandez l'heure, faites tomber un objet).\n3. Appelez de l'aide ou la sécurité.\n4. Restez avec la victime après.";
    } else if (type == TypeConseil.insecurite) {
      title = "Anticiper";
      content =
          "1. Partagez votre trajet via l'application.\n2. Restez dans des zones éclairées.\n3. Gardez votre téléphone à portée de main.";
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 20),
            Text(content,
                style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Fermer",
                        style: TextStyle(color: theme.colorScheme.onSurface))),
                const SizedBox(width: 10),
                ...actions
              ],
            )
          ],
        ),
      ),
    );
  }
}
