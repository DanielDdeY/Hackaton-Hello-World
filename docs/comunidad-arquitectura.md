# Módulo Comunidad: arquitectura, reglas de negocio y requisitos

> Documento de trabajo. Nombre del módulo provisional ("Comunidad"). La moneda de la app se llama **ficha**. Las tareas con recompensa se llaman **favores** (antes "misiones"); en pantalla se habla de **ayudantes** y no de "cupos".

## 1. Alcance

Comunidad es el espacio donde el vecino **ve, acepta, participa y reconoce**. No crea contenido: otros módulos lo hacen.

| Dentro de Comunidad                          | Fuera de Comunidad (otros equipos)  |
| -------------------------------------------- | ----------------------------------- |
| Ver y filtrar favores                        | Publicar favores y eventos          |
| Aceptar favores (con límite de ayudantes)    | Mapa y geolocalización              |
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

| Colección                          | Campos principales                                                                                                                                                       |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `cuadras/{id}`                     | nombre, barrioId, distritoId                                                                                                                                             |
| `favores/{id}`                     | tipo, tamaño, categoría, estado, ayudantes necesarios (`cuposTotales`) y anotados (`cuposTomados`), cuadraId, solicitanteId, venceEn, recompensa (calculada por sistema) |
| `favores/{id}/participantes/{uid}` | estado, aceptadoEn, terminadoEn, confirmadoEn, calificación                                                                                                              |
| `eventos/{id}`                     | tipo, fecha, lugar, organizadorId, cuadraId, requiereAsistencia                                                                                                          |
| `eventos/{id}/asistencias/{uid}`   | respuesta (voy / interesa), verificada                                                                                                                                   |
| `reconocimientos/{id}`             | autorId, destinoId, semana, motivo                                                                                                                                       |
| `ranking/{liga}/{uid}`             | xpPeriodo, posición (precalculado)                                                                                                                                       |
| `stats/{barrioId}`                 | favoresCompletados, vecinosDistintos, % preparación (precalculado)                                                                                                       |
| `usuarios/{uid}`                   | nivel, xpNivel, xpLiga, estrellas, fiabilidad (solo lectura para el cliente)                                                                                             |
| `usuarios/{uid}/billetera`         | disponible, pendiente (solo lectura para el cliente)                                                                                                                     |
| `usuarios/{uid}/movimientos/{id}`  | tipo, monto, origen, fecha, idempotencyKey (registro inmutable)                                                                                                          |
| `economia/pendientes/{id}`         | recompensas retenidas 24 a 48 h                                                                                                                                          |

Principio: ranking y estadísticas son **documentos ya calculados**, nunca consultas pesadas desde el cliente.

### 3.4 Responsabilidades cliente / servidor

| Lo escribe la app                    | Lo escribe Cloud Functions             |
| ------------------------------------ | -------------------------------------- |
| Anotarse como ayudante (transacción) | XP y ficha                             |
| "Terminé" y calificación             | Liberar recompensas pendientes         |
| "Voy" / "Me interesa"                | Ranking, ligas y estadísticas          |
| Registro de asistencia (QR)          | Buen vecino de la semana               |
| Nominación de buen vecino            | Detección de pares repetidos y anillos |

Las reglas de seguridad deben impedir que el cliente modifique XP, ficha, estrellas o ranking.

### 3.5 Estados del favor

`Abierto → Completo (bloqueado) → Aceptado → En curso → Esperando confirmación → Completado → Recompensa pendiente → Liberada`

Estados laterales: `Cancelado`, `Vencido`, `En revisión` (por reporte).

### 3.6 Offline

- Persistencia de Firestore activa: lectura de lo ya cargado y escritura en cola.
- **Las transacciones no funcionan offline.** Aceptar un favor queda como "solicitud pendiente" y se resuelve al reconectar; si el cupo ya se llenó, se notifica al vecino.
- XP y ficha llegan al sincronizar (Cloud Functions).
- Se guarda en caché lo esencial de la zona: favores abiertos cercanos y eventos próximos.

### 3.7 Contrato con otros módulos

