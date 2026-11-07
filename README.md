# Hackaton-Hello-World

## Probar VeciApp con Firebase local

Desde la raíz de este proyecto, inicia los emuladores en una terminal:

```powershell
npx.cmd --yes firebase-tools emulators:start --only auth,firestore,storage --project demo-hackaton-hello-world
```

En otra terminal, con un emulador de Android iniciado o un dispositivo conectado:

```powershell
flutter pub get
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

El modo de depuración usa el proyecto de demostración. El emulador de Android
accede a los servicios de la PC mediante `10.0.2.2`. Para un dispositivo Android
conectado por USB, usa `adb reverse tcp:9099 tcp:9099`,
`adb reverse tcp:8080 tcp:8080` y `adb reverse tcp:9199 tcp:9199`, y añade
`--dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1` al comando de Flutter.

Completa el ingreso de demostración y abre **+ → Emergencia**. Si concedes el
permiso, verás las coordenadas mientras se busca la calle. El botón **Publicar**
solicita una sesión anónima cuando el formulario es válido. Puedes comprobar el
usuario en [Authentication del emulador](http://127.0.0.1:4000/auth).
En esta fase la publicación se registra en consola y los adjuntos permanecen
en el dispositivo. Las reglas de acceso de la app se incorporarán en la fase 3.

Para probar Auth contra `hackaton-hello-world`, habilita **Authentication →
Método de acceso → Anónimo** en la consola de Firebase y ejecuta Flutter sin
el modo de emuladores.

Para habilitar el registro con Google, activa **Authentication → Método de
acceso → Google** en Firebase Console. En Android añade la huella SHA-1 y
SHA-256 de la aplicación en **Configuración del proyecto**, descarga de nuevo
`android/app/google-services.json` y reemplaza el archivo existente. En iOS
configura el cliente OAuth generado por Firebase en Xcode. Después de esto,
el botón **Continuar con Google** del ingreso inicial abre el flujo real de
Google; en web usa el popup de Firebase.

El Home guarda el perfil de cada usuario en `users/{uid}` de Firestore:
nombre, ubicación, XP, estrellas, favores, herramientas y estado de la
mascota. Publica las reglas con `firebase deploy --only firestore:rules`
para permitir únicamente el acceso del usuario a su propio perfil.

```powershell
flutter analyze
flutter test
flutter build apk --debug
```
