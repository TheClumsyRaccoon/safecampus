import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/services/secure_storage_service.dart';
import 'package:safecampus/services/sms_service.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:safecampus/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;

class TrajetPage extends StatefulWidget {
  const TrajetPage({super.key});

  @override
  State<TrajetPage> createState() => _TrajetPageState();
}

class _TrajetPageState extends State<TrajetPage> with WidgetsBindingObserver {
  static const int _extensionSeconds = 300; // 5 minutes
  bool _isActive = false;
  bool _isFinished = false;
  double _durationMinutes = 15;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si l'application revient au premier plan et que le trajet était actif
    if (state == AppLifecycleState.resumed && _isActive) {
      if (_remainingSeconds <= 0) {
        _triggerEscalation();
      }
    }
  }

  // Récupération des contacts de confiance
  Future<List<String>> _getRecipients() async {
    final box = SecureStorageService.contactsBox;
    final user = FirebaseAuth.instance.currentUser;
    final String key = user != null
        ? '${user.uid}_trusted_contacts'
        : 'guest_trusted_contacts';
    final contacts = box.get(key);

    if (contacts != null && (contacts as List).isNotEmpty) {
      return (contacts)
          .map((e) => (e['phone'] as String).replaceAll(' ', ''))
          .toList();
    }
    return [];
  }

  void _startJourney() async {
    setState(() {
      _isActive = true;
      _isFinished = false;
      _remainingSeconds = (_durationMinutes * 60).toInt();
    });
    _startTimer();

    // SMS de début de trajet
    final recipients = await _getRecipients();
    if (recipients.isNotEmpty) {
      // Pas d'attente du résultat pour ne pas bloquer l'UI
      SmsService.sendSms(recipients,
              "Je commence un trajet (~${_durationMinutes.toInt()} min).")
          .catchError((e) {
        dev.log("Échec SMS début de trajet", name: "TrajetPage", error: e);
      });
    }
    _scheduleNotification();
  }

  void _stopJourney() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _isFinished = true;
    });
    flutterLocalNotificationsPlugin.cancel(1);
  }

  void _extendJourney() {
    setState(() {
      _remainingSeconds += _extensionSeconds;
    });
    _scheduleNotification();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _triggerEscalation();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> _scheduleNotification() async {
    await flutterLocalNotificationsPlugin.cancel(1);

    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: _remainingSeconds));

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'safety_alert_channel',
      'Alerte Trajet',
      channelDescription: 'Notifications de fin de trajet',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );
    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'ALERTE TRAJET',
        'Fin du temps imparti. Touchez pour ouvrir.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'TRAJET_ALERT', // Distingue la notif trajet du faux appel
      );
    } on PlatformException catch (_) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'ALERTE TRAJET',
        'Fin du temps imparti. Touchez pour ouvrir.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'TRAJET_ALERT',
      );
    }
  }

  void _triggerEscalation() async {
    // Protège contre le double-déclenchement
    setState(() => _isActive = false);

    // Vibration SOS
    Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000]);

    // Ouverture directe de l'app SMS
    final recipients = await _getRecipients();
    if (recipients.isNotEmpty) {
      await SmsService.sendSms(recipients,
          "ALERTE ! Je n'ai pas confirmé la fin de mon trajet. Je suis peut-être en danger.");
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text("Aucun contact d'urgence configuré."),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Trajet sécurisé",
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isActive
            ? _buildActiveView()
            : _isFinished
                ? _buildFinishedView()
                : _buildSetupView(),
      ),
    );
  }

  // Nouvel écran de succès
  Widget _buildFinishedView() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 100, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            "Trajet terminé",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            "Vous êtes bien arrivé(e).",
            style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isFinished = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Nouveau trajet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Où allez-vous ?",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 20),
        // Placeholder Carte (TODO intégration Google Maps)
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.onSurfaceVariant),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map,
                    size: 50, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 10),
                Text("Aperçu de la carte",
                    style:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          "Durée estimée",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${_durationMinutes.toInt()} min",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            Expanded(
              child: Slider(
                value: _durationMinutes,
                min: 1,
                max: 60,
                divisions: 11,
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.onSurfaceVariant,
                onChanged: (value) {
                  setState(() {
                    _durationMinutes = value;
                  });
                },
              ),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _startJourney,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Commencer le trajet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveView() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Trajet en cours",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 10),
        Text(
          "Si le minuteur atteint zéro, vous pourrez envoyer un SMS d'alerte à vos contacts de confiance.",
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 50),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 5),
            color: theme.cardTheme.color,
          ),
          child: Center(
            child: Text(
              _formatTime(_remainingSeconds),
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 50),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _stopJourney,
            icon: const Icon(Icons.check_circle),
            label: const Text("Je suis bien arrivé(e)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextButton.icon(
          onPressed: _extendJourney,
          icon: Icon(Icons.add_alarm, color: theme.colorScheme.primary),
          label: Text("Prolonger (+5 min)",
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AlertePage()));
          },
          icon: Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.secondary),
          label: Text("En danger ? Alerter maintenant",
              style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
