# Plan de mejora: Mochila de emergencia y video de simulacro

**Fecha**: 2026-11-07 | **Especificación**: solicitud del usuario

## Resumen

Ampliar la lista visible de productos de la mochila de emergencia, conservando el
checklist offline y lo que ya esté marcado. Añadir debajo de la mochila un botón
“Prepárate para un simulacro” que abra el video
https://www.youtube.com/watch?v=f9h9EIuuWs8 dentro de la aplicación, sin enviar a
YouTube ni al navegador externo.

La app ya usa `shared_preferences` para guardar la mochila y ya declara
`youtube_player_iframe`; el plan reutiliza ambos. El video requiere conexión a
internet, pero el checklist debe seguir disponible sin conexión.

## Contexto técnico

- **Lenguaje/plataforma**: Dart y Flutter; revisar los targets habilitados por la
  app al implementar el reproductor.
- **Dependencias existentes**: `shared_preferences`, `youtube_player_iframe`,
  `url_launcher`.
- **Persistencia**: `BackpackChecklistStore` almacena los elementos marcados
  localmente con la clave `mochila_checklist_v1`.
- **Pantalla**: `AyudaPrevencionPage` compone la mochila, tutorial, directorio y
  servicios cercanos en un `ListView`.
- **Pruebas existentes**: pruebas de widgets en
  `test/features/ayuda_prevencion/ayuda_prevencion_page_test.dart`.
- **Restricciones**: mantener el estilo visual existente; no abrir una app
  externa para reproducir el video; informar dentro de la app si el video no
  puede cargarse.

## Requisitos

- **REQ-001 (P1)**: Mostrar más de los cuatro productos actuales en la mochila,
  manteniendo un checklist legible, su contador y el guardado local de las
  selecciones existentes.
- **REQ-002 (P1)**: Mostrar debajo de la mochila un botón con una llamada a la
  acción relacionada con prepararse y practicar simulacros.
- **REQ-003 (P1)**: Al pulsar el botón, reproducir el video indicado en una
  pantalla/ventana dentro de la misma app, con controles para volver y un estado
  comprensible si no hay conexión o falla la carga.

## Verificación de principios

- Se conservan las selecciones existentes del checklist y su funcionamiento
  offline.
- El reproductor usa la dependencia ya presente; no se añade una dependencia
  sin necesidad.
- El video se abre en una ruta interna de Flutter y los errores no se presentan
  como si la reproducción hubiera iniciado correctamente.
- No se encontró un archivo de constitución o diseño específico en el
  repositorio; las decisiones se basan en el código actual y en los requisitos
  de esta solicitud.

## Guías aplicadas

No se identificaron guías de migración aplicables a esta mejora Flutter.

## Pasos de implementación

### Fase 1: Ampliar la mochila

#### Paso 1.1: Ampliar los elementos y mejorar la lectura del checklist

- **Requisitos**: REQ-001
- **Archivos**: `lib/features/ayuda_prevencion/services/backpack_checklist_store.dart`,
  `lib/features/ayuda_prevencion/widgets/mochila_emergencia_card.dart`
- **Descripción**: Añadir artículos de emergencia prácticos a la lista existente
  (por ejemplo, alimentos no perecibles, pilas de repuesto, silbato, artículos
  de higiene, documentos y efectivo), conservando literalmente los nombres de
  los cuatro elementos actuales. Mostrar el conjunto ampliado con un diseño
  adaptable y fácil de recorrer; mantener el total y el progreso actualizados.
  Los elementos nuevos deben iniciar desmarcados y no borrar el estado guardado
  de los elementos actuales.

### Fase 2: Prepararse para simulacros

#### Paso 2.1: Añadir la llamada a la acción bajo la mochila

- **Requisitos**: REQ-002, REQ-003
- **Archivos**: `lib/features/ayuda_prevencion/ayuda_prevencion_page.dart`
- **Descripción**: Insertar inmediatamente después de la tarjeta de mochila un
  botón visible, por ejemplo “Prepárate para un simulacro”, con estilo y
  accesibilidad coherentes con la aplicación. Al pulsarlo, navegar a la pantalla
  interna del reproductor.

#### Paso 2.2: Implementar la pantalla interna del video

