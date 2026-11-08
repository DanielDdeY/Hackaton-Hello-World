# Mascota y economía: integración con el estado actual del proyecto

> Documento externo de trabajo. Se basa en el código del repositorio `Hackaton-Hello-World` (zip subido, 2026-11-08). Complementa a `economia_interna.md` y `comunidad_arquitectura_requisitos.md`.
>
> **Nombres definidos:** la moneda se llama **ficha**; las tareas con recompensa, **favores**; en pantalla se habla de **ayudantes** y no de "cupos". Los identificadores internos del código (`monedasRecompensa`, `cuposTotales`, `cuposTomados`) pueden mantenerse y solo cambian los textos visibles; si se renombran, hacerlo en una sola pasada.
>
> Los valores numéricos son hipótesis para calibrar.

## 1. Resumen

**Lo que ya existe y sirve:** el perfil guarda XP, XP semanal, estrellas y estado de la mascota; Comunidad tiene 4 pestañas (Favores, Servicios, Eventos, Vecinos); hay ranking por distrito, "buen vecino" y reconocimientos; `TamanoFavor` ya trae las recompensas base (5/15/40/30 fichas y 10/30/80/60 XP); hay un codebase de Cloud Functions en TypeScript (hoy solo para emergencias); la mochila funciona offline.

**Lo que falta para que haya economía de verdad:**

1. **No existe la ficha ni la billetera.** Solo hay un campo `monedasRecompensa` dentro del favor; nadie la acredita.
2. **Completar un favor no paga nada.** `confirmarYCalificar` solo cambia el estado a `completado`.
3. **Hay dos modelos de favores y dos de eventos en paralelo.** La pestaña Favores lee `posts` (`HelpItem`, sin tamaño ni ayudantes necesarios y con una insignia fija "+5 pts (10 XP)"), mientras que el flujo completo (anotarse, terminar, confirmar) vive en `ComunidadRepository` sobre la colección `favores`, y ninguna pantalla lo llama.
4. **Las reglas de Firestore del repositorio no cubren la economía.** No hay reglas para `favores`, `eventos`, `ranking`, `reconocimientos`, `stats` ni `reportes`, y `users` solo permite actualizar campos de ubicación y token. El README dice que las reglas están abiertas; hay que confirmar cuáles están desplegadas.
5. **La mascota actual es otra cosa:** "Firulais", una mascota comunitaria con hambre gratuita, que se desbloquea en **nivel 25**. El cuy personal con ítems pide otro diseño.

## 2. Estado actual por componente

| Componente          | Dónde está                                                                     | Qué hace hoy                                                                                                                                                                                               | Relación con la economía                                                                     |
| ------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Perfil              | `lib/home/user_profile.dart`, colección `users/{uid}`                          | `xp`, `weeklyXp`, `stars` (entero), `favors`, `tools`, `petHunger` (0 a 1), `badges`, `stats.*`. Nivel = `xp ~/ 100`                                                                                       | Ya separa XP total de XP semanal: encaja con XP de nivel y XP de liga. No hay ficha          |
| Inicio y mascota    | `lib/home/home.dart`, `lib/home/login.dart`                                    | Muestra "Nivel · XP · Star"; tarjeta "Firulais" (SVG) con hambre y botón "Alimentar" gratuito que guarda desde el cliente. `login.dart` define `mascotaDesbloqueada => nivel >= 25` y `nivel => xp ~/ 100` | Desbloqueo y curva lineal fijos en el código                                                 |
| Tutorial            | `lib/home/tutorial.dart`                                                       | Dice que la mascota se cuida "desde el nivel 25"                                                                                                                                                           | Textos a actualizar                                                                          |
| Comunidad (UI)      | `lib/features/comunidad/presentation/`                                         | Pestañas alimentadas por `ComunidadFeedRepository` (`posts`); Vecinos usa `ComunidadController`                                                                                                            | La pestaña Favores no tiene ayudantes ni botón de anotarse                                   |
| Comunidad (dominio) | `domain/entities/favor.dart`, `evento_comunitario.dart`, `vecino_ranking.dart` | `Favor`, `TamanoFavor`, `EstadoFavor`, `ParticipanteFavor`                                                                                                                                                 | Modelo listo, sin consumo en pantallas                                                       |
| Comunidad (datos)   | `data/repositories/firestore_comunidad_repository.dart`                        | `aceptarFavor` con transacción, `marcarTerminado`, `confirmarYCalificar`, QR de asistencia, ranking en `ranking/{distrito}/posiciones`, `nominarBuenVecino`                                                | La transacción de ayudantes está bien; falta pagar, penalizar y mover escrituras al servidor |
| Publicar            | `lib/features/create_post/`                                                    | Formularios de ayuda, evento, noticia, servicio y emergencia hacia `posts`                                                                                                                                 | El formulario de ayuda no pide tamaño del favor                                              |
| Mochila             | `lib/features/ayuda_prevencion/`                                               | Checklist local (`mochila_checklist_v1`)                                                                                                                                                                   | La verificación con ML Kit la hace otra persona (ver 5.10)                                   |
| Functions           | `functions/src/index.ts`                                                       | `onEmergencyAlertCreated`, `onEmergencyAlertClosed`                                                                                                                                                        | Ahí cabe el motor de economía                                                                |
| Reglas              | `firestore.rules`                                                              | Cubre `phoneIndex`, `posts`, `users`, `emergency_alerts`, `community_posts`                                                                                                                                | Falta todo lo económico y lo de Comunidad                                                    |
| Ingreso             | `lib/home/login.dart`                                                          | Anónimo, Google o celular con código fijo `123456`                                                                                                                                                         | Facilita cuentas falsas (riesgo de farming)                                                  |

