export function emergencyAlertProjection(
  alertId: string,
  alert: Record<string, unknown>,
  createdAt: unknown,
): Record<string, unknown> {
  const detailsPending = !alert.title &&
    !alert.description &&
    !alert.emergencyType &&
    !alert.photoPath;
  return {
    alertId,
    location: alert.location,
    radiusMeters: 200,
    status: "active",
    title: alert.title ?? "Alerta SOS cercana",
    description: alert.description ?? "",
    emergencyType: alert.emergencyType ?? "emergency",
    photoPath: alert.photoPath ?? null,
    detailsPending,
    createdAt,
  };
}
