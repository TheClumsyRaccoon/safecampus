import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  /// Ouvre l'application SMS native, destinataire et texte pré-remplis
  /// Séparateur (';' pour Android, ',' pour iOS)
  static Future<void> sendSms(List<String> recipients, String body) async {
    final String separator = Platform.isAndroid ? ';' : ',';
    final String recipientsList = recipients.join(separator);

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: recipientsList,
      queryParameters: {'body': body},
    );

    if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
      throw 'Impossible d\'ouvrir l\'application SMS.';
    }
  }
}
