import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { geohashQueryBounds } from "geofire-common";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

import { isWithinRadius } from "./geo";

if (getApps().length === 0) initializeApp();

const db = getFirestore();
const radiusMeters = 500;
const freshLocationMs = 15 * 60 * 1000;

type Point = [number, number];

export const onEmergencyAlertCreated = onDocumentCreated(
  { document: "emergency_alerts/{alertId}", region: "southamerica-east1" },
  async (event) => {
    const alert = event.data?.data();
    if (!alert || alert.status !== "active" || !alert.location) return;

    const origin: Point = [alert.location.latitude, alert.location.longitude];
    const communityId = alert.communityId as string | undefined;
    const reporterUid = alert.reporterUid as string | undefined;
    if (!communityId || !reporterUid) {
      logger.error("SOS alert has no owner or community", {
        alertId: event.params.alertId,
      });
      return;
    }

    const bounds = geohashQueryBounds(origin, radiusMeters);
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
        createdAt: alert.createdAt ?? FieldValue.serverTimestamp(),
      });
    const candidateSnapshots = await Promise.all(
      bounds.map(([start, end]) =>
        db.collection("users")
          .where("communityId", "==", communityId)
          .where("proximityEnabled", "==", true)
          .orderBy("geohash")
          .startAt(start)
          .endAt(end)
          .get(),
      ),
    );
    const candidates = new Map(
      candidateSnapshots.flatMap((snapshot) =>
        snapshot.docs.map((document) => [document.id, document] as const),
      ),
    );
    const now = Date.now();
    const alertId = event.params.alertId;
    const recipients: FirebaseFirestore.QueryDocumentSnapshot[] = [];

    for (const candidate of candidates.values()) {
      if (candidate.id === reporterUid) continue;
      const location = candidate.get("location");
      const updatedAt = candidate.get("locationUpdatedAt") as Timestamp | undefined;
      if (!location || !updatedAt || now - updatedAt.toMillis() > freshLocationMs) {
        continue;
      }
      const target: Point = [location.latitude, location.longitude];
      if (!isWithinRadius(origin, target, radiusMeters)) continue;
      recipients.push(candidate);
    }

    await Promise.all(
      recipients.map(async (recipient) => {
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
          createdAt: alert.createdAt ?? FieldValue.serverTimestamp(),
        });

        const token = recipient.get("fcmToken") as string | undefined;
        if (!token) return;
        try {
          await getMessaging().send({
            token,
            notification: {
              title: "Emergencia cerca de ti",
              body: "Hay una alerta SOS activa en tu zona. Abre la app para verla.",
            },
            data: { alertId, type: "nearby_emergency" },
            android: { priority: "high" },
            apns: { payload: { aps: { sound: "default" } } },
          });
        } catch (error) {
          logger.error("Could not send nearby SOS notification", {
            alertId,
            recipientUid: recipient.id,
            error,
          });
          const code = (error as { code?: string }).code;
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            await recipient.ref.update({ fcmToken: FieldValue.delete() });
          }
        }
      }),
    );
    logger.info("Nearby SOS projections created", {
      alertId,
      eligibleRecipients: recipients.length,
    });
  },
);

export const onEmergencyAlertClosed = onDocumentUpdated(
  { document: "emergency_alerts/{alertId}", region: "southamerica-east1" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (
      !before ||
      !after ||
      before.status !== "active" ||
      after.status === "active"
    ) {
      return;
    }

    const alertId = event.params.alertId;
    const communityPost = db.collection("community_posts").doc(alertId);
    const communityPostSnapshot = await communityPost.get();
    if (communityPostSnapshot.exists) {
      await communityPost.update({
        status: after.status,
        priority: 0,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    const projections = await db
      .collectionGroup("nearby_emergency_alerts")
      .where("alertId", "==", alertId)
      .get();
    await Promise.all(
      projections.docs.map(async (projection) => {
        await projection.ref.update({
          status: after.status,
          updatedAt: FieldValue.serverTimestamp(),
        });
        const uid = projection.ref.parent.parent?.id;
        if (!uid) return;
        const profile = await db.collection("users").doc(uid).get();
        const token = profile.get("fcmToken") as string | undefined;
        if (!token) return;
        try {
          await getMessaging().send({
            token,
            notification: {
              title: "Actualización de alerta",
              body: after.status === "cancelled"
                ? "La alerta SOS cercana fue cancelada."
                : "La alerta SOS cercana fue marcada como resuelta.",
            },
            data: { alertId, type: "emergency_closed", status: after.status },
          });
        } catch (error) {
          logger.error("Could not send SOS closure notification", {
            alertId,
            recipientUid: uid,
            error,
          });
        }
      }),
    );
  },
);
