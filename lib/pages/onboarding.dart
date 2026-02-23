import 'package:flutter/material.dart';
import 'package:safecampus/pages/connexion.dart';
import 'package:safecampus/widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Bienvenue sur safecampus",
      "body":
          "Votre compagnon de sécurité universitaire. Une aide bienveillante pour lutter contre les VSS.",
    },
    {
      "title": "Fonctionnalités clés",
      "body":
          "Alertez vos proches en un clic, simulez un trajet sécurisé, et gardez une trace de vos ressentis dans un journal privé.",
    },
    {
      "title": "Important",
      "body":
          "safecampus ne remplace pas les services d'urgence (15, 17, 112). En cas de danger immédiat, contactez-les directement.",
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.security,
                              size: 80,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pages[index]["body"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: PrimaryButton(
                text:
                    _currentPage == _pages.length - 1 ? "Commencer" : "Suivant",
                onPressed: () async {
                  if (_currentPage < _pages.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    // Marquer l'onboarding comme vu et naviguer
                    final navigator = Navigator.of(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('hasSeenOnboarding', true);

                    navigator.pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const Connexion()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
