import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

export interface ItemCatalogo {
  id: string;
  nombre: string;
  rareza: "comun" | "raro" | "legendario";
  probabilidad: number;
}

export const CATALOGO_OFICIAL: ItemCatalogo[] = [
  { id: "sombrero", nombre: "Sombrero Clásico", rareza: "comun", probabilidad: 0.40 },
  { id: "sombrero-papel-barco", nombre: "Barco de Papel", rareza: "comun", probabilidad: 0.30 },
  { id: "fiesta", nombre: "Gorrito de Fiesta", rareza: "raro", probabilidad: 0.18 },
  { id: "vikingo", nombre: "Casco Vikingo", rareza: "raro", probabilidad: 0.09 },
  { id: "mugiwara", nombre: "Sombrero Mugiwara", rareza: "legendario", probabilidad: 0.03 },
];

export const COSTO_CAJA = 30;
export const REEMBOLSO_DUPLICADO = 15;
export const PITY_GARANTIZADO = 21;

export function sortearItem(randomVal = Math.random()): ItemCatalogo {
  let acumulado = 0;
  for (const item of CATALOGO_OFICIAL) {
    acumulado += item.probabilidad;
    if (randomVal <= acumulado) return item;
  }
  return CATALOGO_OFICIAL[0];
}

export const abrirCaja = onCall(
  { region: "southamerica-east1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Debe iniciar sesión para abrir cajas.");
    }

    const db = getFirestore();
    const userRef = db.collection("users").doc(uid);
    const mascotaRef = userRef.collection("mascota").doc("cuy");

    return await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError("not-found", "Perfil de usuario no encontrado.");
      }
      const userData = userSnap.data() ?? {};
      const fichasDisponibles = Number(userData.fichas ?? 0);
      const xp = Number(userData.xp ?? 0);

      // Desbloqueo a partir de Nivel 2 (210 XP acumulados)
      if (xp < 210) {
        throw new HttpsError("failed-precondition", "La mascota se desbloquea en el Nivel 2 (210 XP).");
      }

      const mascotaSnap = await tx.get(mascotaRef);
      const mascotaData = mascotaSnap.data() ?? {};
      const itemsDesbloqueados: string[] = mascotaData.itemsDesbloqueados ?? [];
      const pityCount: number = Number(mascotaData.pityCount ?? 0);
      const cajasAbiertasTotal: number = Number(mascotaData.cajasAbiertasTotal ?? 0);
      const primeraCajaGratis: boolean = mascotaData.primeraCajaGratis ?? (cajasAbiertasTotal === 0);

      const costo = primeraCajaGratis ? 0 : COSTO_CAJA;
      if (fichasDisponibles < costo) {
        throw new HttpsError(
          "failed-precondition",
          `Fichas insuficientes (${costo} requeridas, ${fichasDisponibles} disponibles).`,
        );
      }

      const activarPity = pityCount >= (PITY_GARANTIZADO - 1);
      const itemSeleccionado = activarPity
        ? CATALOGO_OFICIAL.find((i) => i.rareza === "legendario")!
        : sortearItem();

      const yaLoTiene = itemsDesbloqueados.includes(itemSeleccionado.id);
      const esNuevo = !yaLoTiene;
      const reembolso = yaLoTiene ? REEMBOLSO_DUPLICADO : 0;
      const nuevoSaldo = fichasDisponibles - costo + reembolso;

      const nuevosItems = esNuevo ? [...itemsDesbloqueados, itemSeleccionado.id] : itemsDesbloqueados;
      const nuevoPity = itemSeleccionado.rareza === "legendario" ? 0 : pityCount + 1;

      tx.update(userRef, {
        fichas: nuevoSaldo,
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.set(mascotaRef, {
        itemsDesbloqueados: nuevosItems,
        pityCount: nuevoPity,
        primeraCajaGratis: false,
        cajasAbiertasTotal: cajasAbiertasTotal + 1,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      const movRef = userRef.collection("movimientos").doc();
      tx.set(movRef, {
        id: movRef.id,
        uid,
        tipo: "egreso",
        concepto: "compraCaja",
        fichas: costo - reembolso,
        xp: 0,
        descripcion: `Apertura de caja de sorpresas (${itemSeleccionado.nombre}${esNuevo ? " nuevo" : " repetido, reembolso 15 fichas"})`,
        fecha: FieldValue.serverTimestamp(),
        referenciaId: itemSeleccionado.id,
      });

      return {
        item: itemSeleccionado,
        esNuevo,
        esGarantizado: activarPity,
        fichasCobradas: costo,
        fichasDevueltas: reembolso,
        nuevoSaldo,
      };
    });
  },
);