## 3. Brechas

| ID   | Brecha                                                                                                                                      | Gravedad |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| G-01 | No hay ficha, billetera ni movimientos                                                                                                      | Alta     |
| G-02 | Completar favor no acredita XP ni fichas                                                                                                    | Alta     |
| G-03 | Favores y eventos duplicados (`posts` vs `favores`/`eventos`)                                                                               | Alta     |
| G-04 | Las escrituras de XP, estrellas y reconocimientos salen del cliente (`UserProfileStore.save`, `nominarBuenVecino`)                          | Alta     |
| G-05 | Reglas de Firestore sin cobertura para Comunidad ni economía, y desalineadas con el README                                                  | Alta     |
| G-06 | Mascota: perro comunitario, desbloqueo en nivel 25, cuidado gratis                                                                          | Media    |
| G-07 | `stars` es un entero; la calificación llega como `double`                                                                                   | Media    |
| G-08 | La insignia de la tarjeta de favor está fija en "+5 pts (10 XP)"                                                                            | Media    |
| G-09 | El formulario de ayuda no captura tamaño ni cantidad de ayudantes                                                                           | Media    |
| G-10 | `EstadoFavor` no tiene `vencido`, `enRevision`, `recompensaPendiente` ni `liberada`; `ParticipanteFavor` no tiene `cancelado` ni `noLlego`  | Media    |
| G-11 | `weeklyXp` y `xpPeriodo` no se reinician (no hay función programada)                                                                        | Media    |
| G-12 | Los SVG de `assets/` no figuran en `pubspec.yaml` (solo `OFL-Inter.txt`); los PNG nuevos tampoco                                            | Media    |
| G-13 | La curva `xp ~/ 100` está repetida en `user_profile.dart`, `login.dart`, `firestore_comunidad_repository.dart` y `vecino_detalle_page.dart` | Media    |
| G-14 | Posible divergencia entre el perfil en `shared_preferences` y el de Firestore                                                               | Baja     |

## 4. Decisiones

### 4.1 Ya tomadas

| ID   | Decisión                                                                                                   |
| ---- | ---------------------------------------------------------------------------------------------------------- |
| T-01 | La moneda se llama **ficha**                                                                               |
| T-02 | Por ahora existe **una sola caja** (`caja-1`), sin arte de caja abierta: la apertura se anima por código   |
| T-03 | Cinco ítems, de más a menos frecuente: `sombrero`, `sombrero-papel-barco`, `piruleta`, `shrek`, `mugiwara` |
| T-04 | Un ítem duplicado **devuelve la mitad del precio** en fichas (15). No hay fragmentos                       |
| T-05 | La curva de XP es **progresiva** (sección 5.6)                                                             |
| T-06 | El cuy tiene **una sola pose**; los ítems se colocan con un punto de anclaje (sección 6.3)                 |
| T-07 | "Cupo" se sustituye por "ayudantes" en todos los textos                                                    |
| T-08 | La verificación de la mochila con ML Kit la desarrolla otra persona; se acuerda un contrato (sección 5.10) |

### 4.2 Por tomar

| ID   | Decisión                                    | Recomendación                                                                                                                                                                                     |
| ---- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D-01 | ¿Dónde viven los favores?                   | **Un solo modelo.** Extender `posts` (categoría ayuda) con tamaño, ayudantes y estado, más la subcolección `participantes`. Alternativa: que publicar escriba en `favores`. Lo mismo para eventos |
| D-02 | ¿Quién calcula XP, fichas y penalizaciones? | **Cloud Functions**. Para una demo sin servidor se puede usar una transacción de cliente con reglas que limiten el incremento, pero es manipulable; si se hace, marcarlo como temporal            |
| D-03 | ¿Nivel de desbloqueo del cuy?               | **Nivel 2** (210 XP acumulados con la curva nueva, ≈ 7 favores medios)                                                                                                                            |
| D-04 | ¿Mascota personal o comunitaria?            | **Personal**: las cajas y los ítems requieren que cada vecino tenga la suya                                                                                                                       |
| D-05 | ¿Dónde se ve la billetera?                  | Saldo junto a Nivel y XP en Inicio; historial en Perfil                                                                                                                                           |
| D-06 | ¿Retención de recompensas?                  | Configurable: 24 h en producción, **1 a 5 minutos en la demo**                                                                                                                                    |
| D-07 | ¿Estrellas?                                 | Guardar `ratingSum` y `ratingCount` y mostrar el promedio (G-07)                                                                                                                                  |
| D-08 | ¿Dónde se guardan los parámetros?           | Documento `config/economia` en Firestore, de solo lectura para el cliente                                                                                                                         |

## 5. Diseño de integración

### 5.1 Principios técnicos

