import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda que la persona aceptó el aviso de responsabilidad del SOS.
///
/// La primera activación pide la casilla; después el botón envía el SOS
/// directamente para no perder tiempo en una emergencia.
class SosConsentStore {
  const SosConsentStore();

  static const currentVersion = 1;
  static const _key = 'sos_consent_version';

  bool hasConsent(SharedPreferences preferences) =>
      (preferences.getInt(_key) ?? 0) >= currentVersion;

  Future<void> grant(SharedPreferences preferences) =>
      preferences.setInt(_key, currentVersion);

  Future<void> reset(SharedPreferences preferences) => preferences.remove(_key);
}
