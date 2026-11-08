# Revisión del avance — 8 de noviembre de 2026

Revisión del código local de Hackaton-Hello-World, contrastado con
`prompt_veciapp_economia_ranking_mensual.md` y las aclaraciones del usuario.
No confirma el estado desplegado en Firebase.

## Correcciones de esta revisión

- `lib/features/ayuda_prevencion/services/backpack_checklist_store.dart`:
  `static Future> load()` era sintaxis inválida. Se restaura el retorno
  `Future<Map<String, bool>>`, conservando checklist y persistencia de fotos.
  Los errores posteriores sobre `Future` y acceso estático eran consecuencia
  de esa declaración incompleta.
- La prueba `lib/features/comunidad/top_three_monthly_card_test.dart` se mueve
  a `test/top_three_monthly_card_test.dart`. Sus cuatro imports `package:veciapp/`
  se corrigen a `package:hackaton_hello_world/`, como indica pubspec.yaml.
  Se conserva el contenido de sus cuatro casos. Al quedar en test, Flutter
  puede descubrirla normalmente y flutter_test no se importa desde lib.

## Fases del plan

| Fase | Estado observado | Evidencia |
|---|---|---|
| 0 — Inspección | Documentada | docs/economy_phase0.md |
| 1 — Usuarios, periodo y seguridad | Implementación existente; sin revalidación en esta revisión | lib/features/economy/data/firestore_user_repository.dart, domain/models/app_user.dart, firestore.rules, firestore.indexes.json |
| 2 — Motor económico de Servicios | Implementación existente; nuevas extensiones requieren revisión | lib/features/economy/domain/services/service_economy_engine.dart, test/economy_engine_test.dart, test/service_economy_rules_test.mjs |
| 3 — Top 3, Vecinos, Inicio y perfil | Código integrado; validación pendiente | lib/features/comunidad/presentation/tabs/vecinos_tab.dart, lib/home/home.dart, lib/home/mi_perfil.dart |
| 4 — Visto Bueno y estrellas | Código integrado; validación y ajustes pendientes | lib/features/comunidad/presentation/tabs/servicios_tab.dart |
| 5 — Seeder y simulador ocultos | Parcial | lib/features/economy/data/demo_ranking_seeder.dart, domain/services/period_provider.dart, lib/main.dart, vecinos_tab.dart |
| 6 — Documentación y verificación final | Pendiente | La documentación anterior describe hasta fase 2; falta validar la matriz completa y documentar las herramientas nuevas |

El desarrollo llegó a la fase 5, pero no corresponde considerar cerradas las
fases 3–5 ni la verificación final.

## Pendientes concretos encontrados por lectura

1. `FirestoreUserRepository.ensureUser` usa `periods.currentPeriod` para
   construir los datos que escribe. Ahora recibe un SimulatablePeriodProvider:
   durante la simulación podría intentar guardar el mes futuro al inicializar
   o actualizar el perfil. Las reglas deben rechazarlo, pero eso no cumple
   el requisito de simulación de solo lectura. El bloqueo del motor económico
   en main.dart no cubre esta ruta.
2. DemoRankingSeeder escribe y borra usuarios mediante el cliente Firestore
   inyectado, sin comprobar dentro del seeder que el destino sea un entorno
   de demostración. main.dart lo construye con la instancia normal; no se
   encontró configuración de emulador allí. Las reglas actuales no permiten
   crear esos perfiles ajenos ni borrarlos. Falta resolver el entorno de
   ejecución del seeder sin relajar las reglas de producción.
3. Visto Bueno guarda el contador local por publicación, mientras el motor
   aplica el límite por pareja de usuarios y mes. La UI puede mostrar un cupo
   disponible en otro anuncio del mismo proveedor y recibir luego el rechazo
   correcto del motor. También conserva operaciones pendientes por periodo:
   falta verificar los reintentos que cruzan el cambio de mes.
4. Se agregaron premios para attendedEvent y backpackVerified en el motor,
   pero las reglas conservan el protocolo de confirmación de Servicios.
   El premio de Eventos se intenta al elegir «Voy» y sus errores se silencian;
   guardar intención de asistencia no acredita asistencia real. Además,
   test/economy_engine_test.dart aún espera unsupportedSource para Eventos.
   Esta incompatibilidad se detectó por lectura; no se ejecutó esa prueba.
   Guardar una ruta de foto tampoco implementa la verificación de mochila.

Estos pendientes no se reimplementan en la reparación de compilación, para
conservar los avances del usuario y distinguirlos del cierre de las fases.

## Alcance de la validación

El análisis inicial encontró 48 incidencias, concentradas en las dos causas
corregidas. Dart format pudo procesar los dos archivos corregidos.
Las solicitudes para volver a ejecutar flutter analyze y flutter test fueron
rechazadas. No se ejecutaron después de la corrección ni se hizo una
compilación web; no se afirma que esas verificaciones hayan pasado.

Pendiente ejecutar desde la raíz del proyecto:

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter run -d chrome
```

Los resultados históricos documentados en economy_phase2.md corresponden a
la entrega anterior y no acreditan el estado de los cambios posteriores.
