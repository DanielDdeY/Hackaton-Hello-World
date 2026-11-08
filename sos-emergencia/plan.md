# Plan de implementación: SOS vecinal con alerta geográfica

**Fecha**: 2026-11-07 | **Especificación**: [spec.md](./spec.md)

## Resumen

Convertir el SOS de demostración de la pantalla Inicio en un flujo real de un
toque. El toque crea una alerta geolocalizada, activa un círculo rojo de 500 m y
dispara notificaciones push mediante backend Firebase a vecinos con
consentimiento, token válido y ubicación reciente. Después de la activación, el
reportante completa el tipo, título, descripción y, opcionalmente, una foto. El
reporte se publica en la comunidad, vinculado al SOS, y las alertas activas se
representan en el mapa.

## Contexto técnico

- **Lenguaje/plataforma**: Flutter/Dart para Android, iOS y web; Functions del
  proyecto serán TypeScript/Node.
- **Dependencias actuales**: `firebase_core`, `cloud_firestore`,
  `geolocator`, `flutter_map`, `latlong2`, y proveedores de ubicación/foto
  inyectados para los formularios.
- **Código existente reutilizable**:
  - `lib/home/home.dart`: botón `confirmarSos()` actualmente simulado, perfil y
    accesos de Inicio.
  - `lib/features/create_post/presentation/forms/emergency/`: formulario y
    categorías de emergencia actuales; hoy no persiste.
  - `lib/screens/map/map_screen.dart`: GPS, mapa Flutter, capa circular,
    marcadores y stream repositorio mock.
  - `lib/screens/map/data/map_places_repository.dart`: patrón de repositorio
    stream para sustituir mocks.
  - `lib/screens/map/utils/map_geo.dart`: cálculo de distancia y radios para el
    mapa.
  - `lib/main.dart`: la pestaña Comunidad sigue mostrando un placeholder; debe
    conectarse a un feed real para que la publicación sea visible.
- **Firebase actual**: Firestore está en dependencias, pero no se encontró
  repositorio Firestore implementado, configuración de Functions ni reglas;
  FCM/Auth/Storage no están declarados. La configuración de Firebase del
  proyecto ya existe.
- **Arquitectura de propuesta**: repositorios Flutter sobre Firestore; Firebase
  Authentication para UID; Cloud Functions para geoconsulta y envío FCM seguro;
  Cloud Storage para fotos; stream autorizado del usuario para las alertas de
  mapa. La función usa consulta geohash aproximada y distancia exacta para
  seleccionar destinatarios.
- **Objetivo de rendimiento**: creación de alerta con confirmación visual en
  menos de 5 s; push a destinos elegibles en menos de 10 s en condiciones
  normales.
- **Restricciones**: no se marca una alerta como enviada si Firestore falla;
  no se exponen tokens ni coordenadas privadas a la comunidad; la imagen nunca
  se almacena como bytes en Firestore; los secretos de FCM viven solo en el
  backend.

## Revisión de principios

- **Seguridad y privacidad**: se requiere UID autenticado; la ubicación de
  receptores es voluntaria, reciente y no se comparte como dato público.
- **Fiabilidad**: el SOS mínimo se persiste antes de abrir el formulario largo;
  el formulario puede fallar sin eliminar la alerta; operaciones idempotentes
  evitan duplicados; la UI expresa error o envío pendiente.
- **Accesibilidad y rapidez**: color rojo se acompaña con texto/icono/semántica;
  el envío de foto y los detalles no bloquean la petición de auxilio.
- **Compatibilidad con el producto actual**: se conserva el inicio, mapa,
  proveedores de foto/ubicación y formularios existentes; se sustituyen
  componentes mock de forma incremental.
- No se encontró una constitución ni artefactos formales de arquitectura en el
  repositorio; las decisiones técnicas se basan en los módulos existentes
  inspeccionados y se registran como propuesta para confirmación.

## Guías aplicadas

No se encontraron guías de migración aplicables. Se reutilizan las convenciones
locales de providers, modelos y repositorios con streams.

## Modelo de persistencia propuesto

