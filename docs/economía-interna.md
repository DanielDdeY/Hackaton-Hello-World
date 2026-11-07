# Economía interna de la app vecinal

> Moneda: puntos de buen vecino (temporal)
> Favores: misiones para tomar, se dan **monedas** y **EXP** por completarlas

## 1. Objetivo

Motivar a los vecinos a ayudarse más entre sí, de forma sostenible, sin que la economía se pueda explotar (farming) ni se desbalancee. La mecánica de enganche (progreso, colección, rachas) sirve a la ayuda real; no la reemplaza.

## 2. Tres capas separadas

| Capa           | Qué es            | ¿Se gasta?     | Para qué sirve                                               |
| -------------- | ----------------- | -------------- | ------------------------------------------------------------ |
| **XP / Nivel** | Progreso tipo RPG | No, nunca baja | Ranking, desbloqueos (mascota, tienda, cajas), estatus       |
| **Moneda**     | Economía gastable | Sí             | Cajas, tienda, mascota, descuentos                           |
| **Estrellas**  | Reputación        | No se gasta    | Confianza: promedio de calificaciones que recibe quien ayuda |

Las estrellas no son la moneda. Si lo fueran, comprar cosas bajaría la reputación y se mezclarían ranking, gasto y confianza.

**Dos mundos con reglas distintas:**

- **Favores:** sin dinero real; dan moneda y XP de la app.
- **Servicios** (gasfitero, cerrajero, clases): sí cobran en dinero real, con "Visto Bueno Vecinal". La moneda no paga servicios.
- El único puente entre ambos son los descuentos en negocios vecinales.

## 3. Fuentes de ganancia

### 3.1 Favores

Recompensa fija fijada por el sistema, nunca por quien publica.

| Tamaño                | Ejemplo                                      | Moneda         | XP  |
| --------------------- | -------------------------------------------- | -------------- | --- |
| Mini (≤15 min)        | Prestar una herramienta, acompañar a un niño | 5              | 10  |
| Medio (≤1 h)          | Compras para un adulto mayor                 | 15             | 30  |
| Grande (varias horas) | Mudanza, reparación                          | 40             | 80  |
| Comunitario           | Limpieza de parque, jornada de pintura       | 30 por persona | 60  |

### 3.2 Modificadores

| Modificador                        | Efecto                            | Regla                                           |
| ---------------------------------- | --------------------------------- | ----------------------------------------------- |
| Vecino nuevo o de otra cuadra      | +25% moneda                       | Fomenta diversidad                              |
| Eslabón de cadena (pasar el favor) | +20% moneda y +10% XP por eslabón | Hasta 3 eslabones; solo entre vecinos distintos |
| Mochila vigente                    | +5% de ganancias                  | Mientras esté al día                            |
| Pareja repetida (30 días)          | 100% → 50% → 25% → 0%             | Entre los mismos dos vecinos                    |
| Cuenta nueva                       | Ganancias reducidas               | Periodo de prueba (confianza oculta)            |

### 3.3 Otras fuentes

| Fuente                          | Moneda               | XP        | Notas                                                          |
| ------------------------------- | -------------------- | --------- | -------------------------------------------------------------- |
| Asistir a evento                | 3                    | 10        | Reunión vecinal: 5 y 20                                        |
| Organizar evento                | 2 por asistente real | 15        | Tope de 20; mínimo 5 asistentes distintos                      |
| Visto Bueno verificado          | 0                    | 5         | Máximo 2 por semana; solo si el proveedor confirma el servicio |
| Mochila completa (única)        | 50                   | 100       | Verificada                                                     |
| Renovar mochila (cada 3 meses)  | 15                   | 30        | Antes de que algo venza                                        |
| Cuadra con más de 60% preparada | 20 por vecino        | n/a       | Una vez por trimestre                                          |
| Rachas semanales                | A definir            | A definir | Pequeño bono por constancia                                    |

Los Vistos Buenos no pagan moneda para evitar una segunda vía de farming entre proveedores y clientes aliados.

## 4. Topes y liberación

- **Tope semanal de moneda:** 150 en condiciones normales.
- **XP:** tope blando; rendimientos decrecientes desde 200 por semana.
- **Cupo de pedidos que generan recompensa** (para quien pide ayuda): 3 por semana.
- **Retención:** toda recompensa queda pendiente 24 a 48 h y se libera si no hay reporte.
- **Modo emergencia:** se suspenden cupos, topes y rendimientos decrecientes. La recompensa sigue siendo fija y solo por ayuda confirmada. No se premia el reporte de vulnerabilidad (incentivaría falsos).

## 5. Anti-farming