- **Requisitos**: REQ-003
- **Archivos**: nuevo
  `lib/features/ayuda_prevencion/widgets/simulacro_video_page.dart` (o ubicación
  equivalente dentro de la feature)
- **Descripción**: Crear una pantalla interna con título, control para volver y
  reproductor `youtube_player_iframe` configurado con el ID `f9h9EIuuWs8`. Crear
  y liberar correctamente el controlador; permitir que el usuario inicie y
  controle el video en la app; mostrar un estado de error/recuperación si el
  video no carga. No usar `url_launcher` para abrir este video externamente.

### Fase 3: Verificación

#### Paso 3.1: Cubrir la nueva experiencia con pruebas

- **Requisitos**: REQ-001, REQ-002, REQ-003
- **Archivos**:
  `test/features/ayuda_prevencion/ayuda_prevencion_page_test.dart`
- **Descripción**: Actualizar las pruebas para verificar que se muestran más de
  cuatro elementos, que se pueden marcar, que el progreso usa el nuevo total,
  que las selecciones anteriores siguen disponibles tras cargar el estado y
  que el botón abre la pantalla interna con el video correcto. Mantener las
  pruebas de las demás secciones.

## Desglose de tareas

### Fase 1: Ampliar la mochila

- [x] T001 [US1] [Plan:1.1] Añadir elementos a `BackpackChecklistStore.defaultItems` en `lib/features/ayuda_prevencion/services/backpack_checklist_store.dart`, conservando los cuatro nombres actuales y el guardado local.
- [x] T002 [US1] [Plan:1.1] Verificar la presentación adaptable del checklist y el progreso en `lib/features/ayuda_prevencion/widgets/mochila_emergencia_card.dart`; el `Wrap` y el total dinámico existentes admiten los productos añadidos sin cambios adicionales.

### Fase 2: Prepararse para simulacros

- [x] T003 [US2] [Plan:2.1] Añadir debajo de `MochilaEmergenciaCard` el botón de simulacro y la navegación interna en `lib/features/ayuda_prevencion/ayuda_prevencion_page.dart`.
- [x] T004 [US2] [Plan:2.2] Crear `lib/features/ayuda_prevencion/widgets/simulacro_video_page.dart` con el reproductor integrado para el video `f9h9EIuuWs8`, acción para volver y estado de error.

### Fase 3: Verificación

- [x] T005 [US1,US2] [Plan:3.1] Actualizar y ejecutar las pruebas de checklist, navegación al reproductor y secciones existentes en `test/features/ayuda_prevencion/ayuda_prevencion_page_test.dart` y `test/widget_test.dart`.
- [ ] T006 [US2] [Plan:3.1] Ejecutar `flutter analyze` y confirmar manualmente en un dispositivo o navegador que la reproducción y el regreso ocurren dentro de la app. El análisis y el arranque web se validaron; falta confirmar la reproducción visualmente.

## Estructura prevista

```text
lib/features/ayuda_prevencion/
  ayuda_prevencion_page.dart
  services/
    backpack_checklist_store.dart
  widgets/
    mochila_emergencia_card.dart
    simulacro_video_page.dart       # nuevo
test/features/ayuda_prevencion/
  ayuda_prevencion_page_test.dart
```

## Estrategia de validación

- `flutter analyze` sin errores nuevos.
- `flutter test test/features/ayuda_prevencion/ayuda_prevencion_page_test.dart`
  con pruebas para los requisitos anteriores.
- Prueba manual en un target Flutter soportado: el botón abre el reproductor
  dentro de la app; se puede volver a la pantalla anterior; el video inicia con
  controles; la falta de conectividad se comunica sin perder el checklist local.

## Mapeo de requisitos

| REQ ID | Descripción | Pasos | Evidencia |
|---|---|---|---|
| REQ-001 | Ampliar y conservar el checklist de la mochila | 1.1, 3.1 | `backpack_checklist_store.dart`, `mochila_emergencia_card.dart`, pruebas de Ayuda y Prevención |
| REQ-002 | Añadir botón de simulacro debajo de la mochila | 2.1, 3.1 | `ayuda_prevencion_page.dart`, prueba de navegación |
| REQ-003 | Reproducir el video dentro de la app | 2.1, 2.2, 3.1 | `ayuda_prevencion_page.dart`, `simulacro_video_page.dart`, pruebas y verificación manual |
