import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:safecampus/main.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';

class FauxAppelPage extends StatefulWidget {
  final String? incomingCallerName;
  const FauxAppelPage({super.key, this.incomingCallerName});

  @override
  State<FauxAppelPage> createState() => _FauxAppelPageState();
}

enum CallState { idle, waiting, ringing, active }

class _FauxAppelPageState extends State<FauxAppelPage>
    with WidgetsBindingObserver {
  CallState _currentState = CallState.idle;
  String _callerName = "";
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    if (widget.incomingCallerName != null) {
      // Si la page est ouverte via la notif, on lance l'appel direct
      _callerName = widget.incomingCallerName!;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _triggerIncomingCall());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // En arrière-plan, c'est la notification native qui prend le relais
    if (state == AppLifecycleState.paused) {
      if (_currentState == CallState.waiting) {
        _timer?.cancel();
        setState(() {
          _currentState = CallState.idle;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  void _triggerIncomingCall() async {
    if (!mounted) {
      return;
    }
    // On annule la notification système pour éviter les doublons (si l'appel se lance in-app)
    await flutterLocalNotificationsPlugin.cancel(0);

    setState(() {
      _currentState = CallState.ringing;
    });
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000], repeat: 0);
      }
    } catch (e) {
      dev.log("Erreur vibration", name: "FauxAppelPage", error: e);
    }
  }

  void _acceptCall() {
    _stopRinging();
    setState(() {
      _currentState = CallState.active;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _declineCall() {
    // Pour ajouter une logique specifique au refus plus tard
    _reset();
  }

  void _stopRinging() {
    Vibration.cancel();
    flutterLocalNotificationsPlugin.cancel(0);
  }

  void _reset() {
    _timer?.cancel();
    _stopRinging();
    if (mounted) {
      // Si la page a été ouverte via la notification, on la ferme à la fin
      if (widget.incomingCallerName != null) {
        Navigator.pop(context);
      } else {
        setState(() {
          _currentState = CallState.idle;
          _seconds = 0;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case CallState.waiting:
        return _buildWaitingScreen();
      case CallState.ringing:
        return _buildIncomingCallScreen();
      case CallState.active:
        return _buildActiveCallScreen();
      case CallState.idle:
        return _buildSelectionScreen();
    }
  }

  Widget _buildActiveCallScreen() {
    // Ecran d'appel
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  _callerName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatDuration(_seconds),
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallButton(Icons.mic_off, "Muet"),
                _buildCallButton(Icons.dialpad, "Clavier"),
                _buildCallButton(Icons.volume_up, "Haut-parleur"),
              ],
            ),
            FloatingActionButton(
              onPressed: _declineCall,
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: InkWell(
        onDoubleTap: _reset,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildIncomingCallScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF202124),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  _callerName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Appel mobile...",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton.large(
                  onPressed: _declineCall,
                  backgroundColor: Colors.redAccent,
                  child:
                      const Icon(Icons.call_end, color: Colors.white, size: 35),
                ),
                FloatingActionButton.large(
                  onPressed: _acceptCall,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.call, color: Colors.white, size: 35),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Faux appel",
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
          Text(
            "Choisissez un scénario pour simuler un appel entrant immédiatement.",
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
          ),
          const SizedBox(height: 30),
          _buildScenarioCard("Maman", "Appel familial classique"),
          _buildScenarioCard("Papa", "Urgence familiale"),
          _buildScenarioCard("Colocataire", "Problème à l'appart"),
          _buildScenarioCard("Patron", "Urgence travail"),
          _buildScenarioCard("Livreur Uber", "Votre commande est arrivée"),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(String name, String subtitle) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.colorScheme.onSurfaceVariant, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.phone_in_talk, color: theme.colorScheme.primary),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.play_arrow_rounded,
            color: theme.colorScheme.primary, size: 30),
        onTap: () => _showTimerOptions(name),
      ),
    );
  }

  Widget _buildCallButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white24,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  void _showTimerOptions(String name) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Déclencher l'appel dans...",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              _buildTimerOption(name, "Immédiatement", 0, Icons.flash_on),
              _buildTimerOption(name, "10 secondes", 10, Icons.timer_10),
              _buildTimerOption(name, "30 secondes", 30, Icons.timer),
              _buildTimerOption(name, "1 minute", 60, Icons.hourglass_bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(
      String name, String label, int seconds, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      onTap: () => _scheduleCall(name, seconds),
    );
  }

  Future<void> _scheduleCall(String name, int delaySeconds) async {
    Navigator.pop(context);
    if (delaySeconds == 0) {
      _callerName = name;
      _triggerIncomingCall();
      return;
    }

    setState(() {
      _currentState = CallState.waiting;
      _callerName = name;
    });

    // Configuration de la notification
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'fake_call_channel',
      'Faux Appel',
      channelDescription: 'Notifications pour le faux appel',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: false,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );
    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

    // Planification
    try {
      // Tente de planifier une alarme exacte (nécessite permission SCHEDULE_EXACT_ALARM)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Appel entrant',
        name,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: name,
      );
    } on PlatformException catch (_) {
      // Si la permission est refusée ou non disponible, on utilise une alarme inexacte
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Appel entrant',
        name,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: name,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Appel de $name programmé dans $delaySeconds secondes"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    _timer?.cancel();
    _timer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted) {
        // On vérifie si cette page est toujours la page active
        // Cela empêche le déclenchement si une autre page d'appel a été ouverte par-dessus via la notif
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          _triggerIncomingCall();
        }
      }
    });
  }
}
