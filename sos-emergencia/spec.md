# Especificación: SOS vecinal con alerta geográfica

**Fecha**: 2026-11-07 | **Estado**: Lista para planificación  
**Entrada**: Solicitud del usuario y decisiones confirmadas para radio, push y foto

## Alcance

- **Método de descubrimiento**: inspección de la pantalla de inicio, el botón SOS
  actual, el formulario de emergencias, la pantalla de mapa, los repositorios de
  mapa y la configuración Firebase.
- **Componentes relevantes descubiertos**: 5 (SOS del inicio, formulario de
  emergencia, mapa, configuración Firebase y publicación comunitaria).
- **Componentes en alcance**: 5. Se limita el cambio a activar SOS, describir y
  publicar incidentes, avisar a vecinos cercanos y representar alertas en el
  mapa.

El botón SOS existente solo muestra una confirmación de demostración. La app ya
tiene un formulario con categorías básicas, ubicación/dirección y foto, además
de mapa con posición GPS y radio visual de 1.8 km. La pestaña Comunidad todavía
es un placeholder y no existe un feed persistido. Firebase Core y Cloud
Firestore están declarados, pero no se encontró autenticación Firebase,
Firebase Cloud Messaging, Cloud Storage, Cloud Functions ni una implementación
Firebase del repositorio de mapa.

## Escenarios de usuario y pruebas

### Historia 1: Pedir auxilio de inmediato (Prioridad: P1)

Como vecino en una emergencia, quiero activar el SOS con una sola pulsación para
que se registre mi ubicación actual y se avise a vecinos cercanos sin tener que
completar primero un formulario.

**Por qué es P1**: la rapidez de la alerta puede ser decisiva; el texto y la foto
no deben bloquear la activación.

**Prueba independiente**: con ubicación disponible y conectividad, pulsar SOS
una vez produce un registro activo, abre la captura de detalles y no presenta
un diálogo de confirmación.

**Escenarios de aceptación**:

1. **Dado** que el usuario concedió ubicación y tiene conexión, **cuando** pulsa
   SOS una vez, **entonces** se registra una alerta activa con hora y posición,
   se muestra su estado y comienza el envío a los destinatarios cercanos.
2. **Dado** que la ubicación no está disponible, **cuando** pulsa SOS,
   **entonces** la app informa que no pudo determinar la zona y ofrece una
   alternativa de ayuda telefónica; no muestra que la alerta fue enviada.
3. **Dado** que no hay conexión, **cuando** intenta activar SOS, **entonces** la
   app distingue claramente entre pendiente y enviado y permite reintentar sin
   duplicar la alerta.
4. **Dado** que el usuario activó SOS por error, **cuando** cancela la alerta,
   **entonces** se actualiza su estado y se comunica la cancelación a quienes
   recibieron el aviso.

### Historia 2: Describir el incidente y publicarlo (Prioridad: P1)

Como persona que activó SOS, quiero completar qué pasó, dónde y cómo ayudar,
para que la comunidad reciba información útil sin retrasar la alerta inicial.

**Prueba independiente**: después de activar SOS, seleccionar categoría,
completar título y descripción, agregar opcionalmente una foto y enviar; verificar
el registro comunitario y el vínculo a la alerta.

**Escenarios de aceptación**:

1. **Dado** un SOS activo, **cuando** el usuario completa el formulario,
   **entonces** puede elegir robo, accidente de tránsito, salud/urgencia médica,
   incendio, sismo/desastre natural, violencia, persona desaparecida u otro.
2. **Dado** un tipo elegido, **cuando** el usuario escribe el título y la
   descripción y decide enviar, **entonces** el aviso aparece en la comunidad
   como emergencia prioritaria en la pestaña Comunidad y enlazado al SOS
   correspondiente, visible solo en la comunidad local del distrito.
3. **Dado** que el usuario no puede o no quiere tomar una foto, **cuando**
   publica, **entonces** el texto y la alerta se envían sin foto.
