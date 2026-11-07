# Módulo Comunidad: arquitectura, reglas de negocio y requisitos

> Documento de trabajo. Nombre del módulo provisional ("Comunidad"). Moneda de la app: **moneda**. Las tareas con recompensa se llaman **favores** (antes "misiones"). Ambos nombres pueden cambiar tras probarlos con vecinos.

## 1. Alcance

Comunidad es el espacio donde el vecino **ve, acepta, participa y reconoce**. No crea contenido: otros módulos lo hacen.

| Dentro de Comunidad                          | Fuera de Comunidad (otros equipos)  |
| -------------------------------------------- | ----------------------------------- |
| Ver y filtrar favores                        | Publicar favores y eventos          |
| Aceptar favores (cupos)                      | Mapa y geolocalización              |
| Seguimiento del favor hasta la recompensa    | Alertas y modo emergencia (gestión) |
| Ver eventos, confirmar "Voy" / "Me interesa" | Directorio de servicios             |
| Registrar asistencia a reuniones             | Tienda, cajas y mascota             |
| Ranking, buen vecino y reconocimientos       | Verificación de mochila             |
| Historial personal                           | Chat (se usa WhatsApp enlazado)     |

## 2. Mapa de pantallas

Barra superior con 4 pestañas. La barra inferior de la app ya existe y no se redefine aquí.

| Pestaña     | Pantallas                       |
| ----------- | ------------------------------- |
| **Hoy**     | Resumen, Pendientes, Historial  |
| **Favores** | Lista, Detalle, Seguimiento     |
| **Eventos** | Lista, Detalle, Asistencia      |
| **Vecinos** | Ranking, Buen vecino, Reconocer |

Elementos transversales: banner de alerta activa (solo visualiza, la gestiona otro módulo), menú de reporte en cada tarjeta, estados vacíos y aviso de modo sin conexión.

## 3. Arquitectura

### 3.1 Stack

- **Cliente:** Flutter (Android).
- **Backend:** Firebase (Firestore, Authentication, Cloud Functions, Cloud Messaging, Remote Config).
- **Estado:** Riverpod.
- **Navegación:** go_router, con enlaces profundos.

### 3.2 Organización del código (feature-first)

```
lib/
├── main.dart
├── app/
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── firebase/          inicialización y persistencia offline
│   ├── models/            Usuario, Cuadra (compartidos)
│   ├── services/          conectividad, WhatsApp, QR
│   └── widgets/           botones, tarjetas, estados vacíos
└── features/
    └── comunidad/
        ├── data/          DTOs e implementaciones de repositorios
        ├── domain/        entidades, interfaces, casos de uso
        └── presentation/  comunidad_page, hoy/, favores/, eventos/, vecinos/
```

Tres capas por funcionalidad: **presentation** (pantallas y proveedores Riverpod), **domain** (entidades, interfaces de repositorio y casos de uso como `aceptarFavor` o `marcarTerminado`) y **data** (Firestore). Las interfaces permiten usar datos falsos mientras otros equipos terminan sus módulos.

### 3.3 Modelo de datos (Firestore, NoSQL)

| Colección                          | Campos principales                                                                                                    |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `cuadras/{id}`                     | nombre, barrioId, distritoId                                                                                          |
| `favores/{id}`                     | tipo, tamaño, categoría, estado, cupos, tomados, cuadraId, solicitanteId, venceEn, recompensa (calculada por sistema) |
| `favores/{id}/participantes/{uid}` | estado, aceptadoEn, terminadoEn, confirmadoEn, calificación                                                           |
| `eventos/{id}`                     | tipo, fecha, lugar, organizadorId, cuadraId, requiereAsistencia                                                       |
| `eventos/{id}/asistencias/{uid}`   | respuesta (voy / interesa), verificada                                                                                |
| `reconocimientos/{id}`             | autorId, destinoId, semana, motivo                                                                                    |
| `ranking/{liga}/{uid}`             | xpPeriodo, posición (precalculado)                                                                                    |
| `stats/{barrioId}`                 | favoresCompletados, vecinosDistintos, % preparación (precalculado)                                                    |
| `usuarios/{uid}`                   | nivel, xp, moneda, estrellas (solo lectura para el cliente)                                                           |
| `economia/pendientes/{id}`         | recompensas retenidas 24 a 48 h                                                                                       |

