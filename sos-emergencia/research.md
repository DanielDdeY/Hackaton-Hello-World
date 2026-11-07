# Investigación y decisiones: SOS vecinal

## Decisiones confirmadas por el usuario

- **Radio: 500 metros.** Se usa tanto para elegibilidad de notificaciones como
  para el círculo rojo del mapa; el backend aplicará distancia geodésica exacta
  después de prefiltrar posiciones con geohash.
- **Notificaciones: push Firebase, aunque la app esté cerrada.** Requiere
  Firebase Cloud Messaging, token por dispositivo y envío confiable desde Cloud
  Functions; no se enviarán pushes desde el cliente.
- **Foto: opcional.** El SOS y el reporte no quedan bloqueados si la persona no
  puede tomar una foto.

## Hallazgos del código actual

- `lib/home/home.dart`: SOS abre un diálogo de simulación y no persiste.
- `lib/features/create_post/presentation/forms/emergency/`: hay categorías
  básicas, dirección, mensaje y selección de foto, pero el formulario no
  persiste ni recoge un título.
- `lib/screens/map/map_screen.dart`: el mapa usa datos mock para lugares, ya
  obtiene ubicación y muestra un círculo de 1.8 km; se pueden agregar streams,
  marcadores y círculos de emergencias sin reemplazar ese límite de lugares.
- `lib/main.dart`: la pestaña Comunidad es un placeholder; se requiere un feed
  para que “publicado en comunidad” sea observable, además del documento en
  Firestore. Se asume que el feed es de la comunidad local del distrito, no
  público global.
- Firebase Core y Cloud Firestore ya aparecen en dependencias; no se encontró
  uso de Firestore en estos flujos, reglas de Firestore/Storage, Cloud Functions,
  Firebase Auth, FCM ni Storage.
- El onboarding actual es demo y conserva el perfil en `SharedPreferences`.
  Como propuesta temporal se incluye Firebase Anonymous Auth, con un bloqueo de
  decisión antes de producción para escoger la autenticación definitiva.

## Supuestos técnicos por validar durante implementación

- Un receptor es elegible solo si aceptó alertas, tiene token push vigente y
  reportó posición mientras usaba la app en los últimos 15 minutos. No se
  agrega rastreo de fondo sin consentimiento explícito adicional.
- El mapa consulta una proyección privada por usuario, en vez de conceder a
  todos los clientes lectura de todas las coordenadas SOS.
- Cloud Functions/Storage y las credenciales de plataforma se deben habilitar en
  el proyecto Firebase; iOS requiere configurar APNs. La disponibilidad de
  Functions y su facturación debe comprobarse antes del despliegue.

## Implementación aplicada

- El botón SOS crea `emergency_alerts/{id}` con ubicación GPS actual, radio de
  500 m, distrito y estado activo; conserva el identificador de reintento en
  preferencias locales para no duplicar una solicitud fallida.
- Firebase Anonymous Auth, Firestore, Storage y Messaging están conectados desde
  Flutter. El feed ofrece consentimiento para ubicación/avisos; la posición
  elegible se actualiza al habilitar avisos y al volver a abrir la app. No hay
  rastreo en segundo plano.
- `functions/src/index.ts` filtra candidatos por distrito y rangos geohash,
  comprueba distancia exacta y ubicación de máximo 15 minutos, crea
  proyecciones privadas y envía FCM sin coordenadas en el texto.
- El formulario publica categorías, título, descripción y foto opcional; las
  fotos de hasta 5 MB se cargan como bytes a Storage y se leen bajo reglas, sin
  guardar una URL de descarga pública en Firestore.
- La comunidad y el mapa se conectan a Firestore; el mapa representa el SOS con
  marcador y círculo rojo de 500 m. Cancelación/resolución actualiza las
  proyecciones desde Functions.

## Pasos requeridos antes de usarlo con Firebase real

1. En Firebase Console, habilitar el proveedor **Anonymous** en Authentication;
   crear Firestore y Storage si aún no existen.
2. Confirmar el plan de facturación que habilita Cloud Functions y desplegar
   reglas, índices y Functions desde la raíz:
   `firebase deploy --only firestore:rules,firestore:indexes,storage,functions`.
3. Configurar APNs para iOS; para web, configurar VAPID y el service worker de
   Firebase Messaging. No se inventaron ni añadieron credenciales.
4. Completar la política de consentimiento y retención antes de producción.
5. Verificar la pertenencia al distrito y habilitar App Check/limitación de
   frecuencia; el distrito del onboarding actual sigue siendo autodeclarado.

El despliegue a la nube y la prueba en dos dispositivos no se ejecutaron.
