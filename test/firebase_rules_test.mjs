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
const storage = localEmulator('FIREBASE_STORAGE_EMULATOR_HOST', 'STORAGE_EMULATOR_HOST');
const documents = 'projects/' + project + '/databases/(default)/documents';
const photosRoot = storage + '/v0/b/' + bucket + '/o';

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
    response.status + ' instead of ' + accepted + ' on ' + new URL(url).pathname +
    ': ' + (await response.clone().text()).slice(0, 500),
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

function encode(value) {
  if (value === null) return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encode) } };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  return { mapValue: { fields: fields(value) } };
}

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, encode(value)]));
}

function firestoreAuth(session) {
  return session ? { Authorization: 'Bearer ' + session.token } : {};
}

async function write(id, data, session, { create = true, status = 200 } = {}) {
  const timestamps = create ? ['createdAt', 'updatedAt'] : ['updatedAt'];
  await request(firestore + '/v1/' + documents + ':commit', {
    method: 'POST',
    headers: firestoreAuth(session),
    status,
    json: {
      writes: [{
        update: { name: documents + '/posts/' + id, fields: fields(data) },
        ...(create ? {} : { updateMask: { fieldPaths: Object.keys(data) } }),
        currentDocument: { exists: !create },
        updateTransforms: timestamps.map((fieldPath) => ({
          fieldPath, setToServerValue: 'REQUEST_TIME',
        })),
      }],
    },
  });
}

function storageAuth(session) {
  return session ? { Authorization: 'Firebase ' + session.token } : {};
}

async function writeDocument(collection, id, fields, session, { transforms = [] } = {}) {
  await request(firestore + '/v1/' + documents + ':commit', {
    method: 'POST',
    headers: firestoreAuth(session),
    json: {
      writes: [{
        update: { name: documents + '/' + collection + '/' + id, fields },
        currentDocument: { exists: false },
        ...(transforms.length === 0 ? {} : {
          updateTransforms: transforms.map((fieldPath) => ({
            fieldPath, setToServerValue: 'REQUEST_TIME',
          })),
        }),
      }],
    },
  });
}

async function upload(path, session, {
  contentType = 'image/jpeg',
  body = Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
  status = 200,
} = {}) {
  await request(photosRoot + '?uploadType=media&name=' + encodeURIComponent(path), {
    method: 'POST',
    headers: { ...storageAuth(session), 'Content-Type': contentType },
    body,
    status,
  });
}

const owner = await signIn();
const stranger = await signIn();
const emergencyId = 'emergency-' + randomUUID();
const helpId = 'help-' + randomUUID();
const rejectedId = 'rejected-' + randomUUID();
const docUrl = (id) => firestore + '/v1/' + documents + '/posts/' + id;
const photoPath = (uid, id) => ['posts', uid, id, '0_1000.jpg'].join('/');
const photoUrl = (path) => photosRoot + '/' + encodeURIComponent(path);
const metadata = (path) => ({ storagePath: path, downloadUrl: photoUrl(path) + '?alt=media' });

const alertUrl = (id) => firestore + '/v1/' + documents + '/emergency_alerts/' + id;
const missingAlertId = 'sos-' + randomUUID();
const communityPostUrl = (id) => firestore + '/v1/' + documents + '/community_posts/' + id;
await request(communityPostUrl(missingAlertId), {
  headers: firestoreAuth(owner),
  status: 404,
});
await request(alertUrl(missingAlertId), {
  headers: firestoreAuth(owner),
  status: 404,
});
await writeDocument('users', owner.uid, {
  communityId: { stringValue: 'test-district' },
}, owner);
await request(firestore + '/v1/' + documents + '/users/' + owner.uid, {
  headers: firestoreAuth(owner),
});
await request(firestore + '/v1/' + documents + '/users/' + owner.uid, {
  headers: firestoreAuth(stranger),
  status: 403,
});
const ownerProfileUrl = firestore + '/v1/' + documents + '/users/' + owner.uid;
await request(ownerProfileUrl, { headers: firestoreAuth(owner) });
// El login por celular lee el perfil del uid guardado en phoneIndex, que puede
// pertenecer a otra sesión anónima del mismo vecino.
await request(ownerProfileUrl, { headers: firestoreAuth(stranger) });
await request(ownerProfileUrl, { status: [401, 403] });
await writeDocument('emergency_alerts', missingAlertId, {
  reporterUid: { stringValue: owner.uid },
  location: { geoPointValue: { latitude: -12.0464, longitude: -77.0428 } },
  communityId: { stringValue: 'test-district' },
  radiusMeters: { integerValue: '200' },
  status: { stringValue: 'active' },
}, owner, { transforms: ['createdAt', 'updatedAt'] });
await request(alertUrl(missingAlertId), { headers: firestoreAuth(owner) });
await request(alertUrl(missingAlertId), {
  headers: firestoreAuth(stranger),
  status: 403,
});

