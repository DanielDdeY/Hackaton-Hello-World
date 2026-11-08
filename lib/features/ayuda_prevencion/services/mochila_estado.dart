import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EstadoBonoMochila {
  noDisponible,
  disponible,
  reclamado,
}

/// Representa el estado de la mochila de emergencia y su elegibilidad de bono.
class MochilaEstado {
  const MochilaEstado({
    required this.items,
    required this.bonoReclamado,
    required this.totalItems,
    required this.checkedCount,
  });

  final Map<String, bool> items;
  final bool bonoReclamado;
  final int totalItems;
  final int checkedCount;

  bool get estaCompleta => checkedCount >= totalItems && totalItems > 0;

  EstadoBonoMochila get estadoBono {
    if (bonoReclamado) return EstadoBonoMochila.reclamado;
    if (estaCompleta) return EstadoBonoMochila.disponible;
    return EstadoBonoMochila.noDisponible;
  }
}

/// Gestiona la verificacion y asignacion del bono de preparacion vecinal.
abstract class MochilaVerificacion {
  static const String keyBonoReclamado = 'mochila_bono_reclamado_v1';
  static const String badgeVecinoPreparado = 'vecino-preparado';
  static const int fichasBono = 50;
  static const int xpBono = 100;

  /// Verifica si el usuario ya reclamo el bono unico.
  static Future<bool> isBonoReclamado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyBonoReclamado) ?? false;
  }

  /// Otorga el bono de 50 fichas y 100 XP tanto en persistencia local
  /// como en Firestore (si el usuario esta autenticado).
  static Future<void> reclamarBono({
    String? uid,
    FirebaseFirestore? firestore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyBonoReclamado, true);

    // Sumar fichas y xp en SharedPreferences locales
    final fichasActuales = prefs.getInt('vecino_fichas') ?? 0;
    final xpActual = prefs.getInt('vecino_xp') ?? 0;
    await prefs.setInt('vecino_fichas', fichasActuales + fichasBono);
    await prefs.setInt('vecino_xp', xpActual + xpBono);

    // Guardar insignia en SharedPreferences
    final insignias = prefs.getStringList('vecino_insignias') ?? <String>[];
    if (!insignias.contains(badgeVecinoPreparado)) {
      insignias.add(badgeVecinoPreparado);
      await prefs.setStringList('vecino_insignias', insignias);
    }

    // Si hay usuario en Firebase, sincronizar con Firestore
    String? effectiveUid = uid;
    if (effectiveUid == null) {
      try {
        effectiveUid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        effectiveUid = null;
      }
    }

    if (effectiveUid != null) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        final userRef = db.collection('users').doc(effectiveUid);
        await userRef.set({
          'fichas': FieldValue.increment(fichasBono),
          'xp': FieldValue.increment(xpBono),
          'badges': FieldValue.arrayUnion([badgeVecinoPreparado]),
          'mochilaPreparada': true,
        }, SetOptions(merge: true));

        // Registrar movimiento economico
        final movRef = userRef.collection('movimientos').doc();
        await movRef.set({
          'id': movRef.id,
          'uid': effectiveUid,
          'tipo': 'ingreso',
          'concepto': 'bonoMochila',
          'fichas': fichasBono,
          'xp': xpBono,
          'descripcion': 'Bono por completar la mochila de emergencia',
          'fecha': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // En modo offline se mantiene la persistencia local en prefs
      }
    }
  }
}

