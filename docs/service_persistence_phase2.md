# Fase 2 — Persistencia de Servicios

El formulario de Servicios utiliza `PostSubmissionScope` y `PostSubmissionController`. Se valida antes de iniciar sesión, se clasifica mediante la interfaz inyectada `ServiceCategoryClassifier` y se entrega un borrador a `PostRepository`. El botón Publicar se deshabilita durante el envío; los errores mantienen los campos para reintentar.

## Datos y validaciones

- Se conserva la colección `posts`, con `category: "service"`, `status: "active"` y `schemaVersion: 2`.
- `details` contiene `title`, `information`, `mode`, `price` numérico, `currency: "PEN"`, `paymentMethods`, `transferBanks` cuando corresponde y `contactPhone`.
- Se incorporan `details.serviceCategory` (clave estable del clasificador) y `details.categorySource: "keyword"`. No aparece un selector de categoría en el formulario.
- Título e información son obligatorios. El monto acepta cero y hasta dos decimales; el teléfono exige nueve dígitos y empieza por 9.
- En Brindar servicio, la disponibilidad es opcional. Si se completa, requiere días y horas con fin posterior al inicio y se guarda en `availability`.
- Vender exige stock entero mayor o igual a 1. Se guarda únicamente `stock` y se excluye `availability`.
- El cambio entre modalidades conserva el borrador en memoria, pero excluye del documento los campos de la modalidad inactiva.

## Autor, fotografías y confirmación

El repositorio obtiene el nombre con `ProfilePostAuthorNameResolver`, que consulta `UserProfileStore` usando el UID autenticado. Guarda `authorId` y `authorName` en el envelope; si el perfil no existe o su nombre está vacío, usa `Vecino`. Un error de lectura del perfil se comunica como fallo de publicación y permite reintentar.

Se conserva el selector de una foto opcional existente en Servicios. La foto se sube antes de crear el documento. Si Firestore rechaza la escritura, se elimina la foto subida; si falla la subida no se crea el documento. `mediaStatus` es `ready` con foto o `none` sin ella. La ruta local nunca se almacena en `details`.

Al guardar se captura `ScaffoldMessenger` antes de cerrar la ruta y se muestra «Publicación creada.» en la pantalla anterior. El ajuste está en el componente compartido; las pruebas existentes de Emergencia y Ayuda siguen pasando. Emergencia conserva su estrategia de guardar primero y subir después.

## Verificación ejecutada

- 23 pruebas nuevas de Servicios aprobadas: clasificación inyectable, esquema, validaciones, envío único, fallo/reintento, perfil, subida, rollback y ambos modos del formulario en pantalla móvil.
- Suite completa: 104 pruebas aprobadas; un archivo no carga por errores preexistentes en `test/widget_test.dart`. Las 35 pruebas de clasificación y las regresiones de Emergencia, Ayuda, Comunidad y mapa pasan.
- Análisis global: los mismos 10 errores preexistentes de `test/widget_test.dart` y la advertencia por `_publish` sin uso en Ayuda. No aparecen incidencias en los archivos de esta fase.
- No se cambiaron paquetes ni versiones. Las dependencias se resolvieron sin conexión usando el lockfile existente.
- Se probaron el repositorio real con almacenes falsos y la interfaz con repositorios falsos. No se publicaron datos en Firebase de producción ni se verificaron las reglas desplegadas remotamente.

Los errores preexistentes impiden afirmar que todo el proyecto pasa `flutter analyze` o `flutter test`. Esos archivos permanecen sin modificar en esta fase.

## Cómo probar

Desde PowerShell:

```powershell
Set-Location -LiteralPath 'C:\Users\Windows 10\Desktop\Uni\Hackton\Hackaton-HelloWorld\Hackaton-Hello-World'
flutter test test/service_submission_test.dart test/post_form_submission_test.dart test/post_persistence_test.dart
flutter run
```

Si la app ya está abierta, realiza un reinicio completo (hot restart, `R` mayúscula en la terminal), porque cambió la inyección de dependencias.

1. Pulsa `+` y elige Servicios.
2. Publica «Reparación de laptops», información «Formateo y antivirus», monto `25.50` y un celular de nueve dígitos que empiece en 9.
3. En Brindar servicio, deja la disponibilidad en blanco o selecciona al menos un día y un horario válido. En Vender, ingresa stock mayor o igual a 1.
4. Comprueba el cierre del formulario y la confirmación.
5. En Firestore, consulta `posts`: el documento debe tener `category: service`, `details.serviceCategory: technology`, `details.categorySource: keyword` y solo los campos de la modalidad seleccionada.
6. Prueba también una foto opcional y un envío sin conexión; al fallar debe permanecer el formulario con su borrador.

La lista de Servicios en Comunidad se implementa en las fases posteriores. En esta fase la comprobación del dato guardado se realiza en Firestore.

## Acciones manuales

No hay nuevos índices ni cambios de reglas que desplegar en esta fase. Para probar contra el proyecto remoto se requieren la autenticación y las reglas de Firestore/Storage configuradas en las fases anteriores; sin sesión existente, el acceso anónimo debe estar habilitado. Si Firebase devuelve un error de permisos, revisa el despliegue previo. Las validaciones adicionales de reglas para Servicios se entregarán en la fase 4.