- `emergency_alerts/{alertId}`: `reporterUid`, `latitude`, `longitude`,
  `geohash`, `radiusMeters: 500`, `status` (`active`, `cancelled`, `resolved`),
  `createdAt`, `updatedAt`, `linkedPostId` y clave idempotente.
- `community_posts/{postId}`: tipo `emergency`, `alertId`, `authorUid`,
  `communityId` (distrito local), `emergencyType`, `title`, `description`,
  `photoPath?`, `approximateLocation`, `createdAt` y prioridad alta.
- `users/{uid}`: identidad y perfil mínimo del usuario, incluida la comunidad
  local verificada/configurada que controla qué feed puede leer.
- `users/{uid}/notification_devices/{deviceId}`: token FCM, plataforma y
  timestamps de actualización.
- `users/{uid}/alert_preferences/current`: consentimiento de proximidad,
  geohash/posición reciente y `locationUpdatedAt`. La ubicación se actualiza
  solo mientras el usuario usa la app, salvo futura aprobación explícita para
  segundo plano; caduca a los 15 minutos para elegibilidad de push.
- `users/{uid}/nearby_emergency_alerts/{alertId}`: proyección privada para el
  receptor elegible; permite que su mapa observe alertas sin exponer a todos
  los usuarios las ubicaciones exactas. Cloud Functions crea/cierra estas
  proyecciones.
- `incident_photos/{uid}/{alertId}/{fileId}` en Cloud Storage: objeto privado;
  reglas limitan carga por dueño, MIME, tamaño y lectura por receptores
  autorizados.

Las reglas de Firestore/Storage permiten crear/editar por dueño y leer solo las
proyecciones autorizadas; ninguna credencial administrativa se incluye en el
cliente. El feed comunitario del distrito expone ubicación aproximada, no tokens ni
ubicación privada de receptores.

## Pasos de implementación

### Fase 1: Fundamentos Firebase y seguridad

#### Paso 1.1: Configurar identidad y servicios Firebase

- **Requisitos**: REQ-001, REQ-004, REQ-008, REQ-009, REQ-010
- **Archivos**: `pubspec.yaml`, `lib/main.dart`, `lib/firebase_options.dart`,
  `firebase.json`, nuevo `firestore.rules`, nuevo `storage.rules`, nuevo
  `functions/package.json`, `functions/src/index.ts`
- **Descripción**: Habilitar Firebase Auth (Anonymous Auth como modo transitorio
  compatible con el onboarding demo), Cloud Messaging, Cloud Storage y Cloud
  Functions. Inicializar UID antes de crear SOS; sincronizar el distrito
  configurado con un perfil Firebase; registrar/renovar y borrar tokens FCM por
  dispositivo; pedir permisos push y consentimiento de alertas cercanas.
  Configurar reglas e índices seguros y una región acorde a usuarios en Perú;
  no incluir llaves FCM en el cliente.
- **Condición de despliegue**: confirmar disponibilidad de plan Firebase con
  Cloud Functions y credenciales APNs antes de validar pushes de producción.

### Fase 2: Historia P1 — Activar SOS de un toque

#### Paso 2.1: Implementar entidad y repositorio de alertas

- **Requisitos**: REQ-001, REQ-002, REQ-008, REQ-010
- **Archivos**: nuevos
  `lib/features/emergency/domain/emergency_alert.dart`,
  `lib/features/emergency/data/emergency_alert_repository.dart`,
  `lib/features/emergency/data/firebase_emergency_alert_repository.dart`
- **Descripción**: Crear y observar alertas Firestore con estado y clave
  idempotente; capturar ubicación, radio fijo de 500 m y timestamps del
  servidor. Implementar cancelación/resolución solo por creador. Modelar fallo,
  envío pendiente y éxito sin afirmar entrega antes de confirmación del servidor.

#### Paso 2.2: Cambiar el botón SOS del inicio al flujo real

- **Requisitos**: REQ-001, REQ-002
- **Archivos**: `lib/home/home.dart`, nuevos widgets/controladores bajo
  `lib/features/emergency/presentation/`
