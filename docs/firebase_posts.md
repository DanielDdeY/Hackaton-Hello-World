# Publicaciones de Comunidad en Firebase

Servicios, Noticias y Eventos se guardan en Cloud Firestore dentro de `posts/{postId}`. En Comunidad, **Servicios** muestra el catálogo y **Eventos** reúne los próximos eventos y las noticias del barrio.

## Estructura de las publicaciones

El [mapeador de Firestore](../lib/features/create_post/data/mappers/firestore_post_mapper.dart) construye el documento común. Los datos de cada formulario se guardan en `details`.

| Campo común | Valor |
|---|---|
| `id` | Identificador del documento, igual a `postId`. |
| `category` | `service` para Servicios, `news` para Noticias, `event` para Eventos, `help` para Ayuda y `emergency` para Emergencia. |
| `status` | `active` al publicar. |
| `schemaVersion` | `2`. |
| `authorId` | UID de la sesión autenticada. |
| `authorName` | En Servicios y Noticias, nombre del perfil obtenido con `UserProfileStore`. Si falta el perfil o el nombre, se guarda `Vecino`. |
| `createdAt`, `updatedAt` | Marcas de tiempo del servidor. |
| `photos` | Lista de objetos con `storagePath` y `downloadUrl`. |
| `mediaStatus` | `none`, `uploading`, `ready` o `failed`. En un envío de Servicios o Noticias se guarda `none` sin foto y `ready` si la subida se completó. |
| `location` | Datos de ubicación cuando la categoría los proporciona. |

El [repositorio de escritura](../lib/features/create_post/data/repositories/firestore_post_repository.dart) sube la foto opcional de Servicios o Noticias a Cloud Storage antes de guardar el documento. Si falla la subida, el documento queda sin crear. Si falla la escritura después de la subida, el repositorio intenta eliminar la foto. El formulario conserva el borrador para reintentar.

### Servicios

| Campo en `details` | Valor |
|---|---|
| `title`, `information` | Título y descripción del servicio o producto. |
| `mode` | `provide_service` para Brindar servicio o `sell` para Vender. |
| `price`, `currency` | Monto numérico mayor o igual a cero y moneda `PEN`. |
| `paymentMethods` | Lista de claves `yape`, `plin`, `cash`, `bank_transfer` o `card`. |
| `transferBanks` | Claves de los bancos seleccionados cuando corresponde una transferencia. |
| `contactPhone` | Celular de nueve dígitos que empieza con `9`. |
| `availability` | Opcional en `provide_service`. Cuando se completa, incluye `days` con claves de `mon` a `sun`, `startTime` y `endTime` en formato `HH:mm`. |
| `stock` | Cantidad entera mayor o igual a uno en `sell`. |
| `serviceCategory` | Clave estable que devuelve el clasificador. Sirve para mostrar la categoría y filtrar en Firestore. |
| `categorySource` | `keyword`, que indica que la categoría se asignó automáticamente mediante el diccionario. |

Se guarda el campo de la modalidad elegida. En Brindar servicio con la disponibilidad en blanco, `details` omite tanto el horario como el stock. Si se completa la disponibilidad, el formulario requiere al menos un día y una hora de fin posterior a la de inicio.

### Noticias

| Campo en `details` | Valor |
|---|---|
| `title`, `content` | Título y contenido obligatorios. |
| `quickCategory` | `general`, `lost_pet`, `neighborhood_life`, `service_cuts` o `null`. |

### Eventos

El formulario de **Publicar → Eventos** usa el mismo flujo de envío. Guarda `title`, `place` y `startsAt` en `details`. El día y la hora forman una sola marca de tiempo en Firestore. La fecha debe ser futura. Si se completan los campos opcionales, también guarda `attendees` como cantidad entera de asistentes previstos y `description` como detalle.

## Cómo consulta Comunidad

[ComunidadFeedRepository](../lib/features/comunidad/domain/repositories/comunidad_feed_repository.dart) entrega listas tipadas por medio de flujos. Su [implementación de Firestore](../lib/features/comunidad/data/repositories/firestore_comunidad_feed_repository.dart) establece la sesión antes de abrir las consultas.

