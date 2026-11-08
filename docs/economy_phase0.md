# Economía vecinal — Fase 0 y decisiones aprobadas
Fecha de inspección: 8 de noviembre de 2026.
Base revisada: c99047e5dd256542bc0922df52aa74c0dcd1e22e, rama bd-firebase.

## Precedencia y alcance
Se sigue prompt_veciapp_economia_ranking_mensual.md. La arquitectura adjunta sirve de intención, no se copia su implementación.
Las aclaraciones del usuario prevalecen: ranking mensual por distrito con textos «del barrio»; Inicio conserva XP y Star; monedas visibles en perfil; mochila se verificará mediante fotografía en una implementación futura. Dos usos distintos del mismo servicio pueden premiarse, hasta dos por pareja y mes. Reintentar una misma confirmación no consumirá otro cupo.

No SQLite, perfiles paralelos, colecciones servicios/noticias, fechas fijas de semilla ni recompensas de mochila por marcar un checklist. No se convierten estrellas en monedas.
Fases 0 y 1 autorizadas. Motor, Visto Bueno, Top 3, conexión visual del ranking y simulador pertenecen a fases posteriores.

## Hallazgos
- Identidad: FirebaseAuthGateway.currentUid usa Firebase Auth. Google está implementado. El teléfono es una simulación con código fijo y sesión anónima (firebase_auth_gateway.dart:65). La recuperación por teléfono no prueba identidad.
- UserProfileStore guarda users/{uid}. Las escrituras de registro, edición y mascota utilizaban el mapa completo, incluyendo xp, weeklyXp, stars y level (home/user_profile.dart:124,267 en la base).
- Datos personales, ubicación precisa y token FCM estaban en users. SOS y functions/src/index.ts leen esos campos. Se autoriza su separación, conservando los documentos y proyecciones SOS existentes.
- Inicio carga perfil mediante FutureBuilder (home/home.dart:314). Hay XP real si existe perfil, respaldo local y nivel xp ~/ 100. No hay saldo de monedas implementado.
- Favores: pestaña usa posts/category=help, puntos +5 pts (10 XP) decorativos. No tiene acción activa para completar una ayuda. Los métodos antiguos en favores no están conectados a esta pestaña.
- Eventos: posts/{id}/attendance/{uid} guarda going/notGoing. Es intención de asistir; no prueba asistencia ni concede XP.
- Servicios: Pedir/Contratar abre contacto. No hay Visto Bueno ni transacción de recompensa.
- Buen vecino: solo Comunidad/Vecinos, vecinos_tab.dart:160 en la base. Card elevación 2, radio 14, borde 1.5, Container con gradiente y padding 16. El Top 3 reutilizará ese contenedor y posición. Conservar estilos existentes no obliga a agregar literales nuevos.
- Lista Vecinos: ranking/{distrito}/posiciones ordenado por xpPeriodo; alternativa users; semilla automática de Ate tanto desde main como desde el repositorio. Todavía es semanal.
- Mochila: checklist en shared_preferences sin vigencia/verificación. Mascota: nivel 25, hambre persistida; no hay coste económico definido.
- Comunidad mantiene Favores/Servicios/Eventos/Vecinos, sin Hoy. Servicios y Noticias están en posts, clasificador existente y feeds con snapshots.
- Reglas locales: users era privado y limitado a campos SOS, incompatible con ciertos escritores actuales. Índices cubren posts y SOS, no el ranking mensual. No se verificaron los despliegues reales.
- No sqflite. Firestore conserva su configuración del SDK; en web no se añade persistencia en disco automáticamente.

## Matriz de brechas al inicio
| Requisito | Estado | Evidencia en la base | Acción |
|---|---|---|---|
| R1 Perfil tras autenticar | Parcial | home/user_profile.dart:267; home/login.dart:648 | ensureUser transaccional |
| R2 Economía del usuario | Parcial | home/user_profile.dart:77 | Extender perfil y cuenta privada |
| R3 Reinicio mensual | Falta | firestore_comunidad_repository.dart:200 | PeriodProvider y reinicio perezoso |
| R4 Motor/libro | Falta | No hay movimientos ni motor | Fase 2 |
| R5 Visto Bueno | Falta | servicios_tab.dart:223 | Transacción, dos cupos, identidad y operación idempotente, fase 2 |
| R6 Botón | Falta | servicios_tab.dart:158 | Fase 4 |
| R7 Favores/Eventos | Parcial | firestore_comunidad_feed_repository.dart:80 | Sin premios por RSVP; extensión futura |
| R8 Top 3 | Parcial | vecinos_tab.dart:160 | Reutilizar contenedor, fase 3 |
| R9 Ranking real mensual | Parcial | firestore_comunidad_repository.dart:200 | Stream por distrito, fase 3 |
| R10 Inicio/perfil | Parcial | home/home.dart:314 | Streams y monedas en perfil, fase 3 |
| R11 Seguridad/índices | Parcial | firestore.rules:123; firestore.indexes.json | Separación y protección fase 1; premios fase 2 |
| R12 Demostración | Parcial | main.dart:60 | Desactivar siembra automática; seeder/simulador fase 5 |
| R13 Comunidad anterior | Implementado | comunidad_page.dart:47; feed repository:25 | No reimplementar |
| R14 Pruebas/docs | Parcial | test/vecinos_ranking_test.dart:22 | Ampliar por fase |

## Suposiciones y asuntos diferidos
La inspección corresponde a archivos locales, no garantiza contenido, plan ni reglas desplegadas en Firebase.
No hay bono retroactivo a perfiles existentes. No se traslada weeklyXp al mes actual ni se reduce xp.
El nombre se obtiene del perfil existente; fallback Vecino. Se conserva level = xp ~/ 100.
Las monedas y las estrellas son distintas. La nueva verificación de mochila y su vigencia necesitan especificación posterior; no bloquean fase 1.
La arquitectura original no modifica el reparto +15/+25 ni introduce monedas por servicios.
Se usarán reglas comprobadas en emulador, no garantías solo de UI. Dos IDs de cupo no bastan para idempotencia: fase 2 también necesita una clave estable de operación.

## Impacto planificado
Nuevos archivos en features/economy/domain (modelos, periodos, interfaces) y data (repositorio y plan de inicialización).
Integraciones en main, UserProfileStore y login. Ajustes privados en CommunityFeedPage y Cloud Functions, reglas e índices.
La interfaz del ranking se conserva hasta fase 3. Su texto cambiará a mes y barrio entonces.
Pruebas de periodos/modelos/migración/reglas, documentación de despliegue y de privacidad.

