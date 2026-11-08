const assert = require("node:assert/strict");
const { test } = require("node:test");
const {
  sortearItem,
  CATALOGO_OFICIAL,
  COSTO_CAJA,
  REEMBOLSO_DUPLICADO,
  PITY_GARANTIZADO,
} = require("../lib/index.js");

test("catálogo oficial contiene 5 artículos con probabilidades que suman 1.0", () => {
  assert.equal(CATALOGO_OFICIAL.length, 5);
  const totalProb = CATALOGO_OFICIAL.reduce((acc, item) => acc + item.probabilidad, 0);
  assert.ok(Math.abs(totalProb - 1.0) < 0.001, `Probabilidad suma ${totalProb}`);

  const legendario = CATALOGO_OFICIAL.find((i) => i.rareza === "legendario");
  assert.ok(legendario);
  assert.equal(legendario.id, "mugiwara");
});

test("sortearItem devuelve artículos según rango de probabilidad acumulada", () => {
  // 0.00 a 0.40 -> sombrero
  assert.equal(sortearItem(0.1).id, "sombrero");
  // 0.40 a 0.70 -> sombrero-papel-barco
  assert.equal(sortearItem(0.5).id, "sombrero-papel-barco");
  // 0.70 a 0.88 -> piruleta
  assert.equal(sortearItem(0.75).id, "piruleta");
  // 0.88 a 0.97 -> shrek
  assert.equal(sortearItem(0.92).id, "shrek");
  // 0.97 a 1.00 -> mugiwara
  assert.equal(sortearItem(0.99).id, "mugiwara");
});

test("constantes económicas coinciden con la especificación oficial", () => {
  assert.equal(COSTO_CAJA, 30);
  assert.equal(REEMBOLSO_DUPLICADO, 15);
  assert.equal(PITY_GARANTIZADO, 21);
});

