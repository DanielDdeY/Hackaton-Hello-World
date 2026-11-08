const { test } = require("node:test");
const assert = require("node:assert/strict");
const { distanceMeters, isWithinRadius } = require("../lib/geo");

const origin = [40.4168, -3.7038];
const pointAtMetersNorth = (meters) => [
  origin[0] + meters / 111_195,
  origin[1],
];

test("distance uses geodesic meters", () => {
  assert.ok(Math.abs(distanceMeters(origin, pointAtMetersNorth(500)) - 500) < 1);
});

test("the radius includes 499m and excludes 501m", () => {
  assert.equal(isWithinRadius(origin, pointAtMetersNorth(499), 500), true);
  assert.equal(isWithinRadius(origin, pointAtMetersNorth(501), 500), false);
});
