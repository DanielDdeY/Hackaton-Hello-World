import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { geohashQueryBounds } from "geofire-common";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

import { isWithinRadius } from "./geo";
import { emergencyAlertProjection } from "./emergency_projection";
export {
  abrirCaja,
  completarFavor,
  reclamarBonoMochila,
  sortearItem,
  CATALOGO_OFICIAL,
  COSTO_CAJA,
  REEMBOLSO_DUPLICADO,
  PITY_GARANTIZADO,
} from "./economia_mascota";

if (getApps().length === 0) initializeApp();

const db = getFirestore();
const radiusMeters = 200;
const freshLocationMs = 15 * 60 * 1000;

type Point = [number, number];

async function projectEmergencyAlert(
  alertId: string,
  alert: Record<string, unknown>,
  sendNotifications: boolean,
): Promise<void> {
  const location = alert.location as
    | { latitude: number; longitude: number }
    | undefined;
  if (!location || alert.status !== "active") return;
  const origin: Point = [location.latitude, location.longitude];
  const communityId = alert.communityId as string | undefined;
  const reporterUid = alert.reporterUid as string | undefined;
  if (!communityId || !reporterUid) {
    logger.error("SOS alert has no owner or community", { alertId });
    return;
  }

  const bounds = geohashQueryBounds(origin, radiusMeters);
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
  const recipients: FirebaseFirestore.QueryDocumentSnapshot[] = [];

  for (const candidate of candidates.values()) {
    if (candidate.id === reporterUid) continue;
    const recipientLocation = candidate.get("location");
    const updatedAt = candidate.get("locationUpdatedAt") as Timestamp | undefined;
    if (
      !recipientLocation ||
      !updatedAt ||
      now - updatedAt.toMillis() > freshLocationMs
    ) {
      continue;
    }
    const target: Point = [
      recipientLocation.latitude,
      recipientLocation.longitude,
    ];
    if (!isWithinRadius(origin, target, radiusMeters)) continue;
    recipients.push(candidate);
  }

  const createdAt = alert.createdAt ?? FieldValue.serverTimestamp();
  await Promise.all(
    [reporterUid, ...recipients.map((recipient) => recipient.id)].map(
      async (uid) => {
        const profile = candidates.get(uid) ??
          await db.collection("users").doc(uid).get();
        if (!profile.exists) return;
        const projection = profile.ref
          .collection("nearby_emergency_alerts")
          .doc(alertId);
        await projection.set(
          emergencyAlertProjection(alertId, alert, createdAt),
          { merge: true },
        );

        if (!sendNotifications || uid === reporterUid) return;
        const token = profile.get("fcmToken") as string | undefined;
        if (!token) return;
        try {
          await getMessaging().send({
            token,
            notification: {
              title: "Emergencia cerca de ti",
              body: "Hay una alerta SOS activa en tu zona. Los detalles están en proceso.",
            },
            data: { alertId, type: "nearby_emergency" },
            android: { priority: "high" },
            apns: { payload: { aps: { sound: "default" } } },
          });
        } catch (error) {
          logger.error("Could not send nearby SOS notification", {
            alertId,
            recipientUid: uid,
            error,
          });
          const code = (error as { code?: string }).code;
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            await profile.ref.update({ fcmToken: FieldValue.delete() });
          }
        }
      },
    ),
  );
  logger.info("Nearby SOS projections created", {
    alertId,
    eligibleRecipients: recipients.length,
  });
}

export const onEmergencyAlertCreated = onDocumentCreated(
  { document: "emergency_alerts/{alertId}", region: "southamerica-east1" },
  async (event) => {
    const alertRef = db.collection("emergency_alerts").doc(event.params.alertId);
    const latestAlert = await alertRef.get();
    const alert = latestAlert.data();
    if (!alert || alert.status !== "active") return;
    await projectEmergencyAlert(event.params.alertId, alert, true);
  },
);

export const onEmergencyAlertClosed = onDocumentUpdated(
  { document: "emergency_alerts/{alertId}", region: "southamerica-east1" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const closesAlert = before.status === "active" && after.status !== "active";
    const detailsChanged = ["title", "description", "emergencyType", "photoPath"]
      .some((field) => before[field] !== after[field]);
    if (!closesAlert && (after.status !== "active" || !detailsChanged)) return;

    const alertId = event.params.alertId;
    if (closesAlert) {
      const projections = await db
        .collectionGroup("nearby_emergency_alerts")
        .where("alertId", "==", alertId)
        .get();
      const communityPost = db.collection("community_posts").doc(alertId);
      const communityPostSnapshot = await communityPost.get();
      if (communityPostSnapshot.exists) {
        await communityPost.update({
          status: after.status,
          priority: 0,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

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
      return;
    }

    if (after.status !== "active") return;

    const projectionUpdate = {
      title: after.title ?? "Alerta SOS cercana",
      description: after.description ?? "",
      emergencyType: after.emergencyType ?? "emergency",
      photoPath: after.photoPath ?? null,
      detailsPending: false,
      updatedAt: FieldValue.serverTimestamp(),
    };
    const communityPost = db.collection("community_posts").doc(alertId);
    const communityPostSnapshot = await communityPost.get();
    if (communityPostSnapshot.exists) {
      await communityPost.update(projectionUpdate);
    }
    await projectEmergencyAlert(alertId, after, false);
  },
);