Principio: ranking y estadísticas son **documentos ya calculados**, nunca consultas pesadas desde el cliente.

### 3.4 Responsabilidades cliente / servidor

| Lo escribe la app           | Lo escribe Cloud Functions             |
| --------------------------- | -------------------------------------- |
| Aceptar cupo (transacción)  | XP y moneda                            |
| "Terminé" y calificación    | Liberar recompensas pendientes         |
| "Voy" / "Me interesa"       | Ranking, ligas y estadísticas          |
| Registro de asistencia (QR) | Buen vecino de la semana               |
| Nominación de buen vecino   | Detección de pares repetidos y anillos |

Las reglas de seguridad deben impedir que el cliente modifique XP, moneda, estrellas o ranking.

### 3.5 Estados del favor

`Abierto → Cupos llenos (bloqueado) → Aceptado → En curso → Esperando confirmación → Completado → Recompensa pendiente → Liberada`

Estados laterales: `Cancelado`, `Vencido`, `En revisión` (por reporte).

### 3.6 Offline

- Persistencia de Firestore activa: lectura de lo ya cargado y escritura en cola.
- **Las transacciones no funcionan offline.** Aceptar un cupo queda como "solicitud pendiente" y se resuelve al reconectar; si el cupo ya se llenó, se notifica al vecino.
- XP y moneda llegan al sincronizar (Cloud Functions).
- Se guarda en caché lo esencial de la zona: favores abiertos cercanos y eventos próximos.

### 3.7 Contrato con otros módulos

| Origen               | Entrega a Comunidad                              | Acuerdo necesario                                    |
| -------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| Publicación          | Documentos `favores` y `eventos`                 | Esquema de campos y estados fijo                     |
| Alertas / Emergencia | Alerta activa e indicador de **modo emergencia** | Un documento o flag de lectura (`emergencia/activa`) |
| Mapa                 | Ubicación aproximada y navegación                | Enlace profundo `/comunidad/favor/{id}`              |
| Perfil               | Nivel, XP, moneda, estrellas                     | Solo lectura; la actualiza el servidor               |

### 3.8 Notificaciones (FCM por temas)

Temas por cuadra y barrio (`cuadra_{id}_favores`, `barrio_{id}_eventos`). El vecino elige qué recibir. Las urgentes pertenecen al módulo de alertas.

## 4. Reglas de negocio (RN)

| ID    | Regla                                                                                                                                               |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| RN-01 | La recompensa de un favor la fija el sistema según tamaño y duración; quien publica no puede modificarla.                                           |
| RN-02 | Un favor con cupos llenos se bloquea para nuevos participantes.                                                                                     |
| RN-03 | El cierre exige doble confirmación: el ayudante marca "terminé" y el vecino ayudado confirma y califica.                                            |
| RN-04 | La recompensa queda pendiente 24 a 48 h y se libera si no hay reporte.                                                                              |
| RN-05 | No existe transferencia de moneda entre vecinos.                                                                                                    |
| RN-06 | Un vecino no puede aceptar sus propios favores.                                                                                                     |
| RN-07 | La ubicación exacta de un favor se revela solo al aceptarlo.                                                                                        |
| RN-08 | Entre los mismos dos vecinos, la recompensa decrece en 30 días: 100%, 50%, 25%, 0%.                                                                 |
| RN-09 | Ayudar a un vecino nuevo o de otra cuadra da +25% de moneda.                                                                                        |
| RN-10 | Un favor pasado a otro vecino distinto ("cadena") da +20% por eslabón, hasta 3 eslabones; no aplica entre el mismo par.                             |
| RN-11 | Los eventos no tienen cupo competitivo: "Voy" o "Me interesa".                                                                                      |
| RN-12 | En reuniones vecinales solo cuenta la asistencia verificada (QR o ubicación).                                                                       |
| RN-13 | El organizador cobra según asistencia real, con tope, y solo si asisten al menos 5 vecinos distintos.                                               |
| RN-14 | El ranking se basa solo en XP, nunca en moneda.                                                                                                     |
| RN-15 | El ranking se muestra por cuadra, barrio y distrito, con ligas que se reinician.                                                                    |
| RN-16 | Cada vecino tiene un cupo semanal de nominaciones de "buen vecino".                                                                                 |
| RN-17 | Quien pide ayuda tiene un cupo semanal de pedidos que generan recompensa (inicial: 3).                                                              |
| RN-18 | Un reporte retiene la recompensa y envía el favor a revisión.                                                                                       |
| RN-19 | En modo emergencia se suspenden cupos de ayuda, topes y rendimientos decrecientes; las recompensas siguen siendo fijas y solo por ayuda confirmada. |
| RN-20 | El modo emergencia solo lo activa un delegado o una alerta oficial, nunca el vecino.                                                                |
| RN-21 | Las cuentas nuevas tienen un periodo de prueba con ganancias reducidas (confianza oculta).                                                          |