export const completarFavor = onCall(
  { region: "southamerica-east1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Debe iniciar sesión para confirmar un favor.");
    }
    const postId = request.data?.postId;
    if (!postId || typeof postId !== "string" || postId.includes("/")) {
      throw new HttpsError("invalid-argument", "postId es requerido.");
    }

    const db = getFirestore();
    const postRef = db.collection("posts").doc(postId);

    return await db.runTransaction(async (tx) => {
      const postSnap = await tx.get(postRef);
      if (!postSnap.exists) {
        throw new HttpsError("not-found", "El favor solicitado no existe.");
      }
      const postData = postSnap.data() ?? {};
      if (postData.category !== "help" || postData.status !== "active") {
        throw new HttpsError("failed-precondition", "El favor no está activo.");
      }
      if (postData.authorId !== uid) {
        throw new HttpsError("permission-denied", "Solo el autor puede confirmar y agradecer el favor.");
      }
      const details = (postData.details ?? {}) as Record<string, unknown>;
      if (details.estado === "completado") {
        throw new HttpsError("already-exists", "Este favor ya fue completado.");
      }

      const hasAuthorReward = typeof details.hasReward === "boolean"
        ? details.hasReward
        : typeof details.rewardDescription === "string" && details.rewardDescription.trim() !== "";
      const fichasRecompensa = hasAuthorReward ? 0 : 5;
      const xpRecompensa = hasAuthorReward ? 0 : 10;
      const offers = await tx.get(postRef.collection("helpOffers"));
      const pending = offers.docs.filter((offer) => offer.id !== uid && offer.get("confirmedAt") == null);
      // Each digital award writes the offer, profile, wallet and movement.
      if (pending.length > (hasAuthorReward ? 400 : 100)) {
        throw new HttpsError("failed-precondition", "Confirma las ayudas individualmente desde la publicación.");
      }

      const period = new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString().slice(0, 7);
      const movementId = `favor_completed_${postId}`;
      const timestamp = FieldValue.serverTimestamp();
      const rewards = hasAuthorReward ? [] : await Promise.all(pending.map(async (offer) => {
        const helper = db.collection("users").doc(offer.id);
        const account = helper.collection("private").doc("account");
        const [profile, wallet] = await tx.getAll(helper, account);
        const data = profile.data();
        if (
          data?.profileVersion !== 1 || typeof data.xp !== "number" ||
          typeof data.monthlyXp !== "number" || typeof data.rankingPeriod !== "string" ||
          data.rankingPeriod > period || typeof wallet.get("availableCoins") !== "number"
        ) {
          throw new HttpsError("failed-precondition", "El ayudante debe sincronizar su perfil.");
        }
        return { helper, account, data };
      }));
      for (const { helper, account, data } of rewards) {
        const monthBase = data.rankingPeriod === period ? data.monthlyXp : 0;
        tx.update(helper, {
          xp: data.xp + xpRecompensa,
          monthlyXp: monthBase + xpRecompensa,
          rankingPeriod: period,
          lastActivityReward: movementId,
          updatedAt: timestamp,
        });
        tx.update(account, { availableCoins: FieldValue.increment(fichasRecompensa) });
        tx.create(helper.collection("movimientos").doc(movementId), {
          id: movementId,
          confirmationId: movementId,
          uid: helper.id,
          counterpartyUid: uid,
          type: "favor_completed",
          sourceId: postId,
          deltaXpTotal: xpRecompensa,
          deltaXpMonth: xpRecompensa,
          deltaCoins: fichasRecompensa,
          period,
          status: "released",
          createdAt: timestamp,
        });
      }
      for (const offer of pending) tx.update(offer.ref, { confirmedAt: timestamp });

      details.estado = "completado";
      tx.update(postRef, {
        details,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        postId,
        ayudantesRecompensados: rewards.length,
        fichasPorAyudante: fichasRecompensa,
        xpPorAyudante: xpRecompensa,
      };
    });
  },
);


