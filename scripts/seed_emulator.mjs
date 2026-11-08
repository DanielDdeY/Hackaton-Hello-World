// Script para inicializar datos base y configuracion economica en el emulador de Firestore.
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  initializeApp({ projectId: 'demo-hackaton-hello-world' });
}

const db = getFirestore();

async function sembrarConfiguracion() {
  console.log('Sembrando config/economia en Firestore...');
  await db.collection('config').doc('economia').set({
    xpBase: 100,
    xpIncremento: 10,
    fichasPorNivel: 10,
    nivelDesbloqueoMascota: 2,
    pityGarantizado: 21,
    costoCajaFichas: 15,
    recompensasFavores: {
      mini: { fichas: 5, xp: 10 },
      medio: { fichas: 15, xp: 30 },
      grande: { fichas: 40, xp: 80 },
      comunitario: { fichas: 30, xp: 60 },
    },
    updatedAt: new Date(),
  }, { merge: true });

  console.log('Configuracion economica sembrada exitosamente.');
}

sembrarConfiguracion().catch((error) => {
  console.error('Error al sembrar configuracion:', error);
  process.exit(1);
});
