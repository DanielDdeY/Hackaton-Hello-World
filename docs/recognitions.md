# Reconocer a un vecino

En **Comunidad → Vecinos**, el botón del Top 3 abre un selector que reutiliza
la lista mensual del distrito. El autor elige a otro vecino y envía un mensaje
de 1 a 280 caracteres. El formulario conserva el texto si el envío falla.

Firestore guarda un documento en `recognitions/{period}_{authorId}_{recipientId}`.
El ID permite un envío por pareja de autor y destinatario cada mes. El documento
contiene `authorId`, `authorName`, `recipientId`, `recipientName`, `message`,
`period`, `createdAt` y `schemaVersion: 1`, más `districtId` si la lista lo trae.
Los nombres son copias del momento del envío y `createdAt` lo fija el servidor.
Las reglas verifican que ambos perfiles reales pertenezcan al mismo distrito.
Solo autor y destinatario pueden leer el documento. Los envíos son inmutables.

## Integración con el Wrapped

`RecognitionRepository` se inyecta en `MyApp` con Provider. Desde la pantalla
del Wrapped, con el UID de la sesión actual:

```dart
import 'package:hackaton_hello_world/features/comunidad/recognitions/domain/services/recognition_repository.dart';
import 'package:provider/provider.dart';

// Dentro del flujo de carga del Wrapped:
final repository = context.read<RecognitionRepository?>();
final result = await repository?.getForWrapped(recipientId: uid);
if (result != null && result.isOpen) {
  // Usar result.period e iterar result.items (más recientes primero).
  // Cada item incluye authorName y message.
}
```

`WrappedWindowPolicy` abre el resumen del mes desde las 00:00 de su último
día hasta el final del día 7 del mes siguiente, en hora de Lima. La consulta
usa el periodo abierto por defecto. Si se pasa `period`, debe coincidir con
el periodo abierto. Si la ventana está cerrada, la respuesta trae
`isOpen: false`, `period: null` e `items: []`, sin consultar Firestore.

Para forzar la ventana del mes actual en depuración, inicia con
`flutter run -d chrome --dart-define=FORCE_WRAPPED_WINDOW_OPEN=true`. Esto activa
`kForceWrappedWindowOpen`. El periodo de envío siempre usa el mes real de Lima.

## Puesta en marcha y verificación manual

Desde la raíz del repositorio, publica las reglas y el índice de lectura con
`firebase deploy --only "firestore:rules,firestore:indexes"`. Espera a que el
índice de `recognitions` esté listo antes de probar el Wrapped.

1. Inicia sesión como autor y envía un reconocimiento a otro vecino del distrito.
2. Abre Firestore en Firebase Console y verifica el ID y los campos del documento.
3. Intenta enviar otro reconocimiento al mismo vecino en el mismo mes. Debe
   aparecer «Ya reconociste a este vecino este mes».
4. Inicia sesión como destinatario y, con la bandera de depuración activada,
   llama a `getForWrapped(recipientId: uid)`. Comprueba que devuelve el mensaje
   y el nombre del autor.