const emergency = {
  id: emergencyId, category: 'emergency', authorId: owner.uid,
  schemaVersion: 2, status: 'active', details: { type: 'robbery' },
  photos: [], mediaStatus: 'uploading',
};

await write(emergencyId, emergency, null, { status: [401, 403] });
await write(emergencyId, emergency, stranger, { status: 403 });
await write(emergencyId, emergency, owner);
await request(docUrl(emergencyId), { headers: firestoreAuth(stranger) });
await request(docUrl(emergencyId), { status: [401, 403] });

const rejected = { ...emergency, id: rejectedId };
await write(rejectedId, { ...rejected, category: 'invalid' }, owner, { status: 403 });
await write(rejectedId, { ...rejected, details: 'invalid' }, owner, { status: 403 });
await write(rejectedId, { ...rejected, mediaStatus: 'ready' }, owner, { status: 403 });
await write(rejectedId, {
  ...rejected, mediaStatus: 'ready',
  photos: [metadata(photoPath(stranger.uid, rejectedId))],
}, owner, { status: 403 });

const emergencyPhoto = photoPath(owner.uid, emergencyId);
await upload(emergencyPhoto, owner);
await upload(emergencyPhoto, stranger, { status: [401, 403] });
await upload(photoPath(owner.uid, rejectedId), null, { status: [401, 403] });
await upload(photoPath(owner.uid, rejectedId), owner, { contentType: 'text/plain', status: [401, 403] });
await upload(photoPath(owner.uid, rejectedId), owner, { body: Buffer.alloc(5 * 1024 * 1024), status: [401, 403] });
await request(photoUrl(emergencyPhoto) + '?alt=media', { headers: storageAuth(stranger) });
await request(photoUrl(emergencyPhoto) + '?alt=media', { status: [401, 403] });

const ready = { photos: [metadata(emergencyPhoto)], mediaStatus: 'ready' };
await write(emergencyId, ready, stranger, { create: false, status: 403 });
await write(emergencyId, { ...ready, authorId: stranger.uid }, owner, { create: false, status: 403 });
await write(emergencyId, { ...ready, category: 'news' }, owner, { create: false, status: 403 });
await write(emergencyId, { ...ready, createdAt: 'changed' }, owner, { create: false, status: 403 });
await write(emergencyId, ready, owner, { create: false });
await write(emergencyId, { photos: [], mediaStatus: 'failed' }, owner, { create: false });

// Ayuda is allowed to upload before the post document exists.
const helpPhoto = photoPath(owner.uid, helpId);
await upload(helpPhoto, owner);
await write(helpId, {
  ...emergency, id: helpId, category: 'help', details: { description: 'Ayuda de prueba' },
  photos: [metadata(helpPhoto)], mediaStatus: 'ready',
}, owner);
await request(docUrl(helpId), { method: 'DELETE', headers: firestoreAuth(stranger), status: 403 });
await request(docUrl(helpId), { method: 'DELETE', headers: firestoreAuth(owner) });
await request(photoUrl(helpPhoto), { method: 'DELETE', headers: storageAuth(stranger), status: [401, 403] });
await request(photoUrl(helpPhoto), { method: 'DELETE', headers: storageAuth(owner), status: [200, 204] });

const serviceId = 'service-' + randomUUID();
const otherServiceId = 'service-other-' + randomUUID();
const newsId = 'news-' + randomUUID();
const service = {
  ...emergency, id: serviceId, category: 'service', authorName: 'Vecino', mediaStatus: 'none',
  details: {
    title: 'Reparación de laptops', information: 'Diagnóstico y mantenimiento',
    serviceCategory: 'technology', categorySource: 'keyword',
    mode: 'provide_service', price: 25.5, currency: 'PEN',
    paymentMethods: ['yape'], contactPhone: '987654321',
  },
};
const news = {
  ...emergency, id: newsId, category: 'news', authorName: 'Vecino', mediaStatus: 'none',
  details: { title: 'Aviso vecinal', content: 'Primera línea\nSegunda línea', quickCategory: null },
};

