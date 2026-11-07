"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onEmergencyAlertClosed = exports.onEmergencyAlertCreated = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const geofire_common_1 = require("geofire-common");
const firestore_2 = require("firebase-functions/v2/firestore");
const firebase_functions_1 = require("firebase-functions");
const geo_1 = require("./geo");
if ((0, app_1.getApps)().length === 0)
    (0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const radiusMeters = 500;
const freshLocationMs = 15 * 60 * 1000;
exports.onEmergencyAlertCreated = (0, firestore_2.onDocumentCreated)({ document: "emergency_alerts/{alertId}", region: "southamerica-east1" }, async (event) => {
    const alert = event.data?.data();
    if (!alert || alert.status !== "active" || !alert.location)
        return;
    const origin = [alert.location.latitude, alert.location.longitude];
    const communityId = alert.communityId;
    const reporterUid = alert.reporterUid;
    if (!communityId || !reporterUid) {
        firebase_functions_1.logger.error("SOS alert has no owner or community", {
            alertId: event.params.alertId,
        });
        return;
    }
    const bounds = (0, geofire_common_1.geohashQueryBounds)(origin, radiusMeters);
    await db.collection("users").doc(reporterUid)
        .collection("nearby_emergency_alerts")
        .doc(event.params.alertId)
        .set({
        alertId: event.params.alertId,
        location: alert.location,
        radiusMeters,
        status: "active",
        title: alert.title ?? "Tu alerta SOS",
        description: alert.description ?? "",
        emergencyType: alert.emergencyType ?? "emergency",
        photoPath: alert.photoPath ?? null,
        createdAt: alert.createdAt ?? firestore_1.FieldValue.serverTimestamp(),
    });
    const candidateSnapshots = await Promise.all(bounds.map(([start, end]) => db.collection("users")
        .where("communityId", "==", communityId)
        .where("proximityEnabled", "==", true)
        .orderBy("geohash")
        .startAt(start)
        .endAt(end)
        .get()));
    const candidates = new Map(candidateSnapshots.flatMap((snapshot) => snapshot.docs.map((document) => [document.id, document])));
    const now = Date.now();
    const alertId = event.params.alertId;
    const recipients = [];
    for (const candidate of candidates.values()) {
        if (candidate.id === reporterUid)
            continue;
        const location = candidate.get("location");
        const updatedAt = candidate.get("locationUpdatedAt");
        if (!location || !updatedAt || now - updatedAt.toMillis() > freshLocationMs) {
            continue;
        }
        const target = [location.latitude, location.longitude];
        if (!(0, geo_1.isWithinRadius)(origin, target, radiusMeters))
            continue;
        recipients.push(candidate);
    }
    await Promise.all(recipients.map(async (recipient) => {
        const projection = recipient.ref
            .collection("nearby_emergency_alerts")
            .doc(alertId);
        await projection.set({
            alertId,
            location: alert.location,
            radiusMeters,
            status: "active",
            title: alert.title ?? "Alerta SOS cercana",
            description: alert.description ?? "",
            emergencyType: alert.emergencyType ?? "emergency",
            photoPath: alert.photoPath ?? null,
            createdAt: alert.createdAt ?? firestore_1.FieldValue.serverTimestamp(),
        });
        const token = recipient.get("fcmToken");
        if (!token)
            return;
        try {
            await (0, messaging_1.getMessaging)().send({
                token,
                notification: {
                    title: "Emergencia cerca de ti",
                    body: "Hay una alerta SOS activa en tu zona. Abre la app para verla.",
                },
                data: { alertId, type: "nearby_emergency" },
                android: { priority: "high" },
                apns: { payload: { aps: { sound: "default" } } },
            });
        }
        catch (error) {
            firebase_functions_1.logger.error("Could not send nearby SOS notification", {
                alertId,
                recipientUid: recipient.id,
                error,
            });
            const code = error.code;
            if (code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token") {
                await recipient.ref.update({ fcmToken: firestore_1.FieldValue.delete() });
            }
        }
    }));
    firebase_functions_1.logger.info("Nearby SOS projections created", {
        alertId,
        eligibleRecipients: recipients.length,
    });
});
exports.onEmergencyAlertClosed = (0, firestore_2.onDocumentUpdated)({ document: "emergency_alerts/{alertId}", region: "southamerica-east1" }, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before ||
        !after ||
        before.status !== "active" ||
        after.status === "active") {
        return;
    }
    const alertId = event.params.alertId;
    const communityPost = db.collection("community_posts").doc(alertId);
    const communityPostSnapshot = await communityPost.get();
    if (communityPostSnapshot.exists) {
        await communityPost.update({
            status: after.status,
            priority: 0,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    const projections = await db
        .collectionGroup("nearby_emergency_alerts")
        .where("alertId", "==", alertId)
        .get();
    await Promise.all(projections.docs.map(async (projection) => {
        await projection.ref.update({
            status: after.status,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        const uid = projection.ref.parent.parent?.id;
        if (!uid)
            return;
        const profile = await db.collection("users").doc(uid).get();
        const token = profile.get("fcmToken");
        if (!token)
            return;
        try {
            await (0, messaging_1.getMessaging)().send({
                token,
                notification: {
                    title: "Actualización de alerta",
                    body: after.status === "cancelled"
                        ? "La alerta SOS cercana fue cancelada."
                        : "La alerta SOS cercana fue marcada como resuelta.",
                },
                data: { alertId, type: "emergency_closed", status: after.status },
            });
        }
        catch (error) {
            firebase_functions_1.logger.error("Could not send SOS closure notification", {
                alertId,
                recipientUid: uid,
                error,
            });
        }
    }));
});
//# sourceMappingURL=index.js.map