- **Descripción**: Sustituir `confirmarSos()` de demostración por activación
  inmediata de una alerta una vez verificada la posición. Deshabilitar toques
  repetidos mientras se crea el mismo intento. Mostrar estados visuales rojos
  con texto/icono y acción explícita para cancelar; abrir el formulario de
  detalles después de la creación. Si GPS/red falla, informar el error, mantener
  opción de reintento y ofrecer la llamada a un servicio oficial sin dar éxito
  falso.

### Fase 3: Historia P1 — Notificar vecinos cercanos

#### Paso 3.1: Gestionar consentimiento y ubicación reciente de receptores

- **Requisitos**: REQ-004, REQ-009, REQ-010
- **Archivos**: `pubspec.yaml`, nuevas clases en
  `lib/features/emergency/data/` y `lib/features/emergency/domain/`,
  `lib/main.dart`
- **Descripción**: Añadir Firebase Messaging y Auth en Flutter. Crear flujo
  explicativo de consentimiento, guardar preferencia y tokens bajo UID,
  actualizar posición/geohash solo durante uso activo de la app y retirar
  consentimiento/ubicación al desactivarlo. Caducar la elegibilidad de
  destinatarios después de 15 minutos.

#### Paso 3.2: Enviar push de forma segura dentro del radio

- **Requisitos**: REQ-003, REQ-004, REQ-009, REQ-010
- **Archivos**: `functions/src/index.ts`, `firestore.rules`,
  `firebase.json`, índices Firestore
- **Descripción**: Al crearse alerta, Cloud Function consulta perfiles por
  rangos geohash, excluye reportante y tokens inválidos, verifica consentimiento
  y actualidad de ubicación, aplica distancia geodésica exacta de 500 m y
  genera una proyección privada por receptor. Enviar FCM sin coordenadas
  exactas en texto. Al cancelar/resolver, actualizar proyecciones y mandar
  notificación de cierre. Registrar errores y limpiar tokens inválidos.

### Fase 4: Historia P1 — Completar y publicar el reporte

#### Paso 4.1: Ampliar el formulario de emergencia

- **Requisitos**: REQ-005
- **Archivos**: `lib/features/create_post/domain/entities/emergency_post_data.dart`,
  `lib/features/create_post/presentation/forms/emergency/emergency_form.dart`,
  `lib/features/create_post/presentation/forms/emergency/emergency_form_controller.dart`
- **Descripción**: Reutilizar el formulario existente, agregar título obligatorio,
  descripción concreta y categorías robo, accidente de tránsito, salud,
  incendio, sismo/desastre natural, violencia, persona desaparecida y otro.
  Mantener foto opcional y asociar la ubicación tomada por SOS, sin pedir
  dirección manual como sustituto silencioso de coordenadas.

#### Paso 4.2: Subir foto y persistir publicación comunitaria

- **Requisitos**: REQ-005, REQ-006, REQ-008, REQ-010
- **Archivos**: `pubspec.yaml`, nuevos repositorios en
  `lib/features/create_post/data/`, formulario de emergencia,
  nuevo `lib/features/community/presentation/community_feed_page.dart`,
  `lib/main.dart`, `storage.rules`, `firestore.rules`
- **Descripción**: Añadir Firebase Storage y subir foto opcional con límites de
  tamaño/tipo y ruta asociada a UID/alerta. Crear documento `community_posts`
  con categoría, título, descripción, `alertId`, `communityId` de distrito y
  ubicación pública aproximada; limitar lectura del feed/imagen a esa comunidad.
  Usar clave idempotente/estado de publicación para reintentar upload y
  Firestore sin duplicar; conservar alerta activa si falla esta etapa. Reemplazar
  el placeholder de la pestaña Comunidad por un feed conectado a Firestore,
  ordenar emergencias activas primero y mostrar sus tarjetas con estilo rojo,
  detalle y estado de carga/error/vacío.

### Fase 5: Historia P1 — Ver la emergencia en el mapa

#### Paso 5.1: Proveer alertas cercanas desde Firebase al mapa