## 5. Requisitos funcionales (RF)

| ID    | Requisito                                                                                    | Prioridad |
| ----- | -------------------------------------------------------------------------------------------- | --------- |
| RF-01 | Mostrar la pantalla **Hoy** con alerta activa, pendientes, cercanos y progreso.              | Alta      |
| RF-02 | Listar favores con filtros: cercanía, tamaño, categoría y "con cupo".                        | Alta      |
| RF-03 | Mostrar el detalle del favor: descripción, ubicación aproximada, reglas, recompensa y cupos. | Alta      |
| RF-04 | Permitir **aceptar** un favor respetando el cupo mediante transacción.                       | Alta      |
| RF-05 | Mostrar el seguimiento por estados y permitir marcar "terminé" o cancelar con aviso.         | Alta      |
| RF-06 | Permitir al vecino ayudado confirmar y calificar con estrellas.                              | Alta      |
| RF-07 | Habilitar contacto por WhatsApp solo tras aceptar.                                           | Media     |
| RF-08 | Permitir "pasar el favor" (cadena) a otro vecino.                                            | Media     |
| RF-09 | Listar eventos por fecha con "Voy" y "Me interesa".                                          | Alta      |
| RF-10 | Registrar asistencia a reuniones mediante QR o ubicación.                                    | Media     |
| RF-11 | Compartir un evento o favor al grupo de WhatsApp mediante enlace profundo.                   | Media     |
| RF-12 | Mostrar ranking por cuadra, barrio y distrito, con la posición del usuario.                  | Media     |
| RF-13 | Mostrar el "buen vecino de la semana".                                                       | Media     |
| RF-14 | Permitir reconocer (nominar) a un vecino dentro del cupo semanal.                            | Media     |
| RF-15 | Mostrar estadísticas colectivas básicas de la cuadra.                                        | Baja      |
| RF-16 | Mostrar el historial de favores, eventos y recompensas.                                      | Media     |
| RF-17 | Permitir reportar cualquier favor, evento o reconocimiento.                                  | Alta      |
| RF-18 | Mostrar estados vacíos útiles cuando no hay contenido.                                       | Media     |
| RF-19 | Indicar estado sin conexión y mostrar solicitudes pendientes de sincronizar.                 | Alta      |
| RF-20 | Cambiar a la vista de emergencia al detectar el indicador de modo emergencia.                | Alta      |
| RF-21 | Recibir notificaciones configurables por tema (favores, eventos).                            | Media     |

## 6. Requisitos no funcionales (RNF)

