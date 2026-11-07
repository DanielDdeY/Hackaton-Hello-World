# Lista de calidad: SOS vecinal

## Cobertura de requisitos

- [x] Los requisitos tienen identificadores únicos REQ-XXX.
- [x] Los requisitos cubren activación, notificación, detalle, comunidad, mapa,
  persistencia y seguridad.
- [x] Cada requisito tiene evidencia verificable en escenarios o criterios.

## Claridad y límites

- [x] Radio confirmado: 500 metros.
- [x] Notificación confirmada: push FCM, incluso con la app cerrada.
- [x] Foto confirmada: opcional.
- [x] Ubicación reciente y consentimiento están definidos como condiciones de
  elegibilidad.
- [x] El flujo distingue activar la alarma de completar el reporte.
- [x] La publicación se limita a la comunidad local del distrito, no a un feed
  público global.

## Dependencias por resolver antes de producción

- [ ] Confirmar autenticación técnica: Firebase Anonymous Auth para el demo o
  autenticación definitiva de la app.
- [ ] Habilitar/desplegar Cloud Functions, FCM, Cloud Storage y reglas de
  Firestore/Storage en el proyecto Firebase.
- [ ] Configurar credenciales push de APNs para iOS y revisar la configuración
  por plataforma; para web, configurar VAPID y el service worker.
- [ ] Verificar el distrito/perfil, habilitar App Check y definir límites contra
  alertas abusivas antes de producción.
- [ ] Acordar política de privacidad y retención de ubicación/alertas para
  usuarios reales.

## Ejecución del plan

- [x] Flujo SOS, persistencia Firestore, reporte de emergencia y feed comunitario
  conectados en el cliente.
- [x] Cloud Functions para elegibilidad geográfica, notificaciones y cierre;
  reglas Firestore/Storage e índices añadidos al repositorio.
- [x] Círculo e icono SOS de 500 m conectados al stream privado del mapa.
- [x] Análisis Dart y pruebas enfocadas de mapa/modelo; compilación y pruebas de
  distancia de Cloud Functions.
- [ ] Pruebas con Firebase Emulator Suite para reglas, Functions, idempotencia y
  fallos de red.
- [ ] Despliegue Firebase y validación push/foto en dos dispositivos.
- [ ] Definir número de emergencia local para mostrar como alternativa cuando no
  hay GPS o conexión.
