# La economía de la app vecinal: explicación general y aplicaciones

> Documento explicativo y general. Nombres provisionales: la moneda se llama **moneda** y las tareas con recompensa **favores** (antes "misiones"). Todos los valores son hipótesis iniciales para calibrar con datos reales. Las decisiones pendientes están en la sección 15.

## 1. Resumen

La economía de la app es un sistema de incentivos para que los vecinos se ayuden más entre sí de forma sostenida. Funciona así:

1. El vecino **hace favores y participa en eventos** (acciones reales y verificadas).
2. Por ello recibe **XP** (progreso), **moneda** (para gastar) y **estrellas** (reputación).
3. La moneda se guarda en una **billetera** y se gasta en cajas, tienda, mascota y descuentos de negocios.
4. El XP sube su **nivel** y su posición en el **ranking**, y desbloquea funciones.
5. Si el vecino se compromete y **no cumple**, pierde XP de liga y puede ver reducidos sus cupos.
6. Un conjunto de reglas **anti-farming** evita que se obtengan puntos sin ayudar de verdad.

Idea central: **ayudar da progreso y recompensas; incumplir tiene un costo pequeño; hacer trampa no rinde.** El enganche (mascota, cajas, ligas, rachas) está al servicio de la ayuda real.

## 2. Glosario

| Término         | Significado                                                                        |
| --------------- | ---------------------------------------------------------------------------------- |
| **Favor**       | Tarea de ayuda entre vecinos que da recompensa (antes "misión")                    |
| **Evento**      | Actividad comunitaria (pollada, chocolatada, reunión); da recompensa menor         |
| **Moneda**      | Unidad gastable de la app. No tiene valor en dinero y no se transfiere             |
| **XP de nivel** | Experiencia acumulada que define nivel y desbloqueos. Nunca baja                   |
| **XP de liga**  | Experiencia de la temporada que define el ranking. Puede bajar por incumplimientos |
| **Estrellas**   | Reputación: promedio de calificaciones que recibe quien ayuda                      |
| **Fiabilidad**  | Puntaje oculto de cumplimiento; regula cuántos cupos simultáneos puede tomar       |
| **Confianza**   | Puntaje oculto de antigüedad, reportes y diversidad; modula las ganancias          |
| **Billetera**   | Registro de movimientos de moneda con saldo disponible y pendiente                 |
| **Cadena**      | Un favor que el receptor "pasa" ayudando a otro vecino distinto                    |
| **Retención**   | Periodo de 24 a 48 h en que la recompensa queda pendiente antes de liberarse       |

## 3. Principios de diseño

1. **Separar progreso, dinero y reputación.** Gastar no puede bajar el nivel ni la reputación.
2. **La moneda sale del sistema, no del vecino.** Quien pide ayuda no paga. No hay transferencias entre vecinos.
3. **Lo fija el sistema, no quien publica.** Las recompensas dependen de la categoría del favor, no de lo que alguien declare.
4. **Premiar primero, penalizar con medida.** El castigo es siempre menor que el premio, para que nadie tema aceptar.
5. **Verificar antes de pagar.** Doble confirmación y retención.
6. **Que lo ganado tenga dónde gastarse.** Más fuentes que sumideros genera inflación.
7. **Solo positivo en lo público.** Los puntajes de control (fiabilidad, confianza) son ocultos; lo visible son premios.
8. **Emergencia sin fricción.** En una emergencia la economía se simplifica para no frenar la ayuda.

## 4. Las capas de la economía

| Capa        | Se gasta | Puede bajar       | Visible | Función                            |
| ----------- | -------- | ----------------- | ------- | ---------------------------------- |
| XP de nivel | No       | No                | Sí      | Nivel, desbloqueos, títulos        |
| XP de liga  | No       | Sí (penalización) | Sí      | Ranking de temporada               |
| Moneda      | Sí       | Sí (al gastar)    | Sí      | Cajas, tienda, mascota, descuentos |
| Estrellas   | No       | Sí (promedio)     | Sí      | Confianza entre vecinos            |
| Fiabilidad  | No       | Sí                | No      | Cupos simultáneos                  |
| Confianza   | No       | Sí                | No      | Multiplicador de ganancias         |

**Por qué dos tipos de XP:** quitar XP al nivel haría que un imprevisto hiciera caer a un vecino de nivel y perder desbloqueos. Separando, la penalización afecta la competencia (liga) y no el progreso acumulado.

**Por qué las estrellas no son la moneda:** si lo fueran, comprar cosas bajaría la reputación.

**Dos mundos con reglas distintas:**

- **Favores y eventos:** sin dinero real; pagan moneda y XP de la app.
- **Servicios** (gasfitero, cerrajero, clases): cobran en dinero real y se validan con "Visto Bueno Vecinal". La moneda no paga servicios.
- El único puente son los descuentos en negocios vecinales.

