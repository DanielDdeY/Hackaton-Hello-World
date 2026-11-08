import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/sos_sms_contact.dart';

typedef SmsUriLauncher = Future<bool> Function(Uri uri);

final class SosSmsComposer {
  SosSmsComposer({SmsUriLauncher? launch, bool? supported})
    : _launch = launch ?? _launchExternal,
      _isSupported = supported;

  final SmsUriLauncher _launch;
  final bool? _isSupported;

  static bool get isSupported =>
      isSupportedPlatform(isWeb: kIsWeb, platform: defaultTargetPlatform);

  static bool isSupportedPlatform({
    required bool isWeb,
    required TargetPlatform platform,
  }) =>
      !isWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);

  bool get canOpen => _isSupported ?? isSupported;

  static String buildMessage({
    required DateTime now,
    double? latitude,
    double? longitude,
  }) {
    final timestamp = now.toLocal();
    final time =
        '${timestamp.day.toString().padLeft(2, '0')}/'
        '${timestamp.month.toString().padLeft(2, '0')}/'
        '${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
    final location = latitude != null && longitude != null
        ? 'Ubicación: https://maps.google.com/?q=$latitude,$longitude'
        : 'Ubicación no disponible.';
    return 'SOS VECINAL: necesito ayuda. Hora: $time. $location';
  }

  static Uri buildUri({
    required List<SosSmsContact> contacts,
    required String message,
  }) {
    if (contacts.length != 1 ||
        contacts.any(
          (contact) =>
              SosSmsContact.normalizePhoneNumber(contact.phoneNumber) == null,
        ) ||
        message.trim().isEmpty) {
      throw ArgumentError('Se requiere un mensaje y un destinatario SMS válido.');
    }
    final recipient =
        SosSmsContact.normalizePhoneNumber(contacts.single.phoneNumber)!;
    return Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: {'body': message},
    );
  }

  Future<bool> openComposer({
    required List<SosSmsContact> contacts,
    required String message,
  }) {
    if (!canOpen) return Future.value(false);
    return _launch(buildUri(contacts: contacts, message: message));
  }

  static Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
