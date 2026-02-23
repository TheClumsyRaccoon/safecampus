import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:safecampus/pages/accueil.dart';
import 'package:safecampus/pages/connexion.dart';
import 'package:safecampus/pages/faux_appel.dart';
import 'package:safecampus/pages/onboarding.dart';
import 'package:safecampus/utils/app_colors.dart';
import 'package:safecampus/services/secure_storage_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

// Plugin de notification global
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Clé de navigation globale
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Gestionnaire de thème global
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// Gestionnaire de pseudo global
final ValueNotifier<String?> pseudoNotifier = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Timezone
  tz.initializeTimeZones();

  // Initialisation de la base locale
  await Hive.initFlutter();

  // Initialisation du stockage sécurisé (Clés + Boîtes chiffrées)
  await SecureStorageService.init();

  try {
    // Initialisation de Firebase
    // Sur Web/Windows, cela échouera sans 'firebase_options.dart'
    await Firebase.initializeApp();
  } catch (e) {
    dev.log("Firebase init échouée", name: "main", error: e);
  }

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  // Vérification de l'état de connexion Firebase
  final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

  // Chargement de la préférence de thème
  final String? themeMode = prefs.getString('theme_mode');
  if (themeMode == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else if (themeMode == 'light') {
    themeNotifier.value = ThemeMode.light;
  }

  // Chargement initial du pseudo
  if (isLoggedIn) {
    pseudoNotifier.value = prefs
        .getString('${FirebaseAuth.instance.currentUser!.uid}_user_pseudo');
  }

  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding, isLoggedIn: isLoggedIn));
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  final bool isLoggedIn;
  const MyApp(
      {super.key, required this.hasSeenOnboarding, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _pendingPayload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si l'application revient au premier plan et qu'une navigation est en attente
    if (state == AppLifecycleState.resumed && _pendingPayload != null) {
      _navigateToCall(_pendingPayload!);
      _pendingPayload = null;
    }
  }

  void _navigateToCall(String payload) {
    // Si c'est une notif de trajet, on ne fait rien
    if (payload == 'TRAJET_ALERT') return;

    // Utilisation de addPostFrameCallback pour garantir que le contexte de navigation est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => FauxAppelPage(incomingCallerName: payload),
        ),
      );
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          if (WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) {
            _navigateToCall(payload);
          } else {
            _pendingPayload = payload;
          }
        }
      },
    );

    // Gestion du démarrage du cold boot
    final details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null &&
        details.didNotificationLaunchApp &&
        details.notificationResponse?.payload != null) {
      _navigateToCall(details.notificationResponse!.payload!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'safecampus',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // --- THÈME CLAIR ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.background,
              onSurface: AppColors.textMain,
              onSurfaceVariant: AppColors.textLight,
              error: AppColors.danger,
              onPrimary: AppColors.white,
            ),
            cardTheme: const CardTheme(color: AppColors.white),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.primary,
            ),
          ),
          // --- THÈME SOMBRE ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBackground,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.darkPrimary,
              secondary: AppColors.darkSecondary,
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkTextMain,
              onSurfaceVariant: AppColors.darkTextSecondary,
              error: AppColors.darkDanger,
              onPrimary: AppColors.darkTextMain,
            ),
            cardTheme: const CardTheme(color: AppColors.darkSurface),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkBackground,
              foregroundColor: AppColors.darkPrimary,
            ),
          ),
          // Logique de redirection au démarrage
          home: !widget.hasSeenOnboarding
              ? const OnboardingPage()
              : (widget.isLoggedIn ? const Accueil() : const Connexion()),
        );
      },
    );
  }
}