## 5. Cómo se gana

### 5.1 Favores

La recompensa es fija y la determina el sistema por tamaño.

| Tamaño                | Ejemplo                                      | Moneda         | XP  |
| --------------------- | -------------------------------------------- | -------------- | --- |
| Mini (≤15 min)        | Prestar una herramienta, acompañar a un niño | 5              | 10  |
| Medio (≤1 h)          | Compras para un adulto mayor                 | 15             | 30  |
| Grande (varias horas) | Mudanza, reparación                          | 40             | 80  |
| Comunitario           | Limpieza de parque, jornada de pintura       | 30 por persona | 60  |

**Cómo se decide el tamaño:** es el punto más fácil de abusar. Propuesta: el tamaño se elige entre opciones con ejemplos al publicar, y el ayudante puede proponer un cambio al aceptar; el sistema solo lo acepta si el vecino ayudado coincide. Los favores grandes piden evidencia ligera (foto antes y después).

### 5.2 Modificadores

| Modificador                   | Efecto                            | Condición                             |
| ----------------------------- | --------------------------------- | ------------------------------------- |
| Vecino nuevo o de otra cuadra | +25% moneda                       | Fomenta diversidad                    |
| Eslabón de cadena             | +20% moneda y +10% XP por eslabón | Hasta 3; solo entre vecinos distintos |
| Mochila vigente               | +5% de ganancias                  | Mientras esté al día                  |
| Pareja repetida (30 días)     | 100% → 50% → 25% → 0%             | Entre los mismos dos vecinos          |
| Cuenta nueva                  | Ganancias reducidas               | Periodo de prueba (confianza)         |

### 5.3 Eventos y otras fuentes

| Fuente                          | Moneda               | XP        | Notas                                                    |
| ------------------------------- | -------------------- | --------- | -------------------------------------------------------- |
| Asistir a un evento             | 3                    | 10        | Reunión vecinal: 5 y 20                                  |
| Organizar un evento             | 2 por asistente real | 15        | Tope de 20; mínimo 5 asistentes distintos                |
| Visto Bueno verificado          | 0                    | 5         | Máximo 2 por semana; solo con confirmación del proveedor |
| Mochila completa (única)        | 50                   | 100       | Verificada con la cámara                                 |
| Renovar mochila (cada 3 meses)  | 15                   | 30        | Antes de que algo venza                                  |
| Cuadra con más de 60% preparada | 20 por vecino        | n/a       | Una vez por trimestre                                    |
| Bono de bienvenida              | A definir            | A definir | Tutorial con la mascota                                  |
| Rachas semanales                | A definir            | A definir | Con un día de gracia                                     |

Los Vistos Buenos no pagan moneda para evitar una vía de farming entre proveedores y clientes aliados.

## 6. Cumplimiento y penalización

**Objetivo:** que nadie acapare cupos sin ir. Se penaliza el incumplimiento verificable, con medida.

| Aspecto              | Regla propuesta                                                                               |
| -------------------- | --------------------------------------------------------------------------------------------- |
| Qué se penaliza      | No presentarse a un favor aceptado o a una reunión con asistencia verificada (QR o ubicación) |
| Qué no se penaliza   | "Me interesa", eventos sin verificación, cancelaciones a tiempo y todo en modo emergencia     |
| Cancelación a tiempo | Sin costo si se cancela con 2 a 4 h de anticipación (a definir)                               |
| Qué baja             | **XP de liga**, nunca el XP de nivel ni la moneda ganada                                      |
| Monto                | Aproximadamente 50% del XP que daría completar el favor; 25% en reuniones                     |
| Perdón               | Un "no pude" gratuito por mes                                                                 |
| Reincidencia         | 1.ª vez aviso; 2.ª penalización leve; 3.ª penalización completa                               |
| Efecto en cupos      | Baja la **fiabilidad**: de 3 favores simultáneos a 2 y luego a 1; se recupera cumpliendo      |
| Tope                 | Máximo de pérdida por semana; el XP de liga no baja de cero                                   |
| Cómo se detecta      | El vecino ayudado marca "no llegó"; el ayudante puede responder (en camino, ubicación)        |
| Desacuerdo           | Revisión manual y apelación; mientras tanto no se aplica la penalización                      |

**Riesgos:**

- Acusaciones falsas para perjudicar a alguien: requieren contraprueba y apelación.
- Miedo a aceptar favores: la penalización debe ser siempre menor que el premio.
- Adultos mayores: los imprevistos son más frecuentes; mantener el perdón mensual y la cancelación fácil.

## 7. La billetera

La billetera es un **libro de movimientos**: el saldo se calcula desde un registro de entradas y salidas que no se edita.

