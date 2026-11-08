# Economía y ranking mensual — fases 0 a 2

## Estado y alcance
Se implementan la inicialización del usuario, privacidad, periodo mensual y consultas de economía. El motor de Visto Bueno está implementado e inyectado; su botón y la sustitución visual de la tarjeta/lista del ranking pertenecen a fases posteriores. Inicio sigue mostrando XP y Star. Las monedas se conectarán al perfil en fase 3, sin añadirlas a Inicio.
El motor permite dos confirmaciones mensuales por pareja para usos distintos, incluso del mismo post, con una clave de operación estable para evitar duplicados. Consulta economy_phase2.md para el protocolo y las pruebas.
No se paga por marcar Voy/No voy ni por completar el checklist local. La fotografía de mochila pertenece a un flujo futuro.

## Una sola identidad y un solo perfil
Firebase Auth define el UID. Google mantiene su flujo actual. El teléfono es de demostración, no SMS real: phoneExists/loadByPhone solo consultan el teléfono del UID autenticado, nunca recuperan otro usuario desde phoneIndex. El índice antiguo queda inaccesible desde clientes.
No se crea una colección paralela de perfiles. AppUser es una vista económica del mismo users/{uid}; UserProfile conserva sus interfaces.
Un usuario anónimo que pierda su credencial no podrá recuperar su progreso solo escribiendo el teléfono. Las cuentas Google deben usar su autenticación real.

## Equivalencias y documentos
| Guía | Campo persistido | Ubicación |
|---|---|---|
| xpTotal | xp (existente) | users/{uid} |
| xpMesActual | monthlyXp | users/{uid} |
| periodoRanking | rankingPeriod | users/{uid} |
| nombre | name (existente) | users/{uid} |
| monedasDisponibles | availableCoins | users/{uid}/private/account |
| estrellasPromedio / totalResenas | averageStars / reviewCount | users/{uid} |
| telefono / email | phoneNumber / email | users/{uid}/private/account |

El campo stars existente no se usa como moneda. weeklyXp se conserva como legado sin trasladarlo al mes.
El nivel se calcula xp ~/ 100. Las nuevas escrituras no guardan level.
districtKey normaliza el distrito para consultas; el texto visible posterior será «del barrio».
profileVersion=1 indica que el documento fue saneado. Las consultas públicas filtran ese marcador. Los documentos antiguos son legibles únicamente por su dueño hasta migrarse.
La ubicación precisa, geohash, consentimiento y token FCM se guardan en users/{uid}/private/proximity. communityId queda en el documento público para las reglas existentes de comunidad.
users/{uid}/movimientos es legible solo por el dueño. Las escrituras requieren una confirmación nueva y ambos premios en la misma operación atómica; los documentos son inmutables.

## Inicialización atómica y migración
ensureUser lee usuario, cuenta privada y datos de proximidad antes de escribir, en una sola transacción.
- Nuevo documento: 20 XP total, 20 XP mensual, 10 monedas, promedio y reseñas en cero.
- Existente: conserva XP, monedas, reputación y datos anteriores. Añade campos faltantes; no concede bono retroactivo.
- Migra teléfono/correo/saldo y ubicación/token a privado y elimina esos campos del documento público en la misma transacción.
- Conserva los datos privados existentes frente a valores viejos del documento público.
- Un periodo anterior se cambia al actual y monthlyXp pasa a cero; uno futuro nunca se retrocede.
- Guardar nombre, biografía o mascota ya no reproduce XP, estrellas ni estadísticas desde una copia desactualizada.
- Al terminar el acceso se asegura el usuario sin bloquear la pantalla principal. Un fallo muestra aviso con reintento. Guardar el perfil también vuelve a asegurar el usuario.

La migración es perezosa por propietario. No se ha ejecutado una migración masiva ni se han tocado documentos de producción.
No abrir al público documentos antiguos antes de retirar sus datos privados.

## Tiempo, lecturas y ranking
SystemPeriodProvider calcula YYYY-MM en UTC−5 (Lima). FakePeriodProvider permite pruebas y futura simulación.
AppUser.effectiveMonthlyXp devuelve cero para cualquier periodo distinto del actual, sin reducir XP total, nivel ni monedas.
watchUserStats combina el documento público con la cuenta privada y actualiza la evaluación de mes cada minuto.
watchMonthlyLeaderboard requiere un distrito y consulta profileVersion=1, districtKey, rankingPeriod actual, monthlyXp>0; ordena por monthlyXp descendente y xp descendente. Renueva la suscripción al cambiar de mes.
watchTopThreeOfMonth usa la misma consulta con límite 3.
Las transacciones económicas requieren conexión. No se añade SQLite. No se promete persistencia entre recargas de Chrome.

