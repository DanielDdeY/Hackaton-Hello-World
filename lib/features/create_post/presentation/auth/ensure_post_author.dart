import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/services/auth_gateway.dart';

Future<bool> ensurePostAuthor(BuildContext context) async {
  try {
    final gateway = context.read<AuthGateway?>();
    if (gateway == null) throw const AuthFailure(AuthFailureReason.unavailable);
    await gateway.ensureSignedIn();
    return context.mounted;
  } on AuthFailure catch (error) {
    if (context.mounted) {
      final message = switch (error.reason) {
        AuthFailureReason.noConnection =>
          'Sin conexión. Conéctate y vuelve a tocar Publicar.',
        AuthFailureReason.anonymousDisabled =>
          'El acceso anónimo no está habilitado. Intenta publicar más tarde.',
        AuthFailureReason.cancelled => 'Inicio de sesión cancelado.',
        AuthFailureReason.invalidCode ||
        AuthFailureReason.tooManyRequests =>
          'No se pudo iniciar sesión. Vuelve a tocar Publicar.',
        AuthFailureReason.unavailable =>
          'No se pudo iniciar sesión. Vuelve a tocar Publicar.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    return false;
  }
}