1. **El cliente pide, el servidor decide.** El cliente nunca escribe XP, fichas, estrellas, ranking ni inventario ganado.
2. **Un libro de movimientos.** El saldo se deriva de `movimientos`, y cada movimiento es inmutable.
3. **Idempotencia.** El id del movimiento se arma con tipo y origen (`favor_<favorId>_<uid>`); si la función se reintenta, el segundo intento falla al crear y no duplica el pago.
4. **Parámetros fuera del código.** Todo valor económico sale de `config/economia`.

### 5.2 Modelo de datos

```
config/economia                       (solo lectura cliente)
  retencionHoras: 24
  topeSemanalFichas: 150
  topeSemanalXp: 300
  curvaXp: { base: 100, incremento: 10 }
  recompensas: { mini: {fichas: 5, xp: 10}, medio: {15, 30}, grande: {40, 80}, comunitario: {30, 60} }
  caja1: { precio: 30, garantiaCajas: 20, reembolsoDuplicado: 15,
           probabilidades: { sombrero: .40, 'sombrero-papel-barco': .30, piruleta: .18, shrek: .09, mugiwara: .03 } }
  mascota: { nivelDesbloqueo: 2, costoAlimentar: 2 }
  confianza: { cuentaNuevaDias: 7, factorCuentaNueva: .5 }
  fiabilidad: { ventanaDias: 30, favoresALaVez: [3, 3, 2, 1] }

users/{uid}                           (perfil; la economía solo la escribe el servidor)
  xp (XP de nivel), weeklyXp (XP de liga), level,
  ratingSum, ratingCount, stats.*, badges, mochila.vigenteHasta
users/{uid}/economia/billetera        { disponible, pendiente, actualizadoEn }
users/{uid}/economia/semana           { semanaId, fichasGanadas, xpGanado }
users/{uid}/movimientos/{id}          { tipo, monto, xp, origen:{tipo,id}, estado, liberaEn, creadoEn }
users/{uid}/mascota/actual            { nombre, itemEquipado, pity, ultimaComida, cajaGratisUsada }
users/{uid}/inventario/{itemId}       { cantidad, obtenidoEn }
catalogo_items/{itemId}               { nombre, rareza, imagen, orden, dx, dy, escala }

posts/{id}  (categoría ayuda)         + tamano, cuposTotales, cuposTomados, estado,
                                        monedasRecompensa, xpRecompensa   <- los fija la función
posts/{id}/participantes/{uid}        { estado, aceptadoEn, terminadoEn, confirmadoEn, calificacion }
ranking/{distrito}/posiciones/{uid}   { xpPeriodo, xpTotal, ... }   (solo el servidor escribe)
```

`tipo` de movimiento: `ganancia`, `retencion`, `liberacion`, `gasto`, `reembolso`, `ajuste`, `penalizacion`.

### 5.3 Flujos

**A. Favor completo (el núcleo de la demo)**

1. Publicar: el formulario de ayuda pide **tamaño** (con ejemplos) y **cuántos ayudantes se necesitan**. Una función `onCreate` valida el tamaño y escribe `monedasRecompensa` y `xpRecompensa` desde `config/economia`; lo que mande el cliente se ignora.
2. Anotarse: se conserva la transacción de `aceptarFavor` (`cuposTomados`; cuando se llena, el estado pasa a "Completo"), aplicada a `posts/{id}`. En pantalla: "Ayudantes: 1 de 3" y botón "Quiero ayudar".
3. El ayudante pulsa "Terminé" y el vecino ayudado confirma y califica.
4. Al pasar a `completado`, la función `onFavorCompletado` calcula la recompensa (5.4), crea el movimiento `retencion` con `liberaEn = ahora + retencionHoras`, suma al `pendiente` de la billetera y actualiza `ratingSum` y `ratingCount` del ayudante.
5. La función programada `liberarPendientes` mueve el monto a `disponible`, suma XP a `xp` y `weeklyXp`, actualiza `ranking/{distrito}/posiciones/{uid}` y recalcula el nivel con la curva de 5.6.
6. Si hay un reporte durante la retención, el movimiento pasa a `enRevision` y no se libera.

**B. Cancelar o no presentarse**
La cancelación a tiempo libera el lugar del ayudante sin costo. Si el vecino ayudado marca "no llegó" y no hay contraprueba, `onNoLlego` resta XP de liga (≈ 50% del XP del favor) con tope semanal, descuenta un "no pude" gratuito por mes y suma un incumplimiento (5.5). No toca `xp` ni las fichas ganadas.

**C. Evento con asistencia verificada**
Hoy hay dos rutas: `posts/{id}/attendance` (Voy / Me interesa, usada por la UI) y `eventos/{id}/asistencias` (QR, sin usar). Unificar en `posts/{id}/attendance` con `verificada: true`. La verificación del QR pasa por una función que compara el código con el del organizador; el cliente no escribe `verificada`.

**D. Mochila**
Ver 5.10.

**E. Reconocimiento**
`nominarBuenVecino` hoy incrementa contadores del destinatario desde el cliente. Pasarlo a una función invocable que valide el límite semanal, que no sea uno mismo y que sean vecinos del mismo distrito.

**F. Abrir caja-1**
Función invocable `abrirCaja(requestId)`:

1. Verifica sesión, que el cuy esté desbloqueado y que la colección no esté completa.
2. En una transacción: lee billetera y mascota; si es la primera caja (`cajaGratisUsada = false`) no cobra; si no, valida saldo y descuenta el precio con un movimiento `gasto` cuyo id deriva de `requestId`.
3. Sortea con el generador criptográfico del servidor según `config/economia.caja1.probabilidades`. Si `pity >= garantiaCajas - 1`, entrega `mugiwara` y reinicia el contador; si no, lo incrementa.
4. Si el ítem es nuevo, crea `inventario/{itemId}`. Si ya se tenía, suma la cantidad y acredita un movimiento `reembolso` de **15 fichas** (la mitad del precio) directamente en `disponible`, sin retención.
5. Devuelve `{ itemId, nuevo, reembolso, pityRestante, saldo }`. La animación empieza solo al recibir la respuesta.

**G. Alimentar**
Fase inicial: se mantiene el botón actual, pero se guarda `ultimaComida` y se calcula el hambre con el tiempo en lugar de escribir un `double`. Fase posterior: `alimentarMascota` cobra `costoAlimentar` (2 fichas; con el paso de 0,20 equivale a unas 10 fichas por semana). Si el hambre llega a 1 el cuy "duerme"; no pierde nada.

### 5.4 Cálculo de recompensa (`onFavorCompletado`)

```
base            = config.recompensas[tamano]                  // ya coincide con TamanoFavor
pareja          = [1.0, 0.5, 0.25, 0][vecesEnTreintaDias]     // mismo par ayudante-solicitante
diversidad      = 1.25 si el solicitante es nuevo o de otra cuadra
mochila         = 1.05 si la mochila está vigente
confianza       = ver 5.5
fichas          = redondear(base.fichas * pareja * diversidad * mochila * confianza)
xp              = redondear(base.xp * pareja * confianza)
aplicar tope semanal (topeSemanalFichas / topeSemanalXp)
```

Primera iteración: solo `base`, `pareja` y topes. `diversidad`, `mochila` y `confianza` después. El bono de cadena queda fuera hasta que exista el flujo "pasar el favor".

### 5.5 Fiabilidad y confianza (versión mínima)

Son **dos números ocultos**: el vecino nunca los ve. Sirven para que el sistema ajuste límites y recompensas sin castigar públicamente. La "tabla" es simplemente la lista de reglas que dice cómo se calcula cada uno. Para la demo bastan las reglas de abajo; la versión con más factores y pesos queda para después.

| Número         | Qué mide                           | Qué controla                             | Regla mínima                                                                                                                                                   |
| -------------- | ---------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Fiabilidad** | Si cumple lo que promete           | Cuántos favores puede tener **a la vez** | Contar incumplimientos de los últimos 30 días: 0 o 1 → 3 favores a la vez; 2 → 2; 3 o más → 1. Cada 3 favores completados sin incumplir resta 1 incumplimiento |
| **Confianza**  | Qué tan establecida está la cuenta | Un multiplicador de lo que gana          | Cuenta con menos de 7 días → ×0,5. Un reporte confirmado en 30 días → ×0,75; dos o más → ×0,5. Se aplica el factor menor, sin acumular                         |

Lo que ve el vecino es solo un mensaje: "Tienes 2 favores en curso; termina uno para anotarte a otro". Si más adelante se quieren más factores (antigüedad, diversidad de vecinos ayudados, calificaciones), se añaden filas a esta tabla sin cambiar el resto del diseño.

### 5.6 Curva de XP progresiva

Cada nivel pide **10 XP más** que el anterior. El primer nivel cuesta 100 XP, el segundo 110, el tercero 120, y así. Los dos números (`base` e `incremento`) están en `config/economia.curvaXp`, de modo que se pueden ajustar sin tocar código.

```
XP necesario para pasar del nivel n al n+1  =  base + incremento * n
XP acumulado para alcanzar el nivel n       =  base * n + incremento * n * (n - 1) / 2
```

| Nivel       | XP para subir a este nivel | XP acumulado | Semanas, vecino activo (240 XP/semana) | Semanas, vecino casual (80 XP/semana) |
| ----------- | -------------------------- | ------------ | -------------------------------------- | ------------------------------------- |
| 1           | 100                        | 100          | 0,4                                    | 1,2                                   |
| **2 (cuy)** | 110                        | **210**      | 0,9                                    | 2,6                                   |
| 3           | 120                        | 330          | 1,4                                    | 4,1                                   |
| 5           | 140                        | 600          | 2,5                                    | 7,5                                   |
| 10          | 190                        | 1.450        | 6,0                                    | 18,1                                  |
| 15          | 240                        | 2.550        | 10,6                                   | 31,9                                  |
| 20          | 290                        | 3.900        | 16,2                                   | 48,8                                  |
| 25          | 340                        | 5.500        | 22,9                                   | 68,8                                  |

El ritmo se siente progresivo pero alcanzable: el cuy se desbloquea en menos de una semana de uso activo y el nivel 10 en unas 6. Si se quiere más suave, bajar `incremento` a 5 (nivel 25 en 4.000 XP). El tope semanal de XP (300) limita el ritmo máximo.

Código compartido (mismo cálculo en Dart y en TypeScript, con una prueba que compare ambas tablas):