| Origen               | Entrega a Comunidad                              | Acuerdo necesario                                    |
| -------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| Publicación          | Documentos `favores` y `eventos`                 | Esquema de campos y estados fijo                     |
| Alertas / Emergencia | Alerta activa e indicador de **modo emergencia** | Un documento o flag de lectura (`emergencia/activa`) |
| Mapa                 | Ubicación aproximada y navegación                | Enlace profundo `/comunidad/favor/{id}`              |
| Perfil               | Nivel, XP, ficha, estrellas                      | Solo lectura; la actualiza el servidor               |

### 3.8 Notificaciones (FCM por temas)

Temas por cuadra y barrio (`cuadra_{id}_favores`, `barrio_{id}_eventos`). El vecino elige qué recibir. Las urgentes pertenecen al módulo de alertas.

## 4. Reglas de negocio (RN)

| ID    | Regla                                                                                                                                                                       |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RN-01 | La recompensa de un favor la fija el sistema según tamaño y duración; quien publica no puede modificarla.                                                                   |
| RN-02 | Un favor con todos sus ayudantes anotados queda **completo** y se bloquea para nuevos participantes.                                                                        |
| RN-03 | El cierre exige doble confirmación: el ayudante marca "terminé" y el vecino ayudado confirma y califica.                                                                    |
| RN-04 | La recompensa queda pendiente 24 a 48 h y se libera si no hay reporte.                                                                                                      |
| RN-05 | No existe transferencia de ficha entre vecinos.                                                                                                                             |
| RN-06 | Un vecino no puede aceptar sus propios favores.                                                                                                                             |
| RN-07 | La ubicación exacta de un favor se revela solo al aceptarlo.                                                                                                                |
| RN-08 | Entre los mismos dos vecinos, la recompensa decrece en 30 días: 100%, 50%, 25%, 0%.                                                                                         |
| RN-09 | Ayudar a un vecino nuevo o de otra cuadra da +25% de ficha.                                                                                                                 |
| RN-10 | Un favor pasado a otro vecino distinto ("cadena") da +20% por eslabón, hasta 3 eslabones; no aplica entre el mismo par.                                                     |
| RN-11 | En los eventos no hay lugares que se compitan: "Voy" o "Me interesa".                                                                                                       |
| RN-12 | En reuniones vecinales solo cuenta la asistencia verificada (QR o ubicación).                                                                                               |
| RN-13 | El organizador cobra según asistencia real, con tope, y solo si asisten al menos 5 vecinos distintos.                                                                       |
| RN-14 | El ranking se basa solo en XP de liga, nunca en ficha ni en XP de nivel.                                                                                                    |
| RN-15 | El ranking se muestra por cuadra, barrio y distrito, con ligas que se reinician.                                                                                            |
| RN-16 | Cada vecino tiene un límite semanal de nominaciones de "buen vecino".                                                                                                       |
| RN-17 | Quien pide ayuda tiene un límite semanal de pedidos que generan recompensa (inicial: 3).                                                                                    |
| RN-18 | Un reporte retiene la recompensa y envía el favor a revisión.                                                                                                               |
| RN-19 | En modo emergencia se suspenden los límites de ayudantes, topes y rendimientos decrecientes; las recompensas siguen siendo fijas y solo por ayuda confirmada.               |
| RN-20 | El modo emergencia solo lo activa un delegado o una alerta oficial, nunca el vecino.                                                                                        |
| RN-21 | Las cuentas nuevas tienen un periodo de prueba con ganancias reducidas (confianza oculta).                                                                                  |
| RN-22 | El XP de nivel nunca baja; las penalizaciones solo afectan al XP de liga, que no baja de cero.                                                                              |
| RN-23 | Se penaliza no presentarse a un favor aceptado o a una reunión con asistencia verificada; no se penaliza "Me interesa", eventos sin verificación ni cancelaciones a tiempo. |
| RN-24 | Cancelar con al menos 2 a 4 h de anticipación (a definir) no tiene costo.                                                                                                   |
| RN-25 | La penalización equivale a ~50% del XP del favor (25% en reuniones), con un "no pude" gratuito por mes y un tope semanal de pérdida.                                        |
| RN-26 | La reincidencia escala (aviso, penalización leve, completa) y reduce cuántos favores puede tener a la vez mediante la fiabilidad oculta.                                    |
| RN-27 | "No llegó" lo marca el vecino ayudado; el ayudante puede responder y, ante desacuerdo, la penalización se suspende hasta la revisión.                                       |
| RN-28 | Los saldos de ficha se llevan en una billetera con saldo disponible y pendiente; solo el servidor escribe movimientos.                                                      |
| RN-29 | Gastar ficha requiere conexión y una transacción que valida saldo y entrega el objeto en un solo paso.                                                                      |
| RN-30 | No hay penalizaciones en modo emergencia.                                                                                                                                   |