## Reglas y privacidad
Las reglas permiten altas acotadas y cambios de perfil. Niegan incrementos arbitrarios de XP, monedas, promedio o reseñas. La fase 2 permite premios exactos y movimientos solo dentro del protocolo atómico de Visto Bueno.
Valida el periodo con request.time menos cinco horas. Un periodo futuro ya almacenado puede conservarse para editar datos no económicos, pero no introducirse mediante un alta ni usarse para resetear hacia atrás.
Las reglas conservan posts y SOS. Se añade cobertura para la asistencia existente a eventos, limitada al UID propietario.
El cliente no puede leer private/account ni private/proximity de otro usuario.
La siembra automática se elimina del arranque. El método legado permanece pero solo se habilita con ENABLE_DEMO_SEED y un proyecto demo; el seeder nuevo se entrega en fase 5.
Persisten riesgos de cuentas anónimas múltiples para el futuro motor. La identidad anónima no acredita que dos personas sean diferentes. El control de producción debe reforzarse con autenticación verificable y lógica de servidor.

## Compatibilidad de SOS y orden de despliegue
Las funciones consultan ubicaciones antiguas y privadas durante la transición, deduplican por UID y mantienen nearby_emergency_alerts en el mismo lugar. Las notificaciones de cierre leen el token privado con fallback antiguo.
Antes de distribuir el cliente nuevo:
1. Desplegar firestore:indexes y esperar que estén listos.
2. Desplegar las funciones SOS actualizadas.
3. Desplegar firestore:rules.
4. Actualizar el cliente y verificar el acceso de una cuenta existente y una nueva.

Comandos, desde el proyecto original:
```powershell
firebase deploy --only firestore:indexes
firebase deploy --only functions
firebase deploy --only firestore:rules
flutter run -d chrome
```
Estos despliegues requieren acceso al proyecto. No se han ejecutado automáticamente.
Incluidos índices compuestos para el ranking mensual del distrito y la consulta de proximidad privada de Cloud Functions.
Mantener los índices SOS anteriores mientras existan usuarios sin migrar.

## Verificación local
```powershell
flutter analyze --no-pub
flutter test --no-pub
npm --prefix functions ci
npm --prefix functions test
firebase emulators:exec --project demo-hackaton-hello-world --only auth,firestore,storage "node test/firebase_rules_test.mjs && node test/economy_rules_test.mjs"
flutter build web --debug --no-pub
```
economy_phase1_test.dart cubre límites de mes en Lima, parseo int/double, nivel, bono único, migración, conservación y periodos futuros.
economy_rules_test.mjs usa únicamente emuladores locales. Verifica privacidad, bono atómico, doble alta concurrente, rechazos de aumentos libres, migración de legado, periodos y orden/filtros del ranking.
Las pruebas existentes se conservan. Los fixtures antiguos no se insertan en producción.

## Impacto en UI de esta fase
- main.dart: inyección de interfaces y aviso discreto/reintento al fallar la sincronización. Misma navegación y diseño.
- community_feed_page.dart: cambia la ruta de datos privados de consentimiento; mismos controles y textos.
- vecino_detalle_page.dart: se retira una variable sin uso; sin efecto visual.
- Login: adaptación de persistencia e identidad; mismas pantallas.
No se cambian colores, tipografía, iconos, layout ni tarjeta/ranking. El motor de fase 2 está completado; las fases 3–6 siguen pendientes.


## Resultado de verificación de fase 1
- flutter analyze --no-pub: sin incidencias.
- flutter test --no-pub: 130 pruebas aprobadas.
- npm --prefix functions test: compilación TypeScript y 4 pruebas aprobadas.
- Emuladores Auth/Firestore/Storage: suite anterior y nueva suite de economía aprobadas.
- flutter build web --debug --no-pub: compilación correcta.
- No se desplegaron reglas, índices ni funciones en Firebase real.
- No se añadieron paquetes Flutter ni se cambiaron versiones. Las dependencias de funciones se instalaron desde su package-lock existente. El equipo usa Node 24 y el runtime declarado es Node 20; npm informó esa diferencia, pero la compilación y las pruebas pasaron.

## Archivos de esta entrega
- lib/main.dart
- lib/home/user_profile.dart
- lib/home/login.dart
- lib/home/home.dart
- lib/features/economy/data/user_initialization.dart
- lib/features/economy/data/firestore_user_repository.dart
- lib/features/economy/domain/services/period_provider.dart
- lib/features/economy/domain/models/app_user.dart
- lib/features/economy/domain/repositories/user_repository.dart
- lib/features/community/presentation/community_feed_page.dart
- lib/features/comunidad/presentation/pages/vecino_detalle_page.dart
- lib/features/comunidad/domain/entities/vecino_ranking.dart
- lib/features/comunidad/data/repositories/firestore_comunidad_repository.dart
- test/economy_rules_test.mjs
- test/economy_phase1_test.dart
- test/vecinos_ranking_test.dart
- docs/economy_phase0.md
- docs/economy_and_ranking.md
- functions/src/index.ts
- firestore.rules
- firestore.indexes.json

Impacto adicional de home.dart: al cerrar sesión se limpia también el UID de la caché local. Login asocia la caché con ese UID y sincroniza el registro en segundo plano con aviso/reintento. No hay cambios visuales adicionales.