```dart
int xpAcumulado(int nivel, {int base = 100, int incremento = 10}) =>
    base * nivel + incremento * nivel * (nivel - 1) ~/ 2;

int nivelDesdeXp(int xp, {int base = 100, int incremento = 10}) {
  var nivel = 0;
  while (xp >= xpAcumulado(nivel + 1, base: base, incremento: incremento)) {
    nivel++;
  }
  return nivel;
}

int xpEnNivelActual(int xp) => xp - xpAcumulado(nivelDesdeXp(xp));
int xpParaSiguiente(int xp) {
  final n = nivelDesdeXp(xp);
  return xpAcumulado(n + 1) - xpAcumulado(n);
}
```

**Dónde reemplazar la curva lineal (G-13):** `lib/home/user_profile.dart` (`level`, `xpEnNivelActual`, `petUnlocked`), `lib/home/login.dart` (`nivel`, `mascotaDesbloqueada`), `lib/features/comunidad/data/repositories/firestore_comunidad_repository.dart` (línea del `nivel:` con `~/ 100`) y `lib/features/comunidad/presentation/pages/vecino_detalle_page.dart` (`xpTotal % 100`). Revisar también los mocks y fixtures de Comunidad.

### 5.7 Funciones nuevas (`functions/src/economia/`)

| Función                | Disparador                         | Qué hace                                                 |
| ---------------------- | ---------------------------------- | -------------------------------------------------------- |
| `onFavorCreado`        | `posts` creado (ayuda)             | Valida tamaño y fija recompensa                          |
| `onFavorCompletado`    | `posts` actualizado a `completado` | Crea movimiento en retención, actualiza estrellas        |
| `liberarPendientes`    | Programada (cada 15 min)           | Libera pendientes vencidos, acredita XP, nivel y ranking |
| `onNoLlego`            | Participante marcado `noLlego`     | Penalización, incumplimiento, perdón mensual             |
| `reiniciarLigaSemanal` | Programada (lunes)                 | Pone `weeklyXp` y `xpPeriodo` en cero                    |
| `abrirCaja`            | Invocable                          | Flujo F                                                  |
| `alimentarMascota`     | Invocable                          | Flujo G (fase posterior)                                 |
| `reclamarBonoMochila`  | Invocable                          | Sección 5.10                                             |
| `nominarBuenVecino`    | Invocable                          | Flujo E                                                  |
| `verificarAsistencia`  | Invocable                          | Flujo C                                                  |

El proyecto ya usa `firebase-functions` v2 y pruebas con `node --test`; se mantiene ese patrón. Desplegar funciones requiere el plan Blaze; hay que confirmarlo antes de planificar.

### 5.8 Reglas de Firestore (lo que cambia)

```
match /config/{doc}            { allow read: if signedIn(); allow write: if false; }
match /catalogo_items/{id}     { allow read: if signedIn(); allow write: if false; }

match /users/{uid}/economia/{doc}      { allow read: if owns(uid); allow write: if false; }
match /users/{uid}/movimientos/{id}    { allow read: if owns(uid); allow write: if false; }
match /users/{uid}/inventario/{id}     { allow read: if owns(uid); allow write: if false; }

match /users/{uid}/mascota/actual {
  allow read: if owns(uid);
  allow update: if owns(uid)
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['nombre', 'itemEquipado'])
    && (!('itemEquipado' in request.resource.data.diff(resource.data).affectedKeys())
        || request.resource.data.itemEquipado == ''
        || exists(/databases/$(database)/documents/users/$(uid)/inventario/$(request.resource.data.itemEquipado)));
  allow create, delete: if false;
}

match /ranking/{distrito}/posiciones/{uid} { allow read: if signedIn(); allow write: if false; }
```

Además: reglas para `posts/{id}/participantes` (el cliente solo puede crear su propio participante en estado `aceptado` y marcar `terminado`), y quitar de `UserProfileStore.save` los campos que ahora son del servidor (`xp`, `weeklyXp`, `level`, `stars`, `favors`, `badges`, `stats`). Como `users/{uid}` solo lo lee su dueño, lo que se muestra de otros vecinos sale de la proyección pública `ranking/.../posiciones`.

### 5.9 Cambios en la app Flutter, por archivo

