# Clasificador de Servicios: fase 1

Fuente: el diccionario enviado en `Texto pegado.txt`. Se usa únicamente como vocabulario; se reemplaza su algoritmo y no se crea un clasificador en `core/utils`.

## Reglas de clasificación

- Claves estables en `ServiceCategory`; etiquetas independientes para la interfaz.
- Minúsculas, diacríticos latinos y marcas combinantes eliminados; puntuación convertida en espacios y espacios colapsados.
- Diccionario normalizado una vez por instancia. Tokens en conjuntos y frases con límites de palabra; ninguna expresión regular por término.
- Fuertes: 2 puntos; débiles: 1. Coincidencias en el título ×3; en información ×1.
- Cada término cuenta una sola vez en la entrada completa. Si aparece en ambos campos prevalece el título. Términos diferentes pueden sumar aunque uno esté dentro de una frase.
- La entrada es `title + espacio + information`. Una frase que cruza los campos cuenta como información.
- Puntaje menor a 2: `other`. Desempates por puntaje del título, cantidad de términos fuertes distintos y constante `serviceCategoryPriority`.
- Prioridad final fija: Comida, Hogar y Oficios, Educación, Mascotas, Salud y Cuidado, Tecnología, Transporte y Mudanza, Belleza y Costura. No depende del orden del mapa.
- Un término débil aislado en información no alcanza el umbral; en el título sí puede hacerlo por el multiplicador ×3. Esto respeta el umbral solicitado.

## Auditoría del vocabulario

| Categoría | Entradas originales | Fuertes finales | Débiles finales |
|---|---:|---:|---:|
| Comida | 365 | 321 | 41 |
| Hogar y Oficios | 185 | 141 | 44 |
| Educación | 93 | 79 | 14 |
| Mascotas | 62 | 48 | 14 |
| Salud y Cuidado | 65 | 54 | 11 |
| Tecnología | 83 | 70 | 13 |
| Transporte y Mudanza | 54 | 43 | 11 |
| Belleza y Costura | 64 | 54 | 10 |

### Comida

- Espacios recortados: ` sangrecita`.
- Duplicados: `limon` (2 → 1), `manzana` (2 → 1), `maracuya` (2 → 1), `menestra` (2 → 1), `chilcano` (2 → 1), `quinua` (2 → 1).
- `pie` → `pie de limon`, `pie de manzana`.
- `pay` → `pay de limon`, `pay de manzana`.
- `manzana` → `jugo de manzana`, `venta de manzanas`.
- `aeropuerto` → `arroz aeropuerto`.
- `perico` → `pescado perico`.
- `res` → `carne de res`.
- `sal` → `sal de cocina`.
- `agua` → `agua de mesa`, `agua embotellada`.
- `tequeyoyo` → eliminado según la instrucción del documento.
- Conservados como débiles: `aceite`, `adoquin`, `alpaca`, `bidon`, `bomba`, `bonito`, `cancha`, `canchita`, `casera`, `casero`, `causa`, `causas`, `chupete`, `chupetes`, `cilindro`, `cocina`, `combinado`, `conserva`, `dulce`, `dulces`, `enrollado`, `extracto`, `hielo`, `integral`, `jalea`, `jora`, `limon`, `maracuya`, `marciano`, `marcianos`, `morada`, `naranja`, `papa`, `pension`, `rosca`, `sazon`, `seco`, `suspiro`, `triple`, `trucha`, `zanahoria`.

### Hogar y Oficios

- Espacios recortados: ` cielo raso`, ` electrodomestico`.
- Duplicados: `lijado` (2 → 1).
- Frase añadida para el caso de aceptación: `limpieza de casas`.
- Conservados como débiles: `abono`, `aluminio`, `apertura`, `asentado`, `aseo`, `cable`, `cables`, `cama`, `chapa`, `columna`, `diferencial`, `duplicado`, `electrico`, `escritorio`, `fachada`, `fierro`, `fuga`, `fugas`, `grifo`, `horno`, `humedad`, `latex`, `lavado`, `lijado`, `limpieza`, `llave`, `llaves`, `madera`, `mantenimiento`, `marco`, `medidor`, `mesa`, `pintura`, `piso`, `pisos`, `plancha`, `planta`, `plantas`, `reparacion`, `techo`, `tecnico`, `templado`, `traba`, `water`.