| Elemento         | Detalle                                                                                |
| ---------------- | -------------------------------------------------------------------------------------- |
| Saldo disponible | Moneda que se puede gastar                                                             |
| Saldo pendiente  | Recompensas en retención de 24 a 48 h                                                  |
| Movimientos      | Fecha, tipo (ganancia, retención, liberación, gasto, reembolso, ajuste), monto, origen |
| Escritura        | Solo el servidor (Cloud Functions); la app solo lee                                    |
| Gastar           | Operación con transacción: valida saldo, descuenta y entrega el objeto en un solo paso |
| Duplicados       | Cada movimiento tiene identificador único (idempotencia)                               |
| Offline          | Muestra el último saldo sincronizado; no permite gastar sin conexión                   |
| Transferencias   | No existen entre vecinos                                                               |
| Ajustes manuales | Solo administradores, siempre con motivo registrado                                    |

Estructura en Firestore: `usuarios/{uid}/billetera` (disponible, pendiente) y `usuarios/{uid}/movimientos/{id}`.

## 8. Topes, retención y control

- **Tope semanal de moneda:** 150 en condiciones normales.
- **XP:** tope blando; rendimientos decrecientes desde 200 por semana.
- **Pedidos que generan recompensa** (para quien pide ayuda): 3 por semana.
- **Retención:** toda recompensa queda pendiente 24 a 48 h y se libera si no hay reporte.
- **Reportes:** un reporte retiene la recompensa y envía el caso a revisión; sin castigos duros.

## 9. Anti-farming

1. Cero transferencia de moneda entre usuarios.
2. La moneda sale del sistema, no del vecino ayudado.
3. Rendimientos decrecientes por pareja.
4. Bono por diversidad.
5. Topes semanales.
6. Detección de anillos (A, B y C ayudándose solo entre ellos), con atención especial en las cadenas.
7. Confianza oculta que modula ganancias.
8. Evidencia ligera en favores grandes.
9. Doble confirmación obligatoria.
10. Penalización por incumplimiento con perdón y apelación.
11. Sin compra de moneda ni de cajas con dinero real.

## 10. Cómo se gasta

| Sumidero                   | Costo inicial  | Notas                                                 |
| -------------------------- | -------------- | ----------------------------------------------------- |
| Caja básica / media / alta | 30 / 100 / 300 | Objetos de la mascota                                 |
| Cuidado de mascota         | 10 por semana  | Si no se atiende, "duerme"; no muere ni baja de nivel |
| Tienda de perfil           | 40 a 400       | Marcos, insignias, temas, títulos                     |
| Descuento de negocio       | Desde 500      | Un canje mensual por vecino; QR de un solo uso        |
| Ediciones de temporada     | Variable       | Fiestas Patrias, Señor de los Milagros, Navidad       |

**Reglas de las cajas:** probabilidades siempre visibles, garantía tras X cajas sin objeto raro, duplicados convertidos en fragmentos y **sin compra con dinero real**.

**Descuentos:** el negocio absorbe el costo como marketing y la app lo promociona; el canje se limita por vecino para no vaciar la oferta.

## 11. Progresión y ranking

- **Nivel:** sube con el XP de nivel y desbloquea mascota, cajas y tienda.
- **Mascota:** se obtiene a un nivel por definir y sube con la actividad de su dueño.
- **Títulos:** por nivel ("Vecino Aprendiz", "Guardián de la Cuadra").
- **Ranking:** usa **solo XP de liga**, por cuadra, barrio y distrito.
- **Ligas:** semanales o mensuales, que se reinician, para que los nuevos puedan competir.
- **Buen vecino de la semana:** por nominación, con cupo por vecino.

## 12. Aplicaciones en la app

| Módulo / función           | Cómo usa la economía                                                                                                                |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Comunidad**              | Muestra favores y eventos con su recompensa, dispara los eventos económicos al completar, muestra pendientes, ranking y buen vecino |
| **Publicación**            | Asigna tamaño y recompensa fija al favor; aplica el cupo semanal de pedidos                                                         |
| **Servicios (directorio)** | Sin moneda; el Visto Bueno da XP pequeño al vecino que lo emite                                                                     |
| **Mapa**                   | Sin recompensa propia; abre favores y eventos por enlace profundo                                                                   |
| **Alertas y emergencia**   | Activan el modo emergencia (suspende topes y cupos)                                                                                 |
| **Mochila de emergencia**  | Da moneda, XP, insignia y multiplicador mientras esté vigente                                                                       |
| **Perfil**                 | Billetera, nivel, estrellas, mascota, tienda y cajas                                                                                |
| **Negocios aliados**       | Descuentos canjeables con moneda y premios exclusivos                                                                               |
| **Notificaciones**         | Avisan recompensas liberadas, cupos y rachas                                                                                        |
| **Tutorial**               | La mascota guía y entrega el bono de bienvenida y un favor de práctica                                                              |