| Archivo                                                               | Cambio                                                                                                                                                                    |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/home/user_profile.dart`, `lib/home/login.dart`                   | Usar la curva de 5.6; `ratingSum`/`ratingCount` y estrellas como promedio; dejar de escribir campos económicos; nivel de desbloqueo desde `config/economia`               |
| `lib/home/home.dart`                                                  | Mostrar fichas junto a nivel y XP; reemplazar `_mascota()` por la tarjeta del cuy (`cuy-logo`) que abre `MascotaPage`; texto "Alcanza el nivel 2"                         |
| `lib/home/tutorial.dart`                                              | Actualizar el paso de mascota; añadir paso de ficha y billetera; primera caja gratis                                                                                      |
| `.../comunidad/presentation/tabs/favores_tab.dart`                    | Mostrar tamaño, "Ayudantes: 1 de 3" y recompensa real (`_PointsBadge` usa valores fijos y dice "pts"); botón "Quiero ayudar"; seguimiento (terminé, confirmar, calificar) |
| `.../comunidad/domain/entities/favor.dart`                            | Etiqueta `Completo` en lugar de "Cupos llenos"; estados `vencido`, `enRevision`, `recompensaPendiente`, `liberada`; participante `cancelado`, `noLlego`                   |
| `.../comunidad/data/repositories/firestore_comunidad_repository.dart` | Operar sobre `posts` (D-01); quitar escrituras de ranking y reconocimientos del cliente                                                                                   |
| `.../create_post/presentation/forms/help/`                            | Campo de tamaño con ejemplos y de ayudantes necesarios                                                                                                                    |
| `.../ayuda_prevencion/widgets/mochila_emergencia_card.dart`           | Botón "Reclamar bono" (ver 5.10)                                                                                                                                          |
| `.../comunidad` (ranking, perfil de vecino)                           | Mostrar insignias con `assets/insignias/<id>.png`                                                                                                                         |
| `pubspec.yaml`                                                        | Declarar `assets/` y cada carpeta nueva (Flutter no incluye subcarpetas automáticamente)                                                                                  |
| `lib/main.dart`                                                       | Inyectar `EconomiaRepository` y `MascotaRepository`, igual que `comunidadRepository`                                                                                      |

Carpetas nuevas, con el patrón repositorio + mock + Firestore del proyecto:

```
lib/features/economia/{domain, data, presentation}     billetera, movimientos, saldo, curva de XP
lib/features/mascota/{domain, data, presentation}      mascota_page, caja_sheet, coleccion_page, mascota_stage
assets/mascota/                                         cuy-base.png, cuy-logo.png, caja-1.png, fondo
assets/mascota/items/                                   sombrero, sombrero-papel-barco, piruleta, shrek, mugiwara
assets/insignias/                                       una imagen de 96 × 96 por insignia
functions/src/economia/                                 funciones de 5.7
```

### 5.10 Contrato con el módulo de mochila (ML Kit, otra persona)

La economía no verifica nada: solo lee el resultado. Para trabajar en paralelo, se acuerda esta interfaz:

```dart
abstract interface class MochilaEstado {
  Stream<MochilaVerificacion> observar();
}

class MochilaVerificacion {
  final bool completa;            // todos los artículos obligatorios verificados
  final DateTime? vigenteHasta;   // fecha de vencimiento más cercana entre los artículos
  final DateTime verificadoEn;
}
```

- **Mientras no esté el módulo de ML Kit:** una implementación mock que lea el checklist local actual (`BackpackChecklistStore`) y marque `completa` cuando todos los artículos estén marcados. Así la economía se puede probar hoy.
- **Del lado de la economía:** el botón "Reclamar bono" se habilita cuando `completa` es verdadero y `vigenteHasta` es futura, y llama a `reclamarBonoMochila(vigenteHasta)`.
- **En el servidor:** la primera vez entrega el bono único (50 fichas y 100 XP) y la insignia `vecino-preparado`; una renovación solo se acepta si la vigencia anterior venció o falta menos de 30 días, y da 15 fichas y 30 XP. `vigenteHasta` se limita a 6 meses desde hoy. Mientras esté vigente, aplica el ×1,05 de 5.4.
- **Limitación:** ML Kit corre en el teléfono, así que el servidor confía en lo que reporta el cliente. Se mitiga con el bono único, las renovaciones limitadas y los topes semanales.

## 6. Ventana de la mascota

### 6.1 Pantallas

Se abre al tocar la tarjeta del cuy en Inicio. Vistas: **Mi cuy** (principal), **Confirmar caja**, **Resultado**, y como secundarias **Objetos** (colección) y **Billetera** (historial).

**Mi cuy:** barra con nombre (editable) y saldo en fichas; escenario con fondo, cuy y el ítem equipado; botón "Abrir caja · 30 fichas"; botones Objetos y Cuidar; barra de garantía ("12 de 20"). Al tocar el cuy reacciona.

**Confirmar caja:** imagen `caja-1`, precio, saldo, enlace a probabilidades y garantía. Botones Abrir y Cancelar.

**Resultado:** "¡Nuevo!" o "Repetido: te devolvemos 15 fichas", nombre y rareza, y Ponérselo / Guardar. La animación se puede saltar con un toque.

**Objetos:** cuadrícula de 5 espacios (obtenidos a color; faltantes en silueta con su rareza), contador "3 de 5" y botón Equipar / Quitar.

### 6.2 Caja-1: ítems, probabilidades y duplicados

| Orden | Id (archivo)           | Rareza     | Probabilidad |
| ----- | ---------------------- | ---------- | ------------ |
| 1     | `sombrero`             | Común      | 40%          |
| 2     | `sombrero-papel-barco` | Común      | 30%          |
| 3     | `piruleta`             | Raro       | 18%          |
| 4     | `shrek`                | Raro       | 9%           |
| 5     | `mugiwara`             | Legendario | 3%           |

- **Precio:** 30 fichas. **Garantía:** tras 20 cajas sin `mugiwara`, la siguiente lo entrega. **Primera caja:** gratis.
- **Duplicado:** devuelve 15 fichas (la mitad del precio), siempre el mismo monto, sin importar la rareza.
- **Probabilidades siempre visibles**, y la caja **no se compra con dinero real**.

Resultado de simular 100.000 vecinos completando la colección (con la primera caja gratis, garantía de 20 y reembolso de 15):

|                                     | Con reembolso (diseño actual)                       | Sin reembolso |
| ----------------------------------- | --------------------------------------------------- | ------------- |
| Cajas pagadas (media)               | 18,3 (mediana 19; 9 de cada 10 vecinos, 25 o menos) | 18,3          |
| Fichas netas para completar (media) | **335** (mediana 345; 9 de cada 10, 435 o menos)    | 550           |
| Tiempo con 120 fichas/semana        | ≈ 3 semanas                                         | ≈ 4,6 semanas |

El reembolso hace la colección más barata y nunca deja ganancia (siempre devuelve menos de lo que cuesta), así que no abre una vía de farming. Una vez completa la colección, la caja se bloquea ("Colección completa") hasta que haya ítems nuevos; para no secar la economía hay que prever más ítems o cajas, además de los otros sumideros (alimentar, tienda, descuentos).

### 6.3 Medidas, capas y una sola pose

| Recurso    | Medida       | Uso                                                     |
| ---------- | ------------ | ------------------------------------------------------- |
| `cuy-base` | 540 × 540 px | Personaje en el escenario                               |
| `cuy-logo` | 144 × 144 px | Ícono de la mascota: tarjeta de Inicio y perfil público |
| `caja-1`   | 360 × 360 px | Confirmar caja y animación                              |
| ítems      | 192 × 192 px | Cuadrícula de Objetos y ítem puesto en la cabeza        |
| insignia   | 96 × 96 px   | Ranking, perfil de vecino y Perfil                      |
| fondo      | sin definir  | Escenario (ver pendientes)                              |

**Cambia respecto a la propuesta anterior:** los ítems ya no son del mismo lienzo que el cuy (192 contra 540), así que se colocan con un **punto de anclaje**. Con una sola pose basta una constante:

```dart
// Punto de la cabeza (en píxeles del lienzo 540 × 540) donde va el CENTRO del ítem.
// Se mide una sola vez sobre cuy-base.png.
const cuyAnclaje = Offset(270, 110);