- **Requisitos**: REQ-007, REQ-008, REQ-010
- **Archivos**: nuevos
  `lib/screens/map/data/emergency_map_repository.dart`,
  `lib/screens/map/data/firebase_emergency_map_repository.dart`,
  actualización de `lib/screens/map/map_screen.dart`
- **Descripción**: Observar la proyección privada de alertas del usuario
  autenticado; mapear estado y ubicación a un modelo de mapa, manejar
  cancelaciones y errores de stream, sin consultar ni dibujar alertas fuera de
  la zona permitida.

#### Paso 5.2: Dibujar círculo e icono rojos y permitir abrir el reporte

- **Requisitos**: REQ-003, REQ-007
- **Archivos**: `lib/screens/map/map_screen.dart`,
  `lib/screens/map/utils/map_geo.dart`,
  nuevos widgets de marcador/detalle en `lib/screens/map/widgets/`
- **Descripción**: Agregar círculo de 500 m por alerta activa con relleno rojo
  translúcido/borde rojo y marcador seleccionable con icono de peligro.
  El detalle muestra categoría, título, descripción, tiempo y foto si existe.
  Mantener separado el círculo local existente de 1.8 km y el filtro de sitios.
  Al recibir cancelación/resolución, retirar alerta de la capa activa.

### Fase 6: Pruebas y preparación operativa

#### Paso 6.1: Validar reglas, radio, FCM y fallos de extremo a extremo

- **Requisitos**: REQ-001 a REQ-010
- **Archivos**: pruebas nuevas en `test/features/emergency/`,
  `test/screens/map/`, `functions/test/`; reglas e índices Firebase
- **Descripción**: Probar activación sin diálogo, permisos/GPS/red, idempotencia,
  selecciones de categorías, foto opcional, Storage, autorización de UID, radio
  exacto de 500 m, destinatario vencido/fuera del radio, push con app cerrada,
  marker/círculo y cierre sincronizado. Añadir pruebas de integración con Firebase
  Emulator Suite y ejecutar análisis/test del cliente y backend.
- **Prueba manual**: dos dispositivos de prueba (uno dentro y otro fuera del
  radio), app receptora en background, un caso cancelado y un caso con foto.

## Desglose de tareas

### Fase 1: Fundamentos Firebase y seguridad

- [x] T001 [Plan:1.1] Configurar Firebase Auth/Anonymous Auth, Firebase Messaging y Storage en `pubspec.yaml`, `lib/main.dart` y `lib/firebase_options.dart`; sincronizar el distrito del perfil Firebase, documentar configuración por plataforma y no exponer secretos.
- [x] T002 [P] [Plan:1.1] Crear estructura base de Cloud Functions TypeScript en `functions/package.json` y `functions/src/index.ts`, configurar Functions en `firebase.json` y documentar región/deploy.
- [x] T003 [Plan:1.1] Definir reglas mínimas de Firestore y Storage en `firestore.rules` y `storage.rules` para UID dueño, comunidad local del distrito, tokens privados, ubicación con consentimiento e imágenes limitadas.

### Fase 2: US1 — Activar SOS de un toque

- [x] T004 [P] [US1] [Plan:2.1] Crear modelo `EmergencyAlert` en `lib/features/emergency/domain/emergency_alert.dart` con estado, ubicación, radio, timestamps y clave idempotente.
- [x] T005 [US1] [Plan:2.1] Implementar repositorio Firestore de alertas y cancelación/resolución autorizada en `lib/features/emergency/data/emergency_alert_repository.dart` y `firebase_emergency_alert_repository.dart`.
- [ ] T006 [US1] [Plan:2.2] (Parcial: falta una alternativa telefónica local configurable.) Reemplazar `confirmarSos()` en `lib/home/home.dart` por activación única con GPS, feedback rojo, formulario posterior, cancelación, reintentos y errores honestos.

### Fase 3: US2 — Avisar a vecinos

