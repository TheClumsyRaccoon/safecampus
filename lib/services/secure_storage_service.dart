import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureStorageService {
  static const String _journalBoxName = 'journal_secure';
  static const String _contactsBoxName = 'contacts_secure';
  static const String _keyStorageKey = 'hive_encryption_key';

  static Box? _journalBox;
  static Box? _contactsBox;

  static Future<void> init() async {
    const secureStorage = FlutterSecureStorage();

    // Récupérer ou générer la clé de chiffrement
    String? encryptionKeyString = await secureStorage.read(key: _keyStorageKey);

    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: _keyStorageKey,
        value: base64UrlEncode(key),
      );
      encryptionKeyString = base64UrlEncode(key);
    }

    final encryptionKey = base64Url.decode(encryptionKeyString);

    // Ouvrir la boîte Hive avec le chiffrement AES-256
    _journalBox = await Hive.openBox(
      _journalBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    _contactsBox = await Hive.openBox(
      _contactsBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  static Box get journalBox {
    assert(_journalBox != null,
        'SecureStorageService.init() doit être appelé en premier');
    return _journalBox!;
  }

  static Box get contactsBox {
    assert(_contactsBox != null,
        'SecureStorageService.init() doit être appelé en premier');
    return _contactsBox!;
  }
}