// En el escenario, con k = anchoDelEscenario / 540:
// Positioned(
//   left: (cuyAnclaje.dx + item.dx - 96 * item.escala) * k,
//   top:  (cuyAnclaje.dy + item.dy - 96 * item.escala) * k,
//   width:  192 * item.escala * k,
//   height: 192 * item.escala * k,
//   child: Image.asset(item.imagen),
// )
```

`dx`, `dy` y `escala` por ítem vienen de `catalogo_items` (valores iniciales 0, 0 y 1), así se afina cada sombrero sin tocar código. Si más adelante hay otra pose, el catálogo guarda un anclaje por pose (`anclajes: { base: {x, y}, dormido: {x, y} }`).

**Sin más poses, los estados se resuelven con animación y superposiciones:**

| Estado              | Cómo se muestra                                            |
| ------------------- | ---------------------------------------------------------- |
| Reposo              | Balanceo suave en bucle (leve escala y desplazamiento)     |
| Toque               | Salto corto y un ícono sobre la cabeza                     |
| Hambre alta         | Un poco desaturado y más quieto                            |
| Dormido             | Desaturado más inclinación leve y "Zzz" como texto o ícono |
| Ítem nuevo equipado | Pequeño rebote del ítem                                    |

**Nitidez:** si el cuy se muestra a unos 300 dp de ancho en un teléfono de alta densidad, los 540 px quedan algo blandos. No bloquea nada; si hay tiempo, exportar al doble (1080 y 384 px) y declararlos como variante 2.0x.

**Insignias:** el perfil ya guarda `badges` (lista de ids) y `VecinoPerfil` e `VecinoRanking` ya tienen `insignias`. Cada id se asocia a `assets/insignias/<id>.png`. Faltan definir cuáles son; propuestas: `vecino-preparado` (mochila), `buen-vecino` (semana), `primer-favor`, `racha-4`.

### 6.4 Animación de apertura sin arte de caja abierta

Se hace por código con `caja-1` (1,5 a 2 s, saltable):

1. 0 a 0,8 s: la caja tiembla cada vez más (rotación de ±3° a ±8°) y late (escala 1,0 a 1,08).
2. 0,8 a 1,0 s: destello blanco, la caja crece y se desvanece.
3. 1,0 a 1,6 s: el ítem aparece pequeño y rebota hasta su tamaño, sobre un halo cuyo color depende de la rareza (neutro para común, azul para raro, dorado para legendario).
4. 1,6 s: aparece el texto de resultado y los botones.

### 6.5 Estados de la ventana

| Situación                       | Comportamiento                                                       |
| ------------------------------- | -------------------------------------------------------------------- |
| Nivel inferior al de desbloqueo | Silueta con candado y "Se desbloquea en nivel 2"                     |
| Primera vez                     | El cuy "llega" y se regala **una caja gratis** para mostrar el flujo |
| Sin saldo                       | Botón gris "Te faltan X fichas" y atajo a Comunidad                  |
| Sin conexión                    | Se ve y se equipa lo ya descargado; abrir caja requiere conexión     |
| Colección completa              | Botón de caja bloqueado: "Colección completa"                        |
| Hambre al máximo                | El cuy "duerme"; sin pérdidas                                        |

## 7. Plan por fases

| Fase                    | Contenido                                                                                                                                                                              | Tamaño | Criterio de aceptación                                                                                                           |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------- |
| **F0** Alineación       | Decidir D-01 a D-08; confirmar reglas desplegadas y plan Blaze; declarar assets; crear `config/economia`                                                                               | S      | Decisiones registradas; la app arranca con los assets declarados                                                                 |
| **F1** Núcleo económico | Billetera y movimientos; curva de XP compartida; `onFavorCompletado` y `liberarPendientes`; reglas; saldo en Inicio; historial                                                         | M      | Un favor confirmado en el emulador acredita fichas y XP tras la retención, sin duplicarse al reintentar; el nivel sigue la curva |
| **F2** Favores en la UI | Tamaño y ayudantes al publicar; Quiero ayudar, Terminé, Confirmar y calificar; recompensa real en la tarjeta                                                                           | M      | Flujo completo entre dos usuarios de prueba, sin pasarse del máximo de ayudantes                                                 |
| **F3** Mascota          | `MascotaPage`, cuy con anclaje, fondo, ítem equipado, desbloqueo, tutorial, `cuy-logo` en Inicio                                                                                       | M      | El cuy se ve con cada ítem bien colocado y persiste al reabrir                                                                   |
| **F4** Caja-1           | `abrirCaja`, probabilidades, garantía, reembolso de duplicados, animación por código, caja gratis                                                                                      | M      | El saldo baja una sola vez por caja, el duplicado devuelve 15 fichas y la garantía se cumple                                     |
| **F5** Complementos     | Penalización y fiabilidad, QR de eventos, bono de mochila (con el contrato de 5.10), reconocimiento por servidor, liga semanal, modificadores (pareja, diversidad, mochila, confianza) | L      | Cada regla con su prueba                                                                                                         |

**Mínimo para la demo del reto:** F0 a F4, más el bono de mochila de F5 si el módulo de ML Kit ya está (o con el mock). La penalización y los modificadores pueden mostrarse como hoja de ruta.

## 8. Pruebas

- **Functions** (`node --test`, como `geo.test.js` y `emergency_projection.test.js`): recompensa por tamaño y modificadores, topes, idempotencia del movimiento, sorteo de caja con generador inyectable y semilla fija, garantía, reembolso de duplicado y curva de XP.
- **Paridad de la curva:** una prueba en Dart y otra en TypeScript que comparen contra la tabla de 5.6.
- **Reglas:** ampliar `test/firebase_rules_test.mjs` con casos negativos: el cliente no puede escribir en `movimientos`, `billetera`, `inventario`, `ranking` ni en campos económicos de `users`, y solo puede equipar ítems que posee.
- **Flutter:** repositorios mock de economía y mascota (patrón de `mock_comunidad_repository.dart`); pruebas de widget de `MascotaPage` para cada estado de 6.5 y del flujo de caja; actualizar `vecinos_ranking_test.dart` y `comunidad_test.dart` si cambia el origen de datos.
- **Emulador:** ejecutar el flujo A completo con retención de 1 minuto.

## 9. Riesgos

| Riesgo                                                               | Mitigación                                                                                                                                                                        |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Reglas desplegadas distintas a las del repositorio                   | Confirmar en la consola antes de F1 y desplegar desde el repositorio                                                                                                              |
| Plan Blaze no activo para las funciones                              | Confirmarlo en F0; si no es posible, usar la transacción de cliente marcada como temporal                                                                                         |
| Cuentas falsas por ingreso anónimo y código fijo                     | Confianza reducida en cuentas nuevas y tope semanal; documentar que el SMS real queda pendiente                                                                                   |
| Dos modelos de favores sin unificar                                  | Resolver D-01 en F0 antes de escribir pantallas                                                                                                                                   |
| Con 5 ítems la colección se agota en unas 3 semanas                  | Plan de ítems nuevos o de temporada                                                                                                                                               |
| Dependencia del módulo de ML Kit                                     | Contrato de 5.10 y mock con el checklist actual                                                                                                                                   |
| Ítems `shrek` y `mugiwara` aluden a personajes con derechos de autor | Aceptable en una demo cerrada; si la app se publica en una tienda, conviene rediseñarlos o renombrarlos como ítems originales (por ejemplo "orejas de ogro" y "sombrero de paja") |
| Alcance excesivo para el plazo                                       | Priorizar F0 a F4; el resto como hoja de ruta                                                                                                                                     |
| Datos locales (`shared_preferences`) que contradicen al servidor     | El servidor manda; lo local solo sirve de caché de lectura                                                                                                                        |

## 10. Pendientes

- Medida y proporción del **fondo** (sugerencia: vertical, por ejemplo 1080 × 1920 px, con el cuy abajo al centro y espacio libre arriba).
- Medir el **punto de anclaje** de la cabeza sobre `cuy-base`.
- Lista de insignias y su condición.
- Nivel exacto de desbloqueo del cuy (recomendado: 2) y si el incremento de la curva es 10 o 5.
- Cantidad de ayudantes por defecto en el formulario de ayuda.
- Decisión D-01 (modelo único de favores) y D-02 (quién escribe la economía).
- Qué ítems o cajas se agregarán después de caja-1.