- [x] T007 [US2] [Plan:3.1] Implementar solicitud de consentimiento, token FCM y actualización/caducidad de ubicación opt-in en servicios de `lib/features/emergency/data/`.
- [x] T008 [US2] [Plan:3.2] Implementar función `onEmergencyAlertCreated` en `functions/src/index.ts` para filtrar por geohash y distancia geodésica de 500 m, excluir al reportante y generar proyecciones privadas por UID.
- [x] T009 [US2] [Plan:3.2] Enviar FCM seguro desde Cloud Functions, manejar tokens inválidos y propagar cancelación/resolución sin incluir coordenadas exactas en el texto push.

### Fase 4: US3 — Detallar y publicar

- [x] T010 [US3] [Plan:4.1] Ampliar `EmergencyPostData` y el formulario/controlador de `lib/features/create_post/` con ocho categorías, título, descripción y ubicación SOS.
- [x] T011 [US3] [Plan:4.2] Implementar subida opcional a Firebase Storage con validación de tamaño/MIME y reglas privadas usando el UID y la alerta.
- [x] T012 [US3] [Plan:4.2] Persistir `community_posts` en Firestore vinculado a `alertId` y `communityId` del distrito, con ubicación aproximada e idempotencia de reintentos; mostrar publicaciones prioritarias solo de la comunidad autenticada en `lib/features/community/presentation/community_feed_page.dart` conectada desde `lib/main.dart`.

### Fase 5: US4 — Ver y cerrar alertas en el mapa

- [x] T013 [US4] [Plan:5.1] Crear repositorio stream para `users/{uid}/nearby_emergency_alerts` e integrarlo con `MapScreen` sin sustituir el radio de 1.8 km de sitios.
- [x] T014 [US4] [Plan:5.2] Agregar círculos rojos de 500 m, iconos seleccionables de peligro y detalle de emergencia en `lib/screens/map/`.
- [x] T015 [US4] [Plan:5.1,5.2] Sincronizar cancelación/resolución para retirar marcador y círculo activos y mostrar su estado final en el detalle.

### Fase 6: Validación

- [ ] T016 [US1,US2,US3,US4] [Plan:6.1] Añadir pruebas unitarias/widget de flujo, categorías, fallos e idempotencia en `test/features/emergency/` y `test/screens/map/`.
- [ ] T017 [US1,US2,US3,US4] [Plan:6.1] Añadir pruebas de Cloud Functions y reglas con Firebase Emulator Suite en `functions/test/` y ejecutar `flutter test`, `flutter analyze` y pruebas backend.
- [ ] T018 [US2,US4] [Plan:6.1] Validar manualmente entrega push con app cerrada, radio dentro/fuera de 500 m, cancelación y flujo de foto en dos dispositivos de prueba.

## Estado de ejecución

- Implementados en código: T001-T005 y T007-T015.
- T006 está parcial: activación GPS, persistencia idempotente, formulario,
  errores y cancelación funcionan en código; falta una alternativa telefónica
  local configurable.
- T016 tiene pruebas de modelo, mapa y distancia geodésica, pero falta cobertura
  de Firestore, reglas, fallos de red y reintentos.
- T017 y T018 dependen de Firebase Emulator Suite y dispositivos/configuración
  reales, respectivamente; no se marcaron como completados.
- No se desplegaron reglas, índices ni Functions al proyecto Firebase.

## Estructura prevista

```text
functions/
  src/index.ts
  test/
firestore.rules
storage.rules
firebase.json
lib/
  features/emergency/
    data/
    domain/
    presentation/
  features/create_post/
    domain/entities/emergency_post_data.dart
    presentation/forms/emergency/
  features/community/
    presentation/community_feed_page.dart
  home/home.dart
  screens/map/
    data/
    widgets/
    map_screen.dart
test/
  features/emergency/
  screens/map/
```

## Estrategia de validación

- **Tipo de app**: app móvil Flutter con mapa y servicios Firebase.
- **Flujos críticos**: activar en un toque; recibir notificación con app cerrada;
  completar reporte/foto; ver la emergencia en el mapa; cancelar/resolver.
- **Stack de prueba**: `flutter_test`, Firebase Emulator Suite para Firestore,
  Storage y Functions; pruebas con dispositivos reales/emuladores para FCM y
  permisos de SO.