| ID     | Categoría      | Requisito                                                                                                                   |
| ------ | -------------- | --------------------------------------------------------------------------------------------------------------------------- |
| RNF-01 | Usabilidad     | Aceptar un favor en máximo 3 toques desde la lista.                                                                         |
| RNF-02 | Usabilidad     | Letra grande, íconos claros y poco texto; lenguaje sin jerga (adultos mayores).                                             |
| RNF-03 | Accesibilidad  | Contraste adecuado, áreas táctiles amplias y etiquetas para lector de pantalla.                                             |
| RNF-04 | Disponibilidad | Funcionar sin conexión para lectura y encolar escrituras.                                                                   |
| RNF-05 | Confiabilidad  | Un cupo nunca debe sobrepasarse aunque dos vecinos acepten a la vez.                                                        |
| RNF-06 | Integridad     | XP, moneda y ranking solo se modifican desde el servidor.                                                                   |
| RNF-07 | Seguridad      | Reglas de Firestore por rol y por cuadra; acceso solo a datos de la propia zona.                                            |
| RNF-08 | Privacidad     | Estadísticas solo agregadas; ubicación exacta solo tras aceptar; cumplimiento de la Ley 29733 con consentimiento explícito. |
| RNF-09 | Rendimiento    | Cargar la pantalla Hoy en menos de 2 s con conexión normal, usando paginación y caché.                                      |
| RNF-10 | Costos         | Minimizar lecturas con documentos precalculados y expiración (TTL) de avisos vencidos.                                      |
| RNF-11 | Escalabilidad  | Estructura por funcionalidades y parámetros económicos en Remote Config para añadir funciones sin reescribir.               |
| RNF-12 | Mantenibilidad | Interfaces de repositorio para sustituir datos reales por falsos en pruebas.                                                |
| RNF-13 | Compatibilidad | Soporte de Android 8.0 o superior (a confirmar con el equipo).                                                              |
| RNF-14 | Auditoría      | Registro de cada otorgamiento y retención de recompensa.                                                                    |

## 7. Conexión con la economía

Comunidad **genera eventos económicos** pero nunca calcula recompensas. Cada acción relevante crea un registro que Cloud Functions procesa aplicando las reglas del documento de economía.

| Acción en Comunidad                       | Evento económico      | Resultado                            |
| ----------------------------------------- | --------------------- | ------------------------------------ |
| Favor confirmado por ambas partes         | `favor_completado`    | Moneda y XP pendientes 24 a 48 h     |
| Favor encadenado                          | `favor_encadenado`    | Bono por eslabón sobre el favor      |
| Asistencia verificada a evento            | `evento_asistido`     | Moneda y XP simbólicos               |
| Evento organizado con asistencia mínima   | `evento_organizado`   | Pago por asistentes reales, con tope |
| Nominación recibida y elegida buen vecino | `buen_vecino`         | Insignia y XP                        |
| Reporte aceptado                          | `recompensa_retenida` | Recompensa en revisión o cancelada   |

Flujo:

1. La app escribe la acción (por ejemplo, confirmación del favor).
2. Una Cloud Function valida reglas (pares repetidos, topes, confianza, modo emergencia).
3. Calcula moneda y XP, y crea el registro pendiente.
4. Tras la ventana de retención, libera la recompensa y actualiza `usuarios` y `ranking`.
5. La app muestra el resultado leyendo documentos de solo lectura.

Parámetros (valores de recompensa, topes, ventanas de retención) viven en **Remote Config** para ajustarlos sin publicar una versión nueva.

## 8. Orden de implementación sugerido

1. Modelos y repositorios falsos para avanzar la interfaz.
2. Favores: lista, detalle y flujo de aceptar (núcleo de la demo).
3. Eventos y pantalla Hoy.
4. Cloud Functions de recompensas.
5. Vecinos (ranking y buen vecino), con datos precalculados si el tiempo es corto.

## 9. Pendientes por decidir

- Esquema exacto de `favores` y `eventos` con el encargado de publicación [creo]
- Mecanismo del indicador de modo emergencia con el equipo de alertas.
- Verificación de pertenencia a la cuadra (código del delegado, invitación o dirección validada).
- idear/definir roles
