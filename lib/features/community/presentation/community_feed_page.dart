import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  late final Future<String> _communityId = _resolveCommunity();

  Future<String> _resolveCommunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final profile = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await profile.get();
    final savedDistrict = snapshot.data()?['communityId'] as String?;
    if (savedDistrict != null && savedDistrict.trim().isNotEmpty) {
      return savedDistrict;
    }

    final preferences = await SharedPreferences.getInstance();
    final district =
        preferences.getString('vecino_distrito')?.trim().toLowerCase() ?? '';
    if (district.isEmpty) return '';
    await profile.set({'communityId': district}, SetOptions(merge: true));
    return district;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _communityId,
    builder: (context, communitySnapshot) {
      if (communitySnapshot.hasError) {
        return const _FeedMessage(
          icon: Icons.cloud_off_outlined,
          message: 'No se pudo cargar tu comunidad. Revisa tu conexión.',
        );
      }
      if (!communitySnapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final communityId = communitySnapshot.data!;
      if (communityId.isEmpty) {
        return const _FeedMessage(
          icon: Icons.location_city_outlined,
          message: 'Completa tu distrito en el perfil para ver la comunidad.',
        );
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return const _FeedMessage(
          icon: Icons.lock_outline,
          message: 'Inicia sesión para ver las alertas de tu zona.',
        );
      }
      final alerts = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('nearby_emergency_alerts')
          .where('status', isEqualTo: 'active')
          .snapshots();
      final ownAlerts = FirebaseFirestore.instance
          .collection('emergency_alerts')
          .where('reporterUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .snapshots();
      return Column(
        children: [
          _NearbyAlertsConsent(communityId: communityId),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: alerts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _FeedMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'No se pudieron cargar las alertas cercanas.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: ownAlerts,
                  builder: (context, ownSnapshot) {
                    if (ownSnapshot.hasError) {
                      return const _FeedMessage(
                        icon: Icons.cloud_off_outlined,
                        message: 'No se pudieron cargar tus alertas SOS.',
                      );
                    }
                    if (!ownSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final byId = <String, Map<String, dynamic>>{
                      for (final document in snapshot.data!.docs)
                        document.id: {
                          ...document.data(),
                          'alertId': document.id,
                          'category': 'emergency',
                        },
                      for (final document in ownSnapshot.data!.docs)
                        document.id: {
                          ...document.data(),
                          'alertId': document.id,
                          'category': 'emergency',
                          'detailsPending': false,
                        },
                    };
                    final posts = byId.values.toList()
                      ..sort((a, b) {
                        final aDate = a['createdAt'] as Timestamp?;
                        final bDate = b['createdAt'] as Timestamp?;
                        return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
                          aDate?.millisecondsSinceEpoch ?? 0,
                        );
                      });
                    if (posts.isEmpty) {
                      return const _FeedMessage(
                        icon: Icons.notifications_none_outlined,
                        message:
                            'Aún no hay alertas SOS activas a menos de 200 m.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: posts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _CommunityPostCard(data: posts[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

class _NearbyAlertsConsent extends StatefulWidget {
  const _NearbyAlertsConsent({required this.communityId});

  final String communityId;

  @override
  State<_NearbyAlertsConsent> createState() => _NearbyAlertsConsentState();
}

class _NearbyAlertsConsentState extends State<_NearbyAlertsConsent>
    with WidgetsBindingObserver {
  static const _alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

  bool get _pushSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  DocumentReference<Map<String, dynamic>>? get _profile {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(uid);
  }

  StreamSubscription<String>? _tokenSubscription;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshIfEnabled());
  }

  Future<void> _refreshIfEnabled() async {
    if (_updating) return;
    final profile = _profile;
    if (profile == null) return;
    setState(() => _updating = true);
    try {
      final snapshot = await profile.get();
      if (snapshot.data()?['proximityEnabled'] == true) {
        await _registerLocationAndToken();
      }
    } on FirebaseException catch (error) {
      _showError('No se pudo actualizar tu ubicación (${error.code}).');
    } on StateError catch (error) {
      _showError(error.message.toString());
    } on Exception catch (error) {
      _showError('No se pudo actualizar tu ubicación: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _toggle(bool enabled) async {
    if (_updating) return;
    if (!enabled) {
      final profile = _profile;
      if (profile == null) return;
      setState(() => _updating = true);
      try {
        await profile.update({
          'proximityEnabled': false,
          'location': FieldValue.delete(),
          'geohash': FieldValue.delete(),
          'locationUpdatedAt': FieldValue.delete(),
          'fcmToken': FieldValue.delete(),
        });
        await _tokenSubscription?.cancel();
        _tokenSubscription = null;
      } on FirebaseException catch (error) {
        _showError('No se pudo desactivar el aviso (${error.code}).');
      } on StateError catch (error) {
        _showError(error.message.toString());
      } finally {
        if (mounted) setState(() => _updating = false);
      }
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alertas vecinales cercanas'),
        content: const Text(
          'Si aceptas, guardaremos tu ubicación mientras usas la app y '
          'enviaremos una notificación cuando ocurra un SOS a menos de 200 m. '
          'Tu ubicación exacta no se muestra en la comunidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Acepto y activar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    if (_profile == null) {
      _showError('No hay una sesión Firebase activa. Vuelve a ingresar.');
      return;
    }
    setState(() => _updating = true);
    try {
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        throw StateError('Permite las notificaciones para activar el aviso.');
      }
      await _registerLocationAndToken();
      await _tokenSubscription?.cancel();
      final profile = _profile!;
      // Admin Messaging needs the FCM token; onRegistered emits an FID instead.
      // ignore: deprecated_member_use
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => _saveRefreshedToken(profile, token),
        onError: (Object error) =>
            _showError('No se pudo renovar el token de notificaciones: $error'),
      );
    } on FirebaseException catch (error) {
      _showError('Firebase no pudo activar los avisos (${error.code}).');
    } on StateError catch (error) {
      _showError(error.message.toString());
    } on Exception catch (error) {
      _showError('No se pudieron activar los avisos: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _saveRefreshedToken(
    DocumentReference<Map<String, dynamic>> profile,
    String token,
  ) async {
    try {
      await profile.update({'fcmToken': token});
    } on FirebaseException catch (error) {
      _showError(
        'No se pudo renovar el token de notificaciones (${error.code}).',
      );
    }
  }

  Future<void> _registerLocationAndToken() async {
    final profile = _profile;
    if (profile == null) {
      throw StateError('No hay una sesión Firebase activa.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Activa el GPS para recibir alertas cercanas.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Permite el acceso a la ubicación para continuar.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    // Firebase Admin sends to the registration token, not the FID.
    // ignore: deprecated_member_use
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      throw StateError(
        'No se pudo registrar el dispositivo para notificaciones push.',
      );
    }
    await profile.set({
      'communityId': widget.communityId,
      'proximityEnabled': true,
      'location': GeoPoint(position.latitude, position.longitude),
      'geohash': _geohash(position.latitude, position.longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  String _geohash(double latitude, double longitude) {
    var latMin = -90.0;
    var latMax = 90.0;
    var lonMin = -180.0;
    var lonMax = 180.0;
    var evenBit = true;
    var bits = 0;
    var hashValue = 0;
    final result = StringBuffer();
    while (result.length < 9) {
      if (evenBit) {
        final midpoint = (lonMin + lonMax) / 2;
        if (longitude >= midpoint) {
          hashValue = (hashValue << 1) | 1;
          lonMin = midpoint;
        } else {
          hashValue <<= 1;
          lonMax = midpoint;
        }
      } else {
        final midpoint = (latMin + latMax) / 2;
        if (latitude >= midpoint) {
          hashValue = (hashValue << 1) | 1;
          latMin = midpoint;
        } else {
          hashValue <<= 1;
          latMax = midpoint;
        }
      }
      evenBit = !evenBit;
      if (++bits == 5) {
        result.write(_alphabet[hashValue]);
        bits = 0;
        hashValue = 0;
      }
    }
    return result.toString();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_pushSupported) {
      return const Card(
        margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ListTile(
          title: Text(
            'Las alertas push no están disponibles en esta plataforma.',
          ),
        ),
      );
    }
    final profile = _profile;
    if (profile == null) {
      return const Card(
        margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ListTile(
          title: Text('Inicia sesión en Firebase para recibir alertas.'),
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profile.snapshots(),
      builder: (context, snapshot) {
        final enabled = snapshot.data?.data()?['proximityEnabled'] == true;
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          color: const Color(0xfffff1f0),
          child: SwitchListTile(
            value: enabled,
            onChanged: _updating ? null : _toggle,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xffb71c1c),
            ),
            title: const Text('Recibir alertas SOS a 200 m'),
            subtitle: Text(
              _updating
                  ? 'Actualizando…'
                  : 'Solo con tu consentimiento y ubicación reciente.',
            ),
          ),
        );
      },
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isEmergency = data['category'] == 'emergency';
    final emergencyStatus = data['status'] as String? ?? 'active';
    final isActive = emergencyStatus == 'active';
    final theme = Theme.of(context);
    final photoPath = data['photoPath'] as String?;
    final description = data['description'] as String? ?? '';
    final type = data['emergencyType'] as String? ?? 'Emergencia';
    final detailsPending = data['detailsPending'] == true;
    return Card(
      color: isEmergency && isActive ? const Color(0xfffff1f0) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isEmergency && isActive
            ? const BorderSide(color: Color(0xffc62828), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEmergency)
              Row(
                children: [
                  Icon(
                    isActive ? Icons.warning_rounded : Icons.info_outline,
                    color: isActive
                        ? const Color(0xffb71c1c)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isActive ? 'EMERGENCIA' : _statusLabel(emergencyStatus)} · ${type.toUpperCase()}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isActive
                          ? const Color(0xffb71c1c)
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (isEmergency) const SizedBox(height: 8),
            Text(
              data['title'] as String? ?? 'Alerta SOS cercana',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (detailsPending) ...[
              const SizedBox(height: 6),
              const Text(
                'El vecino está completando los detalles del reporte.',
                style: TextStyle(color: Color(0xffb71c1c)),
              ),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            if (photoPath != null) ...[
              const SizedBox(height: 12),
              _PrivatePhoto(path: photoPath),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'cancelled' => 'SOS CANCELADO',
    'resolved' => 'SOS RESUELTO',
    _ => 'SOS',
  };
}

class _PrivatePhoto extends StatelessWidget {
  const _PrivatePhoto({required this.path});

  final String path;

  Future<Uint8List?> _load() =>
      FirebaseStorage.instance.ref(path).getData(5 * 1024 * 1024);

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _load(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text('No se pudo cargar la foto del reporte.');
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    },
  );
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