4. **Dado** que la foto o publicación falla, **cuando** se reintenta,
   **entonces** no se duplica el SOS ni la publicación y se muestra qué parte
   requiere reintento.

### Historia 3: Ubicar y atender alertas cercanas (Prioridad: P1)

Como vecino que aceptó recibir alertas de proximidad, quiero recibir una
notificación aunque la app esté cerrada y ver en el mapa dónde está ocurriendo
la emergencia para decidir cómo ayudar.

**Prueba independiente**: con dos usuarios de prueba con ubicación reciente y
notificaciones habilitadas, activar un SOS y comprobar la entrega al usuario
dentro de 500 m, la ausencia de aviso al usuario fuera del radio y el marcador
en el mapa.

**Escenarios de aceptación**:

1. **Dado** un usuario que aceptó alertas y cuya ubicación reportada
   recientemente está a 500 m o menos, **cuando** se activa un SOS,
   **entonces** recibe una notificación push que puede abrir la alerta en el mapa.
2. **Dado** un usuario fuera de 500 m, sin permiso de notificaciones o con
   ubicación vencida, **cuando** se activa el SOS, **entonces** no se le envía
   una notificación de proximidad.
3. **Dado** un SOS activo visible para un destinatario autorizado, **cuando**
   abre el mapa, **entonces** ve un círculo rojo de 500 m y un marcador/icono de
   peligro seleccionable.
4. **Dado** que el SOS se cancela o se resuelve, **cuando** el mapa recibe el
   cambio, **entonces** deja de mostrarlo como peligro activo y los destinatarios
   reciben la actualización correspondiente.

## Casos límite

- Permiso de ubicación denegado, servicio GPS apagado o posición imprecisa.
- Falta de red al crear la alerta, mientras se completa el formulario o al
  subir la foto.
- Toques repetidos durante el envío: un solo SOS activo por pulsación/solicitud.
- Token push inválido, permiso de notificaciones denegado o ausencia de
  destinatarios elegibles.
- Usuario que reporta la emergencia no debe recibir su propia notificación.
- Foto demasiado grande o tipo de archivo no permitido.
- La alerta se cancela mientras otro usuario la tiene abierta.
- Usuario sin autenticación Firebase o perfil sin consentimiento/ubicación
  reciente.
- Alertas cercanas a los bordes del radio: decidir elegibilidad por distancia
  geodésica exacta, no solo por celdas aproximadas.
- Ninguna notificación debe incluir datos personales o coordenadas exactas en
  texto visible de la pantalla bloqueada.

## Requisitos

### Requisitos funcionales

- **REQ-001**: Una única pulsación en SOS debe intentar crear inmediatamente
  una alerta activa usando la ubicación actual; no debe exigir confirmar en un
  diálogo ni completar primero los detalles.
- **REQ-002**: La interfaz debe distinguir los estados pendiente de envío,
  enviada, cancelada/resuelta y error. Los reintentos no deben crear alertas
  duplicadas; una activación sin posición válida no debe reportarse como enviada.
- **REQ-003**: El radio predeterminado de alerta y notificación es 500 m medidos
  desde la posición de la emergencia; el mapa debe mostrar su límite en rojo.
- **REQ-004**: El envío push debe llegar con la app cerrada a usuarios que hayan
  aceptado recibir alertas, tengan token push válido y ubicación reciente dentro
  del radio; excluir al reportante y evitar filtrar coordenadas en el texto push.
- **REQ-005**: Después de crear el SOS, la persona debe poder registrar categoría,
  título y descripción, con foto opcional; las categorías incluyen robo,
  accidente de tránsito, salud, incendio, sismo/desastre natural, violencia,
  persona desaparecida y otro.
- **REQ-006**: Publicar los detalles en el feed comunitario como contenido
  prioritario de emergencia, visible en la pestaña Comunidad solo para la
  comunidad local del distrito, vinculado a la alerta SOS y sin crear duplicados
  al reintentar.