## 5. Requisitos funcionales (RF)

| ID    | Requisito                                                                                                                | Prioridad |
| ----- | ------------------------------------------------------------------------------------------------------------------------ | --------- |
| RF-01 | Mostrar la pantalla **Hoy** con alerta activa, pendientes, cercanos y progreso.                                          | Alta      |
| RF-02 | Listar favores con filtros: cercanía, tamaño, categoría y "faltan ayudantes".                                            | Alta      |
| RF-03 | Mostrar el detalle del favor: descripción, ubicación aproximada, reglas, recompensa y ayudantes (anotados y necesarios). | Alta      |
| RF-04 | Permitir **aceptar** un favor respetando el máximo de ayudantes mediante transacción.                                    | Alta      |
| RF-05 | Mostrar el seguimiento por estados y permitir marcar "terminé" o cancelar con aviso.                                     | Alta      |
| RF-06 | Permitir al vecino ayudado confirmar y calificar con estrellas.                                                          | Alta      |
| RF-07 | Habilitar contacto por WhatsApp solo tras aceptar.                                                                       | Media     |
| RF-08 | Permitir "pasar el favor" (cadena) a otro vecino.                                                                        | Media     |
| RF-09 | Listar eventos por fecha con "Voy" y "Me interesa".                                                                      | Alta      |
| RF-10 | Registrar asistencia a reuniones mediante QR o ubicación.                                                                | Media     |
| RF-11 | Compartir un evento o favor al grupo de WhatsApp mediante enlace profundo.                                               | Media     |
| RF-12 | Mostrar ranking por cuadra, barrio y distrito, con la posición del usuario.                                              | Media     |
| RF-13 | Mostrar el "buen vecino de la semana".                                                                                   | Media     |
| RF-14 | Permitir reconocer (nominar) a un vecino dentro del límite semanal.                                                      | Media     |
| RF-15 | Mostrar estadísticas colectivas básicas de la cuadra.                                                                    | Baja      |
| RF-16 | Mostrar el historial de favores, eventos y recompensas.                                                                  | Media     |
| RF-17 | Permitir reportar cualquier favor, evento o reconocimiento.                                                              | Alta      |
| RF-18 | Mostrar estados vacíos útiles cuando no hay contenido.                                                                   | Media     |
| RF-19 | Indicar estado sin conexión y mostrar solicitudes pendientes de sincronizar.                                             | Alta      |
| RF-20 | Cambiar a la vista de emergencia al detectar el indicador de modo emergencia.                                            | Alta      |
| RF-21 | Recibir notificaciones configurables por tema (favores, eventos).                                                        | Media     |
| RF-22 | Mostrar saldo disponible y pendiente de la billetera y su historial de movimientos.                                      | Alta      |
| RF-23 | Permitir cancelar un favor aceptado, indicando si es a tiempo y mostrando la consecuencia antes de confirmar.            | Alta      |
| RF-24 | Permitir al vecino ayudado marcar "no llegó" y al ayudante responder con "en camino" o su ubicación.                     | Media     |
| RF-25 | Mostrar al vecino la penalización aplicada y permitir apelarla.                                                          | Media     |
| RF-26 | Limitar la cantidad de favores simultáneos según la fiabilidad, explicando el motivo sin mostrar el puntaje.             | Media     |

## 6. Requisitos no funcionales (RNF)

