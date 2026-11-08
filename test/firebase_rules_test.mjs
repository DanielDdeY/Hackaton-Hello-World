import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const project = 'demo-hackaton-hello-world';
const bucket = project + '.firebasestorage.app';

function localEmulator(...names) {
  const value = names.map((name) => process.env[name]).find(Boolean);
  assert.ok(value, 'Run this test with Firebase emulators:exec: ' + names[0]);
  const url = new URL(value.includes('://') ? value : 'http://' + value);
  assert.ok(
    url.protocol === 'http:' &&
      ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname),
    'The rules test only accepts local emulators.',
  );
  return url.origin;
}

const auth = localEmulator('FIREBASE_AUTH_EMULATOR_HOST');
const firestore = localEmulator('FIRESTORE_EMULATOR_HOST');
const storage = localEmulator(
  'FIREBASE_STORAGE_EMULATOR_HOST',
  'STORAGE_EMULATOR_HOST',
);
const documents = 'projects/' + project + '/databases/(default)/documents';
const objects = storage + '/v0/b/' + bucket + '/o';

async function request(url, { status = 200, json, ...options } = {}) {
  const response = await fetch(url, {
    signal: AbortSignal.timeout(20000),
    ...options,
    headers: {
      ...(json === undefined ? {} : { 'Content-Type': 'application/json' }),
      ...options.headers,
    },
    body: json === undefined ? options.body : JSON.stringify(json),
  });
  const accepted = Array.isArray(status) ? status : [status];
  assert.ok(
    accepted.includes(response.status),
    response.status + ' instead of ' + accepted + ' on ' +
      new URL(url).pathname + ': ' +
      (await response.clone().text()).slice(0, 500),
  );
  return response;
}

async function signIn() {
  const response = await request(
    auth + '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-veciapp',
    { method: 'POST', json: { returnSecureToken: true } },
  );
  const session = await response.json();
  assert.ok(session.localId && session.idToken);
  return { uid: session.localId, token: session.idToken };
}

function firestoreAuth(session) {
  return session ? { Authorization: 'Bearer ' + session.token } : {};
}

function storageAuth(session) {
  return session ? { Authorization: 'Firebase ' + session.token } : {};
}

async function writeDocument(
  collection,
  id,
  fields,
  session,
  { create = true } = {},
) {
  await request(firestore + '/v1/' + documents + ':commit', {
    method: 'POST',
    headers: firestoreAuth(session),
    json: {
      writes: [{
        update: { name: documents + '/' + collection + '/' + id, fields },
        currentDocument: { exists: !create },
      }],
    },
  });
}

async function upload(path, session, {
  contentType = 'image/jpeg',
  body = Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
} = {}) {
  await request(objects + '?uploadType=media&name=' + encodeURIComponent(path), {
    method: 'POST',
    headers: { ...storageAuth(session), 'Content-Type': contentType },
    body,
  });
}

const id = 'open-' + randomUUID();
const profileUrl = firestore + '/v1/' + documents + '/users/' + id;

// Firestore abierto: sin sesión puede crear, leer y sobrescribir.
await writeDocument('users', id, {
  uid: { stringValue: 'anonymous' },
  communityId: { stringValue: 'test-district' },
}, null);
await request(profileUrl);
await writeDocument('users', id, {
  uid: { stringValue: 'anonymous-2' },
  communityId: { stringValue: 'test-district' },
}, null, { create: false });

// Firestore abierto: una sesión puede leer y escribir datos de otra.
const owner = await signIn();
const stranger = await signIn();
const strangerId = 'open-stranger-' + randomUUID();
await writeDocument('users', strangerId, {
  uid: { stringValue: stranger.uid },
}, owner);
await request(
  firestore + '/v1/' + documents + '/users/' + strangerId,
  { headers: firestoreAuth(stranger) },
);
await request(profileUrl, { headers: firestoreAuth(stranger) });

// Storage abierto: sin sesión puede subir y descargar.
const path = 'posts/anonymous/' + id + '/0_1000.jpg';
await upload(path, null);
await request(objects + '/' + encodeURIComponent(path) + '?alt=media');
await upload('posts/anonymous/' + id + '/1_2000.jpg', owner);
await request(objects + '/' + encodeURIComponent(path) + '?alt=media', {
  method: 'DELETE',
  headers: storageAuth(stranger),
  status: [200, 204],
});

console.log(
  'Reglas abiertas verificadas: Firestore y Storage aceptan lectura y ' +
    'escritura con y sin sesión.',
);