### Ejemplo de ciclo completo

1. Ana acepta un favor medio de Luis (cupo 1 de 1, se bloquea).
2. Ana marca "terminé"; Luis confirma y califica con 5 estrellas.
3. La recompensa (15 monedas y 30 XP) queda pendiente 24 h.
4. Pasado el plazo sin reporte, se libera: 15 monedas a la billetera, 30 XP al nivel y a la liga.
5. Ana pasa el favor ayudando a Rosa (otro vecino distinto): bono de cadena +20%.
6. Con sus monedas, Ana compra una caja básica para su mascota.
7. Si Ana hubiera aceptado y no hubiera ido ni cancelado a tiempo, habría perdido unos 15 XP de liga y su fiabilidad habría bajado.

## 13. Modo emergencia

- Lo activa un delegado o una alerta oficial; nunca el vecino.
- Se suspenden cupos, topes, rendimientos decrecientes y penalizaciones.
- La recompensa sigue siendo fija y solo por ayuda confirmada.
- No se premia reportar vulnerabilidad (incentivaría falsos).
- Al terminar, reconocimiento especial de temporada (insignia, no moneda masiva).

## 14. Ritmo esperado y control

**Referencia:** un vecino activo gana unas 120 monedas por semana; uno casual, unas 40.

| Hito                               | Tiempo aproximado |
| ---------------------------------- | ----------------- |
| Primer favor y primera caja básica | Primera semana    |
| Mascota nivel 3 (~100 XP)          | 3 a 4 favores     |
| Caja media                         | Semanal           |
| Caja alta                          | Cada 3 semanas    |
| Primer descuento de negocio        | 4 a 5 semanas     |

**Equilibrio semanal (vecino activo):** 120 ganadas; ~10 a mascota, ~30 a una caja básica o ahorro para la media y el resto a ahorro. Si el ahorro promedio crece semana a semana, hay que subir sumideros o bajar ganancias.

**Valor de referencia:** si un descuento típico de S/5 cuesta 500 monedas, 1 moneda equivale a S/0,01. Un vecino activo "gana" unos S/1,20 por semana. Un valor bajo protege a los negocios y hace poco atractivo el farming.

**Métricas:**

- Moneda ganada vs. gastada por semana.
- Porcentaje de ayudas entre pares repetidos.
- Vecinos distintos ayudados por usuario.
- Tiempo hasta la primera mascota y la primera caja.
- Tasa de incumplimientos, de reportes y de favores sin completar.
- Longitud y repetición de cadenas.

**Regla de ajuste:** si la moneda se acumula sin gastarse, bajar ganancias o añadir sumideros; si se gasta demasiado rápido, subir topes o crear más formas de ganar.

## 15. Qué falta definir

### Imprescindible para el primer lanzamiento

1. Nombres finales de moneda, favores y XP (probar con vecinos).
2. Cómo se clasifica el tamaño de un favor y quién lo valida.
3. Curva de niveles y nivel en que se obtiene la mascota.
4. Bono de bienvenida y tutorial.
5. Reglas de la billetera (pendiente, historial, sin transferencias).
6. Reglas de penalización (montos, plazos, perdón, apelación).
7. Valores finales de ganancias y topes.

### Segunda versión

8. Catálogo de cajas: objetos, rareza, probabilidades y garantía.
9. Precios de la tienda y qué es permanente o de temporada.
10. Mascota: cuidado y qué pasa si se descuida.
11. Ligas: duración, ascensos y descensos, premios.
12. Rachas: qué cuenta, cuánto dan y día de gracia.
13. Cálculo de fiabilidad y confianza (factores y pesos).
14. Descuentos de negocios: financiación, topes, vigencia y canje.

### Más adelante

15. Inactividad y posible vencimiento de moneda de temporada.
16. Moneda de temporada o de evento.
17. Gobernanza: quién cambia parámetros y cada cuánto se revisa el equilibrio.
18. Aspectos legales: moneda sin valor en dinero, cajas con probabilidad, datos personales (Ley 29733) y menores.
19. Arranque en frío con pocos vecinos (topes más bajos, eventos semilla).

## 16. Implementación técnica

- Todo cálculo de moneda, XP, penalizaciones y ranking se hace en **Cloud Functions**; el cliente solo lee.
- La billetera es un libro de movimientos con identificadores únicos.
- Los valores (recompensas, topes, ventanas, penalizaciones) viven en **Remote Config** para ajustarlos sin publicar versión.
- Cada otorgamiento, retención y penalización queda registrado para auditoría.
- Las reglas de seguridad impiden que el cliente modifique XP, moneda, estrellas o fiabilidad.
- Empezar con topes conservadores, que son más fáciles de subir que de bajar, y simular antes de fijar números.