- **Matriz de fallback**: FCM de producción → pruebas de Functions con emulador
  más verificación manual en dispositivos; GPS real → proveedor de ubicación
  falso en pruebas.
- **Entorno**: proyecto Firebase con Firestore, Authentication, FCM, Storage,
  Functions, índices/reglas desplegables; credenciales APNs para validar iOS;
  Android/iOS de prueba con dos perfiles.
- **Gaps conocidos**: FCM de producción y permisos push no quedan plenamente
  validados por tests widget; requieren dispositivo y configuración de proyecto.
- **Datos de prueba**: dos UID aislados, posiciones de 499 m y 501 m, alertas
  con ID determinístico por test, limpiar usuarios, tokens y Storage al terminar.
- **Aceptación**: sin falsos éxitos, sin duplicados al reintentar, sólo push al
  receptor dentro del radio y con consentimiento/ubicación reciente, reglas
  niegan lectura/escritura ajena, y mapa retira al cerrar.
- **Revisión final**: verificar no hay secretos en cliente, tokens/ubicaciones
  privados, errores de GPS/red visibles y categoría/foto opcional no impiden el
  SOS inicial.

## Riesgos y dependencias externas

1. **Autenticación**: el onboarding actual es una demostración local basada en
   `SharedPreferences`; debe confirmarse Firebase Anonymous Auth o la autenticación
   definitiva antes de producción.
2. **Cloud Functions**: hay que habilitar Functions y confirmar el plan de
   facturación/ubicación del proyecto Firebase; FCM no debe ser enviado por el
   cliente.
3. **Ubicación de receptores**: el radio requiere consentimiento y una
   ubicación actualizada durante el uso de la app. Sin ubicación reciente, el
   sistema no puede garantizar que el vecino sigue dentro del radio cuando la
   app está cerrada.
4. **Plataformas push**: configurar APNs y permisos para iOS; web requiere
   service worker/clave VAPID si se incluye en el alcance.
5. **Seguridad de mapa/feed**: no exponer coordenadas exactas, tokens o
   ubicaciones de usuario a lecturas globales del cliente; entregar
   proyecciones por UID y filtrar publicaciones por comunidad local autenticada.

## Mapeo de requisitos

| REQ ID | Descripción | Pasos | Evidencia |
|---|---|---|---|
| REQ-001 | Activar SOS inmediato con una pulsación | 1.1, 2.1, 2.2, 6.1 | `home.dart`, modelo y repositorio de alerta, pruebas de flujo |
| REQ-002 | Mostrar estado/error y evitar duplicados | 2.1, 2.2, 6.1 | repositorio/estado SOS y pruebas de reintento |
| REQ-003 | Radio rojo de 500 m y alcance geográfico | 3.2, 5.2, 6.1 | Cloud Function, `map_screen.dart`, pruebas 499/501 m |
| REQ-004 | Enviar push seguro a vecinos elegibles | 1.1, 3.1, 3.2, 6.1 | FCM, `functions/src/index.ts`, pruebas de Functions |
| REQ-005 | Capturar categoría, título, descripción y foto opcional | 4.1, 4.2, 6.1 | `EmergencyPostData`, formulario y pruebas |
| REQ-006 | Publicar y mostrar en el feed comunitario vinculado al SOS | 4.2, 6.1 | repositorio `community_posts`, `CommunityFeedPage` y pruebas |
| REQ-007 | Ver, seleccionar y cerrar alertas en mapa | 5.1, 5.2, 6.1 | repositorio mapa, capas/marker y pruebas de estado |
| REQ-008 | Persistir alerta, reporte e imagen en Firebase | 1.1, 2.1, 4.2, 5.1 | Firestore/Storage repositorios, reglas y pruebas emulator |
| REQ-009 | Respetar consentimiento y vigencia de ubicación | 1.1, 3.1, 3.2, 6.1 | preferencias, timestamp/TTL, pruebas de destinatarios |
| REQ-010 | Aplicar autorización de Firebase y protección de datos | 1.1, 2.1, 3.2, 4.2, 6.1 | reglas Firestore/Storage y pruebas con UID |
