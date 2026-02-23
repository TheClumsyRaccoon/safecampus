import 'package:flutter/material.dart';

class JournalPinScreen extends StatelessWidget {
  final bool hasPin;
  final String pinInput;
  final void Function(String) onKeyTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onReset;

  const JournalPinScreen({
    super.key,
    required this.hasPin,
    required this.pinInput,
    required this.onKeyTap,
    required this.onDeleteTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 50, color: theme.colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          hasPin ? "Entrez votre code" : "Créez votre code",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 30),

        // Indicateurs de points
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < pinInput.length
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
            );
          }),
        ),
        const SizedBox(height: 50),

        // Clavier numérique
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var j = 1; j <= 3; j++)
                  _buildPinKey(context, (i * 3 + j).toString()),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80),
            _buildPinKey(context, "0"),
            Container(
              width: 80,
              alignment: Alignment.center,
              child: IconButton(
                onPressed: onDeleteTap,
                icon: Icon(Icons.backspace_outlined,
                    color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        if (hasPin)
          TextButton(
            onPressed: onReset,
            child: Text(
              "Code oublié ?",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _buildPinKey(BuildContext context, String value) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: () => onKeyTap(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.cardTheme.color,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          shape: const CircleBorder(),
          side:
              BorderSide(color: theme.colorScheme.onSurfaceVariant, width: 0.5),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
