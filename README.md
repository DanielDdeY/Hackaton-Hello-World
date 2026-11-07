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

```powershell
flutter analyze
flutter test
flutter build apk --debug
```