| ID     | Categoría      | Requisito                                                                                                                   |
| ------ | -------------- | --------------------------------------------------------------------------------------------------------------------------- |
| RNF-01 | Usabilidad     | Aceptar un favor en máximo 3 toques desde la lista.                                                                         |
| RNF-02 | Usabilidad     | Letra grande, íconos claros y poco texto; lenguaje sin jerga (adultos mayores).                                             |
| RNF-03 | Accesibilidad  | Contraste adecuado, áreas táctiles amplias y etiquetas para lector de pantalla.                                             |
| RNF-04 | Disponibilidad | Funcionar sin conexión para lectura y encolar escrituras.                                                                   |
| RNF-05 | Confiabilidad  | Nunca debe haber más ayudantes anotados que los necesarios, aunque dos vecinos acepten a la vez.                            |
| RNF-06 | Integridad     | XP, ficha y ranking solo se modifican desde el servidor.                                                                    |
| RNF-07 | Seguridad      | Reglas de Firestore por rol y por cuadra; acceso solo a datos de la propia zona.                                            |
| RNF-08 | Privacidad     | Estadísticas solo agregadas; ubicación exacta solo tras aceptar; cumplimiento de la Ley 29733 con consentimiento explícito. |
| RNF-09 | Rendimiento    | Cargar la pantalla Hoy en menos de 2 s con conexión normal, usando paginación y caché.                                      |
| RNF-10 | Costos         | Minimizar lecturas con documentos precalculados y expiración (TTL) de avisos vencidos.                                      |
| RNF-11 | Escalabilidad  | Estructura por funcionalidades y parámetros económicos en Remote Config para añadir funciones sin reescribir.               |
| RNF-12 | Mantenibilidad | Interfaces de repositorio para sustituir datos reales por falsos en pruebas.                                                |
| RNF-13 | Compatibilidad | Soporte de Android 8.0 o superior (a confirmar con el equipo).                                                              |
| RNF-14 | Auditoría      | Registro de cada otorgamiento, retención, penalización y ajuste.                                                            |
| RNF-15 | Integridad     | Los movimientos de la billetera son inmutables e idempotentes: reintentar no duplica.                                       |
| RNF-16 | Equidad        | Las penalizaciones deben poder revertirse mediante apelación y quedar registradas.                                          |

## 7. Conexión con la economía

Comunidad **genera eventos económicos** pero nunca calcula recompensas ni penalizaciones. La explicación general de la economía está en `economia_interna.md`. Cada acción relevante crea un registro que Cloud Functions procesa aplicando las reglas del documento de economía.

| Acción en Comunidad                          | Evento económico      | Resultado                                         |
| -------------------------------------------- | --------------------- | ------------------------------------------------- |
| Favor confirmado por ambas partes            | `favor_completado`    | Ficha y XP pendientes 24 a 48 h                   |
| Favor encadenado                             | `favor_encadenado`    | Bono por eslabón sobre el favor                   |
| Asistencia verificada a evento               | `evento_asistido`     | Ficha y XP simbólicos                             |
| Evento organizado con asistencia mínima      | `evento_organizado`   | Pago por asistentes reales, con tope              |
| Nominación recibida y elegida buen vecino    | `buen_vecino`         | Insignia y XP                                     |
| Reporte aceptado                             | `recompensa_retenida` | Recompensa en revisión o cancelada                |
| Favor aceptado y no cumplido ("no llegó")    | `favor_incumplido`    | Penalización de XP de liga y ajuste de fiabilidad |
| Reunión con asistencia verificada y ausencia | `evento_incumplido`   | Penalización menor de XP de liga                  |
| Cancelación a tiempo                         | `favor_cancelado`     | Sin costo; libera el lugar del ayudante           |
| Gasto de ficha (caja, tienda)                | `gasto`               | Movimiento en la billetera                        |

Flujo:

1. La app escribe la acción (por ejemplo, confirmación del favor).
2. Una Cloud Function valida reglas (pares repetidos, topes, confianza, modo emergencia).
3. Calcula ficha y XP, y crea el registro pendiente.
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

- Nombre final del módulo, de la ficha y de los favores (probar con vecinos).
- Esquema exacto de `favores` y `eventos` con el equipo de publicación.
- Mecanismo del indicador de modo emergencia con el equipo de alertas.
- Verificación de pertenencia a la cuadra (código del delegado, invitación o dirección validada).
- Panel de administración (idealmente web) para delegados y moderación.
