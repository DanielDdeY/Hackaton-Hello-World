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
  { id: "piruleta", nombre: "Piruleta Dulce", rareza: "raro", probabilidad: 0.18 },
  { id: "shrek", nombre: "Orejas de Ogro", rareza: "raro", probabilidad: 0.09 },
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
    if (!postId || typeof postId !== "string") {
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
      if (postData.authorId !== uid) {
        throw new HttpsError("permission-denied", "Solo el autor puede confirmar y agradecer el favor.");
      }
      const details = (postData.details ?? {}) as Record<string, unknown>;
      if (details.estado === "completado") {
        throw new HttpsError("already-exists", "Este favor ya fue completado.");
      }

      const fichasRecompensa = Number(details.fichasRecompensa ?? 15);
      const xpRecompensa = Number(details.xpRecompensa ?? 30);
      const ayudantes: string[] = Array.isArray(details.ayudantes) ? details.ayudantes : [];

      for (const helperUid of ayudantes) {
        const helperRef = db.collection("users").doc(helperUid);
        tx.set(helperRef, {
          fichas: FieldValue.increment(fichasRecompensa),
          xp: FieldValue.increment(xpRecompensa),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        const movRef = helperRef.collection("movimientos").doc();
        tx.set(movRef, {
          id: movRef.id,
          uid: helperUid,
          tipo: "ingreso",
          concepto: "recompensaFavor",
          fichas: fichasRecompensa,
          xp: xpRecompensa,
          descripcion: `Recompensa por favor: ${details.title ?? "Favor vecinal"}`,
          fecha: FieldValue.serverTimestamp(),
          referenciaId: postId,
        });
      }

      details.estado = "completado";
      tx.update(postRef, {
        details,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        postId,
        ayudantesRecompensados: ayudantes.length,
        fichasPorAyudante: fichasRecompensa,
        xpPorAyudante: xpRecompensa,
      };
    });
  },
);

export const reclamarBonoMochila = onCall(
  { region: "southamerica-east1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Debe iniciar sesión para reclamar el bono.");
    }

    const db = getFirestore();
    const userRef = db.collection("users").doc(uid);

    return await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError("not-found", "Perfil de usuario no encontrado.");
      }
      const userData = userSnap.data() ?? {};
      const badges: string[] = userData.badges ?? [];

      if (userData.mochilaPreparada || badges.includes("vecino-preparado")) {
        throw new HttpsError("already-exists", "El bono de preparación ya fue reclamado.");
      }

      const fichasBono = 50;
      const xpBono = 100;

      tx.set(userRef, {
        fichas: FieldValue.increment(fichasBono),
        xp: FieldValue.increment(xpBono),
        badges: FieldValue.arrayUnion("vecino-preparado"),
        mochilaPreparada: true,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      const movRef = userRef.collection("movimientos").doc();
      tx.set(movRef, {
        id: movRef.id,
        uid,
        tipo: "ingreso",
        concepto: "bonoMochila",
        fichas: fichasBono,
        xp: xpBono,
        descripcion: "Bono por completar la mochila de emergencia",
        fecha: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        fichasOtorgadas: fichasBono,
        xpOtorgado: xpBono,
        badge: "vecino-preparado",
      };
    });
  },
);

