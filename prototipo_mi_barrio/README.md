# Mi Barrio · prototipo Flutter

Proyecto de la hackatón UTP–El Comercio.

El primer arranque muestra la bienvenida. Para probar el acceso por celular usa un número ficticio de nueve dígitos y el código 123456. La opción Google también es de demostración. Elige el departamento, provincia y distrito antes de entrar. El prototipo guarda localmente el distrito, los datos del perfil y si ya viste el tutorial.

En Inicio puedes repetir el tutorial desde Mi barrio. El perfil incluye negocios, misiones, ayudas activas y anuncios, con la Pichanga del condominio como ejemplo. Publicar, avanzar una misión y completar un favor modifican los datos de la sesión. La edición de foto usa una imagen de ejemplo.

## Android Studio

Abre esta carpeta con File > Open. Configura Flutter SDK en Android Studio. En este equipo está en:

    C:\Users\Joel\Documents\Codex\tools\flutter

Si el comando flutter no está en PATH, puedes llamarlo usando la ruta completa al archivo bin\flutter.bat. Para ejecutar la aplicación necesitas Android SDK y un emulador o celular Android.

    flutter pub get
    flutter run

Las pantallas usan datos de ejemplo. SMS, Google, SOS, mapa, mensajería y foto de galería requieren sus servicios reales.

## Ramas del equipo

- `main`: versión estable para la demo.
- `develop`: integración de los cambios del equipo.
- `feature/bienvenida`: acceso y selección del distrito.
- `feature/perfil`: perfil, foto y actividad.
- `feature/tutorial`: recorrido guiado de Inicio.
- `feature/modulos`: oficios, favores, anuncios y pantallas del barrio.

Las ramas de trabajo parten del mismo código inicial. Abre los pull requests de las ramas de trabajo hacia `develop`. Cuando la demo esté revisada, integra `develop` en `main`.