### Educación

- Duplicados: ninguno.
- `bateria` → `clases de bateria`.
- Conservados como débiles: `arte`, `cajon`, `ciencias`, `clase`, `clases`, `comunicacion`, `fisica`, `historia`, `inicial`, `lenguaje`, `liderazgo`, `quimica`, `salsa`, `teclado`.

### Mascotas

- Duplicados: ninguno.
- `can` → `cuidado canino`.
- `perico` → `ave perico`.
- Conservados como débiles: `albergue`, `ave`, `aves`, `collar`, `correa`, `corte de pelo`, `corte de unas`, `cuidador`, `entrenador`, `guarderia`, `pasear`, `paseo`, `paseos`, `vacuna`.

### Salud y Cuidado

- Duplicados: ninguno.
- `via` → `via intravenosa`.
- Conservados como débiles: `acompanante`, `bebe`, `bebes`, `curacion`, `dieta`, `masaje`, `masajes`, `ninos`, `relajante`, `suero`, `terapia`.

### Tecnología

- Duplicados: ninguno.
- `red` → `red informatica`.
- Conservados como débiles: `alarma`, `cabezal`, `canon`, `desbloqueo`, `hp`, `impresion`, `impresiones`, `lento`, `mando`, `pc`, `ram`, `redes`, `virus`.

### Transporte y Mudanza

- Duplicados: ninguno.
- `van` → `alquiler de van`.
- Conservados como débiles: `carga`, `cargador`, `colectivo`, `conductor`, `delivery`, `movilidad`, `planchado`, `recojo`, `reparto`, `suspension`, `traslado`.

### Belleza y Costura

- Duplicados: ninguno.
- Conservados como débiles: `cera`, `cierre`, `cierres`, `gel`, `hilo`, `iluminacion`, `palitos`, `rubber`, `tejido`, `unas`.

## Extensión y límites

Para ampliar el vocabulario edita solamente `serviceCategoryKeywords`: añade una palabra o frase a `strong` si es específica, o a `weak` si admite varios sentidos. Evita términos aislados ambiguos; utiliza frases. Añade un ejemplo a los tests. No hace falta cambiar el algoritmo.

No se recortó el vocabulario válido por tamaño: se eliminaron duplicados, se aplicaron las sustituciones documentadas y se conservó el resto. Los pesos y el umbral reducen falsos positivos, pero no equivalen a comprensión semántica ni garantizan equilibrio estadístico entre categorías.

Esta fase entrega la regla de negocio aislada. La inyección en el controlador y la persistencia de `serviceCategory`/`categorySource` corresponden a la fase 2; todavía no hay cambios visibles en Comunidad ni cambios de Firebase.

## Verificación

```powershell
flutter test test/service_category_classifier_test.dart
flutter test
flutter analyze
```

Acciones manuales de Firebase: ninguna para esta fase.

### Resultado de las comprobaciones

- Los 35 tests del clasificador pasan, incluidos los 16 casos de aceptación.
- El análisis de los cinco archivos Dart añadidos termina sin incidencias.
- La suite completa ejecuta 81 tests correctamente, pero no puede cargar `test/widget_test.dart`: el archivo original usa `const MyApp()` aunque su constructor ya no es constante y referencia `MapScreen`, `LocationPermissionView`, `FlutterMap`, `bar` y `CategoryCard` sin definirlos o importarlos.
- El análisis global informa esos 10 errores y una advertencia preexistente por `_publish` sin uso en `help_form.dart`.
- Se compararon los hashes de esos dos archivos con los del proyecto original: son idénticos. Esta fase no modifica ninguno de ellos ni cambia las dependencias. El proyecto completo no queda todavía con todas sus verificaciones en verde.
