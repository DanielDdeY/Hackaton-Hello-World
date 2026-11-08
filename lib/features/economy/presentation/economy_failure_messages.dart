import '../domain/models/economy_result.dart';

String economyFailureMessage(
  EconomyFailure failure,
) => switch (failure.reason) {
  EconomyFailureReason.noSession => 'Inicia sesión para confirmar.',
  EconomyFailureReason.selfConfirmation =>
    'No puedes confirmar tu propio servicio.',
  EconomyFailureReason.monthlyPairLimitReached =>
    'Ya recibiste XP por dos usos con este proveedor este mes.',
  EconomyFailureReason.invalidRating =>
    'Selecciona una calificación de 1 a 5 estrellas.',
  EconomyFailureReason.invalidOperation =>
    'No se pudo preparar la confirmación. Vuelve a abrirla.',
  EconomyFailureReason.operationConflict =>
    'Esta confirmación ya se usó con otros datos.',
  EconomyFailureReason.serviceNotFound => 'El servicio ya no está disponible.',
  EconomyFailureReason.inactiveService => 'Este servicio ya no está activo.',
  EconomyFailureReason.serviceNotDelivered =>
    'El proveedor debe marcar el trabajo como realizado antes de que confirmes.',
  EconomyFailureReason.userNotFound =>
    'Falta el perfil del cliente o del proveedor.',
  EconomyFailureReason.profileNotReady =>
    'El cliente y el proveedor deben sincronizar su perfil antes de confirmar.',
  EconomyFailureReason.futurePeriod => 'El periodo guardado es posterior al actual. Revisa la fecha del dispositivo.',
  EconomyFailureReason.networkUnavailable =>
    'Necesitas conexión para confirmar. Reintenta con la misma solicitud.',
  EconomyFailureReason.permissionDenied => 'No se pudo autorizar la confirmación. Actualiza la app o consulta al administrador.',
  EconomyFailureReason.simulationActive =>
    'Sal de la simulación para otorgar XP.',
  EconomyFailureReason.activityNotEligible =>
    'Esta participación todavía no cumple los requisitos para recibir XP.',
  EconomyFailureReason.unsupportedSource =>
    'Esta actividad todavía no otorga recompensas.',
  EconomyFailureReason.unavailable =>
    'No se pudo confirmar. Reintenta con la misma solicitud.',
};
