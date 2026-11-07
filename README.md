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

Completa el ingreso de demostración y prueba estas dos publicaciones:

1. **+ → Emergencia**. Concede el permiso de ubicación o escribe la calle.
   Puedes publicar en cuanto la calle tenga un valor, incluso mientras se
   resuelve el nombre de la dirección. Si adjuntas una foto, el documento
   aparece primero en `posts` con `mediaStatus: uploading`. La foto se sube
   después y el estado cambia a `ready` o `failed`.
2. **+ → Ayuda**. Completa la descripción y adjunta una foto. La ubicación
   se busca aunque no abras **Detalles**. La foto se sube antes de crear
   el documento. Si cancelas durante la subida o falla la escritura en
   Firestore, la app intenta eliminar los archivos de ese intento.

El botón **Publicar** solicita una sesión anónima cuando el formulario es
válido. Comprueba el usuario en [Authentication](http://127.0.0.1:4000/auth),
el documento en [Firestore](http://127.0.0.1:4000/firestore) y la imagen en
[Storage](http://127.0.0.1:4000/storage). En Servicios y Noticias la persistencia
se incorporará en sus fases de integración.

Los adjuntos de estos flujos deben ser JPG y pesar menos de 5 MB. La foto de
Emergencia puede seguir subiendo al salir del formulario mientras la aplicación
permanezca en ejecución. Si se cierra el proceso, puede quedar en `uploading`.

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

El registro con celular usa un código de prueba fijo: `123456`. Un teléfono
nuevo solicita nombres y apellidos antes del código; un teléfono existente
solicita únicamente el código. El índice `phoneIndex` permite distinguir ambos
casos. No se envía un SMS real en este prototipo.

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Para verificar las reglas de acceso en el proyecto de demostración:

```powershell
npx.cmd --yes firebase-tools emulators:exec --only auth,firestore,storage --project demo-hackaton-hello-world "node test/firebase_rules_test.mjs"
```

Antes de usar el proyecto remoto, revisa las reglas que tenga desplegadas y
confirma que estén habilitados Auth anónimo, Firestore y el bucket de Storage.
Si ya hay reglas para otros módulos, integra los bloques de publicaciones con
esas reglas antes de desplegar.
Una vez revisados esos cambios, el despliegue de reglas e índices se hace desde
la raíz del proyecto:

```powershell
npx.cmd --yes firebase-tools deploy --project hackaton-hello-world --only firestore:rules,firestore:indexes,storage
```
