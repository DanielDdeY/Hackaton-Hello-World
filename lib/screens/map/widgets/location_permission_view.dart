import 'package:flutter/material.dart';

import '../data/map_location_provider.dart';

/// Pantalla que bloquea el mapa hasta que el usuario concede su
/// ubicación (o activa el GPS / abre ajustes).
class LocationPermissionView extends StatelessWidget {
  const LocationPermissionView({
    super.key,
    required this.failure,
    required this.onAction,
    this.onSecondaryAction,
  });

  /// Motivo por el que no está disponible la ubicación.
  final LocationFailure failure;

  /// Acción principal del estado actual (pedir permiso, abrir ajustes…).
  final VoidCallback onAction;

  /// Acción secundaria opcional (volver a intentar).
  final VoidCallback? onSecondaryAction;

  String get _title => switch (failure) {
    LocationFailure.serviceDisabled => 'Activa tu ubicación',
    LocationFailure.permissionDenied => 'Permitimos tu ubicación',
    LocationFailure.permissionDeniedForever => 'Permiso bloqueado',
    LocationFailure.timeout => 'No pudimos obtener tu ubicación',
    LocationFailure.error => 'No pudimos obtener tu ubicación',
  };

  String get _message => switch (failure) {
    LocationFailure.serviceDisabled =>
      'Para mostrarte el mapa y los sitios de tu barrio necesitamos que '
          'actives el GPS del dispositivo.',
    LocationFailure.permissionDenied =>
      'Para limitar el mapa a los sitios de tu zona necesitamos conocer '
          'tu ubicación. Tus datos no salen del dispositivo.',
    LocationFailure.permissionDeniedForever =>
      'Has denegado el permiso de ubicación. Puedes concederlo de nuevo '
          'desde los ajustes de la app.',
    LocationFailure.timeout =>
      'La lectura de la ubicación tardó demasiado. Comprueba que el GPS '
          'esté activo y vuelve a intentarlo.',
    LocationFailure.error =>
      'No pudimos leer tu ubicación. Comprueba los permisos y vuelve a '
          'intentarlo.',
  };

  String get _actionLabel => switch (failure) {
    LocationFailure.serviceDisabled => 'Activar ubicación',
    LocationFailure.permissionDenied => 'Permitir ubicación',
    LocationFailure.permissionDeniedForever => 'Abrir ajustes',
    LocationFailure.timeout => 'Reintentar',
    LocationFailure.error => 'Reintentar',
  };

  IconData get _icon => switch (failure) {
    LocationFailure.serviceDisabled => Icons.gps_off_rounded,
    LocationFailure.permissionDenied => Icons.my_location_rounded,
    LocationFailure.permissionDeniedForever => Icons.block_rounded,
    LocationFailure.timeout => Icons.hourglass_bottom_rounded,
    LocationFailure.error => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(_actionLabel),
              ),
              if (onSecondaryAction != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSecondaryAction,
                  child: const Text('Volver a intentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