for (const patch of [
  { serviceCategory: 'unknown' },
  { price: -1 },
  { price: '25' },
  { contactPhone: '887654321' },
  { contactPhone: '9876543210' },
]) {
  await write(serviceId, { ...service, details: { ...service.details, ...patch } }, owner, { status: 403 });
}
for (const patch of [{ title: '' }, { content: ' \t\n ' }, { title: 123 }]) {
  await write(newsId, { ...news, details: { ...news.details, ...patch } }, owner, { status: 403 });
}
await write(serviceId, service, owner);
await write(otherServiceId, {
  ...service, id: otherServiceId, details: { ...service.details, serviceCategory: 'food', price: 0 },
}, owner);
await write(newsId, news, owner);

async function readFeed(category, session, { serviceCategory, startsAfter, status = 200 } = {}) {
  const equalTo = (fieldPath, value) => ({
    fieldFilter: { field: { fieldPath }, op: 'EQUAL', value: encode(value) },
  });
  const response = await request(firestore + '/v1/' + documents + ':runQuery', {
    method: 'POST',
    headers: firestoreAuth(session),
    status,
    json: {
      structuredQuery: {
        from: [{ collectionId: 'posts' }],
        where: {
          compositeFilter: {
            op: 'AND', filters: [
              equalTo('category', category),
              equalTo('status', 'active'),
              ...(serviceCategory ? [equalTo('details.serviceCategory', serviceCategory)] : []),
              ...(startsAfter ? [{
                fieldFilter: {
                  field: { fieldPath: 'details.startsAt' },
                  op: 'GREATER_THAN',
                  value: encode(startsAfter),
                }
              }] : []),
            ]
          }
        },
        orderBy: [startsAfter
          ? { field: { fieldPath: 'details.startsAt' }, direction: 'ASCENDING' }
          : { field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
        limit: 30,
      },
    },
  });
  if (!response.ok) return [];
  return (await response.json()).flatMap(({ document }) => document ? [document.name] : []);
}

const services = await readFeed('service', stranger);
assert.ok(services.some((path) => path.endsWith('/' + serviceId)));
assert.ok(services.some((path) => path.endsWith('/' + otherServiceId)));
const filteredServices = await readFeed('service', stranger, { serviceCategory: 'technology' });
assert.ok(filteredServices.some((path) => path.endsWith('/' + serviceId)));
assert.ok(!filteredServices.some((path) => path.endsWith('/' + otherServiceId)));
assert.ok((await readFeed('news', stranger)).some((path) => path.endsWith('/' + newsId)));
await readFeed('news', null, { status: [401, 403] });

const eventId = 'event-' + randomUUID();
const laterId = 'event-later-' + randomUUID();
const soonId = 'event-soon-' + randomUUID();
const afterDays = (days) => new Date(Date.now() + days * 24 * 60 * 60 * 1000);
const event = {
  ...emergency, id: eventId, category: 'event', mediaStatus: 'none',
  details: { title: 'Reunión vecinal', place: 'Local comunal', startsAt: afterDays(2) },
};
for (const patch of [
  { title: '   ' },
  { place: '' },
  { startsAt: afterDays(-1) },
  { startsAt: 'mañana' },
  { attendees: -1 },
  { attendees: 2.5 },
  { description: 123 },
]) {
  await write(eventId, { ...event, details: { ...event.details, ...patch } }, owner, { status: 403 });
}
await write(eventId, event, stranger, { status: 403 });
await write(eventId, event, owner);
await write(laterId, {
  ...event, id: laterId,
  details: { ...event.details, startsAt: afterDays(3), attendees: 14, description: 'Simulacro' },
}, owner);
await write(soonId, {
  ...event, id: soonId, details: { ...event.details, startsAt: afterDays(0.5) },
}, owner);
const eventPaths = await readFeed('event', stranger, { startsAfter: afterDays(1) });
assert.deepEqual(eventPaths, [documents + '/posts/' + eventId, documents + '/posts/' + laterId]);
await readFeed('event', null, { startsAfter: afterDays(1), status: [401, 403] });

console.log('Reglas de Firestore y Storage verificadas con dos sesiones anónimas locales.');
