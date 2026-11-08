const { test } = require("node:test");
const assert = require("node:assert/strict");
const { emergencyAlertProjection } = require("../lib/emergency_projection");

test("projects a new SOS immediately with a red-alert placeholder", () => {
  const createdAt = new Date();
  const projection = emergencyAlertProjection(
    "alert-1",
    {
      location: { latitude: -12, longitude: -77 },
      communityId: "miraflores",
      reporterUid: "reporter-1",
    },
    createdAt,
  );

  assert.equal(projection.alertId, "alert-1");
  assert.equal(projection.status, "active");
  assert.equal(projection.radiusMeters, 200);
  assert.equal(projection.title, "Alerta SOS cercana");
  assert.equal(projection.description, "");
  assert.equal(projection.emergencyType, "emergency");
  assert.equal(projection.photoPath, null);
  assert.equal(projection.detailsPending, true);
});

test("projects the report details after the SOS form is submitted", () => {
  const projection = emergencyAlertProjection(
    "alert-2",
    {
      location: { latitude: -12, longitude: -77 },
      title: "Accidente de tránsito",
      description: "Choque en la avenida principal",
      emergencyType: "accident",
      photoPath: "incident_photos/reporter/alert-2/photo",
    },
    new Date(),
  );

  assert.equal(projection.title, "Accidente de tránsito");
  assert.equal(projection.description, "Choque en la avenida principal");
  assert.equal(projection.emergencyType, "accident");
  assert.equal(projection.detailsPending, false);
  assert.equal(
    projection.photoPath,
    "incident_photos/reporter/alert-2/photo",
  );
});