1. **Cero transferencia de moneda entre usuarios.** Es la medida más importante.
2. **La moneda sale del sistema, no del vecino ayudado.**
3. **Rendimientos decrecientes por pareja** (sección 3.2).
4. **Bono por diversidad** (vecinos nuevos o de otra cuadra).
5. **Topes semanales** de moneda y XP blando.
6. **Detección de anillos:** si A, B y C se ayudan solo entre ellos de forma recurrente, bajan las recompensas y se revisa a mano. Aplica especialmente a la cadena de favores.
7. **Puntaje de confianza oculto:** cuentas nuevas, reportes y antigüedad modulan las ganancias sin mostrarse.
8. **Evidencia ligera** en favores grandes: foto antes y después o calificación detallada.
9. **Reportes con consecuencias leves:** la recompensa se retiene y se revisa; sin castigos duros.
10. **Doble confirmación** obligatoria para cerrar un favor.
11. **Solo positivo:** no hay puntaje público que limite accesos. Se premia, no se castiga.

## 6. Sumideros (dónde se gasta la moneda)

| Sumidero                      | Costo inicial | Notas                                           |
| ----------------------------- | ------------- | ----------------------------------------------- |
| Caja básica                   | 30            | Objetos para la mascota                         |
| Caja media                    | 100           |                                                 |
| Caja alta                     | 300           |                                                 |
| Cuidado de mascota            | 10 por semana | Gasto recurrente pequeño                        |
| Artículos de tienda de perfil | 40 a 400      | Marcos, insignias, temas, títulos               |
| Descuento de negocio          | Desde 500     | Un canje mensual por vecino                     |
| Ediciones de temporada        | Variable      | Fiestas Patrias, Señor de los Milagros, Navidad |

**Reglas de las cajas:**

- Mostrar siempre las probabilidades.
- Garantía: tras X cajas sin objeto raro, uno asegurado.
- Los duplicados se convierten en fragmentos.
- **No se pueden comprar con dinero real.** Así se mantiene el enganche sin entrar en terreno de apuestas.

**Descuentos de negocios:** el negocio absorbe el costo como marketing y la app lo promociona. El canje se limita por vecino para no vaciar la oferta. Los negocios pueden aportar premios exclusivos a cambio de visibilidad.

## 7. Progresión y ranking

- **Nivel:** sube con XP y desbloquea mascota, cajas y tienda.
- **Mascota:** se obtiene a un nivel determinado; sube con la actividad de su dueño.
- **Títulos:** por nivel (por ejemplo, "Vecino Aprendiz", "Guardián de la Cuadra").
- **Ranking basado solo en XP**, por cuadra, barrio y distrito.
- **Ligas** semanales o mensuales que se reinician, para que los nuevos puedan competir.
- **Buen vecino de la semana:** reconocimiento por nominación, con cupo por vecino.

## 8. Estimación de ritmo (vecino activo)

Referencia: un vecino activo gana unas 120 monedas por semana y uno casual unas 40.

| Hito                               | Tiempo aproximado                                        |
| ---------------------------------- | -------------------------------------------------------- |
| Primer favor y primera caja básica | Primera semana (favor de práctica guiado por la mascota) |
| Mascota nivel 3 (~100 XP)          | 3 a 4 favores                                            |
| Caja media                         | Semanal                                                  |
| Caja alta                          | Cada 3 semanas                                           |
| Primer descuento de negocio        | 4 a 5 semanas                                            |

**Comprobación de equilibrio (vecino activo, por semana):** 120 ganadas; ~10 a mascota, ~30 a una caja básica o ahorro para la media y el resto a ahorro. Si el ahorro promedio crece semana a semana, hay que subir sumideros o bajar ganancias.

**Valor de referencia:** si un descuento típico vale unos S/5 por 500 monedas, 1 moneda equivale a S/0,01. Un vecino activo "gana" el equivalente a ~S/1,20 por semana. Ese valor bajo protege a los negocios y hace poco atractivo el farming.

## 9. Métricas de control

- Moneda ganada vs. gastada por semana (debe estar cerca de equilibrio).
- Porcentaje de ayudas entre pares repetidos.
- Vecinos distintos ayudados por usuario.
- Tiempo para la primera mascota y la primera caja.
- Tasa de reportes y de favores sin completar.
- Longitud y repetición de cadenas de favores.

**Regla de ajuste:** si la moneda se acumula sin gastarse, bajar ganancias o añadir sumideros. Si se gasta demasiado rápido, subir topes o crear más formas de ganar.

## 10. Implementación

- Los valores (recompensas, topes, ventanas, modificadores) se guardan en **Remote Config** para ajustarlos sin publicar versión.
- Toda ganancia se calcula en **Cloud Functions**, nunca en el cliente.
- Cada otorgamiento y retención se registra para auditoría.
- Simular el modelo antes de fijar números; empezar con topes conservadores, que son más fáciles de subir que de bajar.

## 11. Pendientes por decidir

- Nombres finales de la moneda y de los favores.
- Bono de rachas semanales.
- Nivel exacto para obtener la mascota y curva de XP por nivel.
- Contenido y probabilidades de cada tipo de caja.
- Acuerdos con negocios (costos y cupos de descuento).
- Cálculo de la confianza oculta (factores y pesos).