- **REQ-007**: El mapa debe mostrar las alertas activas autorizadas con un icono
  de peligro seleccionable, círculo rojo de 500 m y acceso al detalle; debe
  actualizarse al cancelar o resolver una alerta.
- **REQ-008**: Los registros de alerta, publicación y metadatos de imagen deben
  persistir en Firebase; las imágenes deben almacenarse separadas del documento
  y respetar las reglas de acceso.
- **REQ-009**: La lectura de ubicación para recibir alertas requiere consentimiento
  explícito, debe excluir ubicaciones vencidas y permitir retirar consentimiento.
- **REQ-010**: Solo el creador puede cancelar/resolver su alerta; las reglas de
  Firebase deben impedir crear/editar alertas en nombre de otros usuarios y
  acceder a tokens o ubicaciones privadas de terceros.

### Entidades principales

- **SOS activo**: identificador, reportante, coordenadas, geohash, radio,
  estado, marcas de tiempo, ID de publicación opcional y referencia a
  destinatarios/dispatches.
- **Reporte comunitario de emergencia**: identificador, alerta vinculada,
  categoría, título, descripción, referencia de foto, creador, ubicación
  aproximada para la comunidad y fecha de publicación.
- **Perfil de notificaciones**: UID, consentimiento, token(es) push,
  geohash/posición reciente, hora de actualización y caducidad de la posición.
- **Foto del incidente**: ruta de Storage, tipo MIME, tamaño y relación al
  reporte; no guardar el binario en Firestore.

### Supuestos y dependencias

- Radio seleccionado por el usuario: **500 metros**.
- Notificación seleccionada: **Firebase Cloud Messaging**, incluso con la app
  cerrada.
- Foto seleccionada: **opcional**.
- El primer toque activa el SOS sin confirmación; la pantalla posterior permite
  completar detalles o cancelar. Cancelar genera una actualización de cierre.
- La comunidad de destino es la comunidad local/distrito configurado del
  reportante, no un feed público global.
- La búsqueda de destinatarios usa la última ubicación de usuarios que
  aceptaron compartirla y se actualizó durante los últimos 15 minutos. No se
  contempla rastreo continuo en segundo plano en el alcance inicial.
- Para conservar el inicio de sesión demo actual, se propone Firebase Anonymous
  Auth como identidad técnica inicial; debe confirmarse antes de desplegar a
  usuarios reales o migrarse a una autenticación de producto.
- Firebase Auth, FCM, Storage y Functions deben habilitarse y configurarse para
  los targets soportados. El envío seguro de FCM requiere una función backend;
  no se debe enviar desde el cliente con credenciales privilegiadas.
- Los datos de perfil/ubicación y el acceso a la alerta deben ser protegidos con
  reglas; Firebase Cloud Messaging puede requerir configuración de APNs en iOS.
- La llamada SOS no sustituye a los servicios oficiales de emergencia.

## Criterios de éxito

- **SC-001**: Con GPS y red disponibles, el usuario puede activar una alerta con
  un toque y ver el resultado en menos de 5 segundos en al menos el 95% de las
  pruebas de aceptación.
- **SC-002**: Al menos el 95% de los dispositivos de prueba autorizados, con
  ubicación vigente dentro de 500 m y conectividad push, recibe el aviso en
  menos de 10 segundos; ningún dispositivo de prueba fuera del radio lo recibe.
- **SC-003**: El 100% de alertas activas de prueba se representa con círculo rojo
  de 500 m y marcador de peligro; al cerrar la alerta, desaparece del estado
  activo.
- **SC-004**: Se puede publicar una emergencia sin foto y con foto; fallos de
  carga/reintentos no crean duplicados.
- **SC-005**: Usuarios no autorizados no pueden leer tokens ni ubicaciones
  privadas ni modificar o cerrar alertas ajenas en pruebas de reglas.