| Método | Consulta y destino |
|---|---|
| `watchServices()` | Servicios con `category == 'service'` y `status == 'active'`. Corresponde al filtro **Todos**. |
| `watchServices(category: ...)` | La misma consulta con una condición adicional de igualdad sobre `details.serviceCategory`. |
| `watchNews()` | Publicaciones con `category == 'news'` y `status == 'active'`. Se muestran en **Eventos → Noticias del barrio**. |
| `watchEvents()` | Publicaciones activas de categoría `event` con `details.startsAt` posterior al momento de la consulta. Se muestran en **Eventos → Próximos eventos**. |

Cada consulta pide hasta 30 documentos. Servicios y Noticias ordenan por `createdAt` descendente. Eventos ordena por `details.startsAt` ascendente. Las pestañas conservan las suscripciones al alternar entre ellas. Al cambiar el filtro de Servicios se abre la consulta de la categoría seleccionada.

En **Todos**, un servicio antiguo con categoría ausente o desconocida se presenta como **Otros**. Al elegir el filtro **Otros**, Firestore devuelve los documentos que guardan explícitamente `details.serviceCategory == 'other'`.

## Clasificación automática de Servicios

El [clasificador](../lib/features/create_post/data/services/keyword_service_category_classifier.dart) recibe título e información. Los pasa a minúsculas, elimina los diacríticos previstos por el normalizador y convierte la puntuación y los espacios consecutivos en separadores. Compara palabras completas y frases delimitadas.

Cada término fuerte aporta **2 puntos** y cada término débil aporta **1 punto**. Si coincide en el título, su aporte se multiplica por **3**. Si solo coincide en la información o cruza el límite entre ambos campos, se aplica el peso base. Cada término cuenta una vez por categoría y, si aparece en ambos campos, se usa el peso del título.

Gana la categoría con mayor puntaje a partir de **2 puntos**. En caso de empate se compara el puntaje del título, luego la cantidad de términos fuertes y, por último, la prioridad que aparece en la tabla. Si ninguna categoría alcanza el mínimo, se guarda `other`.

| Prioridad | Clave guardada | Etiqueta |
|---|---|---|
| 1 | `food` | Comida |
| 2 | `home_trades` | Hogar y Oficios |
| 3 | `education` | Educación |
| 4 | `pets` | Mascotas |
| 5 | `health_care` | Salud y Cuidado |
| 6 | `technology` | Tecnología |
| 7 | `transport_moving` | Transporte y Mudanza |
| 8 | `beauty_sewing` | Belleza y Costura |
| Predeterminada | `other` | Otros |

Para ampliar el vocabulario, agrega la palabra o frase a `strong` o `weak` en el [archivo del diccionario](../lib/features/create_post/data/services/service_category_keywords.dart). Reserva `strong` para términos distintivos y usa `weak` para indicios ambiguos. Puedes ampliar el vocabulario sin editar el algoritmo ni cambiar las claves persistidas. Los cambios se aplican a las publicaciones que se clasifiquen después de actualizar la app. [Auditoría del diccionario](service_category_dictionary.md).

## Reglas, índices y privacidad

Las [reglas de Firestore](../firestore.rules) requieren una sesión para leer `posts`. Al crear un documento comprueban la autoría, el esquema y los campos comunes. En Servicios validan la clave de categoría, el monto numérico no negativo y el patrón `^9[0-9]{8}$` del celular. En Noticias requieren título y contenido con texto. El autor puede actualizar `photos`, `mediaStatus` y `updatedAt`, o eliminar el documento.

Al publicar un evento, las reglas también validan el título, el lugar, la fecha futura y el tipo de los campos opcionales. Los [índices compuestos](../firestore.indexes.json) de `posts` respaldan las consultas de Comunidad.

| Consulta | Campos del índice |
|---|---|
| Noticias y Servicios sin filtro de categoría de servicio | `category ASC`, `status ASC`, `createdAt DESC`. |
| Servicios con filtro de categoría | `category ASC`, `status ASC`, `details.serviceCategory ASC`, `createdAt DESC`. |
| Próximos eventos | `category ASC`, `status ASC`, `details.startsAt ASC`. |

El celular de contacto se guarda en `details.contactPhone` y se muestra en el detalle del servicio. La decisión actual es que **cualquier usuario autenticado puede leerlo**, incluida una sesión anónima de Firebase, para facilitar el contacto entre vecinos. El número se puede seleccionar. Botones **Copiar** y **Llamar** serían una mejora futura.
