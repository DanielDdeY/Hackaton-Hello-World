# Sistema de Diseño y Guía de Estilos (UX/UI)

**Proyecto:** Aplicación Móvil de Seguridad y Solidaridad Vecinal
**Tecnología:** Flutter (Material Design 3 adaptado)

## 1. Principios de Diseño

* **Alta Legibilidad:** Uso de altos contrastes para asegurar la visibilidad en exteriores y bajo estrés. Cumplimiento de estándares WCAG AAA para texto principal.

* **Acción Rápida (Regla de 3 clics):** Los flujos críticos (emergencias, reportes) deben completarse en un máximo de tres interacciones.

* **Aislamiento Contextual:** Separación estricta entre la utilidad cívica (Inicio/Mapa/Servicios) y la gamificación comunitaria (Perfil).

* **Soporte Offline:** La interfaz siempre debe comunicar de forma clara si el dispositivo se encuentra sin conexión a internet.

## 2. Paleta de Colores

El color no es decorativo; se utiliza exclusivamente para dirigir la atención y jerarquizar la información.

### Fondos y Superficies

* **Fondo Principal:** `#FAFAFA` (Gris tiza). Evita la fatiga visual del blanco puro al leer el muro de favores.

* **Tarjetas / Superficies:** `#FFFFFF` (Blanco puro). Para destacar las noticias, eventos y perfiles sobre el fondo principal.

### Colores de Interacción

* **Primario (Acciones cotidianas):** `#006D77` (Verde Azulado / Cerceta). Usado para botones principales, el ícono activo de la barra inferior y enlaces. Transmite confianza y comunidad.

* **Crítico / Urgencia:** `#D62828` (Rojo Señal). **Uso restringido.** Exclusivo para el Botón de Pánico, reportes de robos y alertas graves.

* **Solidaridad / Éxito:** `#2A9D8F` (Verde Esmeralda). Para confirmar que una acción fue exitosa (ej. "Favor aceptado") o destacar servicios validados ("Visto Bueno Vecinal").

* **Gamificación (Solo en Perfil):** `#FFB703` (Dorado/Mostaza). Para el nivel de la mascota y las recompensas por revisar la mochila de emergencia.

### Tipografía (Texto)

* **Texto Principal / Títulos:** `#1A1A1A` (Negro casi puro).

* **Texto Secundario / Descriptivo:** `#5C5C5C` (Gris oscuro).

## 3. Tipografía

Se utilizará **Inter** (disponible en Google Fonts). Es una fuente sans-serif geométrica optimizada para pantallas móviles pequeñas y alta legibilidad.
*Importante para Flutter: Descargar los archivos `.ttf` y declararlos en el `pubspec.yaml` para no depender de la red.*

* **Titulares (H1, H2):** Inter `Bold` o `SemiBold`.

* **Cuerpo de Texto (Noticias, descripciones):** Inter `Regular` (14pt o 16pt mínimo para accesibilidad).

* **Etiquetas y Botones:** Inter `Medium` (12pt para etiquetas de la barra inferior, 16pt para botones de acción).

## 4. Componentes Clave (Flutter)

### Top App Bar (Cabecera Superior)

* **Perfil y Gamificación:** Al liberar la barra inferior, el acceso al Perfil (donde habita la mascota y el "Spotify Wrapped" mensual) se ubicará en la esquina superior izquierda (Avatar del usuario).

* **Botón de Pánico:** Ubicado en la esquina superior derecha. Diseño en forma de pastilla (pill-shape). Debe requerir mantener presionado (LongPress) o deslizar para evitar activaciones accidentales.

### Bottom Navigation Bar (Barra Inferior)

* Debe contener **5 destinos** estratégicos para cubrir todos los frentes vecinales:

  1. **Inicio:** El feed principal con alertas urgentes, robos anclados y última hora.

  2. **Mapa:** Vista geolocalizada con pines de comercios, emergencias y necesidades.

  3. **Publicar (Centro):** Botón central resaltado (prominente). Al presionarlo, invoca un `ModalBottomSheet` con opciones rápidas para reportar, pedir ayuda o recomendar, cumpliendo la regla de los 3 clics.

  4. **Comunidad:** Espacio pasivo para noticias generales, avisos del jefe de grupo y eventos barriales.

  5. **Ayuda:** El núcleo de la economía solidaria. Directorio de oficios ("Visto Bueno Vecinal") y el muro de intercambio y favores.

### Tarjetas (Cards)

* **Bordes:** Redondeados a `12px` (amigable pero estructurado).

* **Sombras (Elevation):** Muy sutiles. Recomendado: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)`.

* **Estado de Alerta:** Las tarjetas de robos o emergencias en el feed llevan un borde lateral izquierdo rojo (`#D62828`) de `4px` de grosor.

## 5. Estados UI (Offline y Semántica)

* **Banner Offline:** Un contenedor en la parte superior (debajo del AppBar) de color Gris Claro (`#E5E5E5`), texto Negro (`#1A1A1A`), con el mensaje: "Sin conexión. Mostrando última actualización."

* **Botones Deshabilitados (Offline):** Si una acción requiere internet (ej. crear publicación), el botón debe pasar a opacidad 0.5 y color gris (`#B0B0B0`).

* **Accesibilidad (Semantics):** Todos los botones iconográficos deben estar envueltos en el widget `Semantics(label: 'Descripción de la acción')` para los lectores de pantalla (VoiceOver/TalkBack).