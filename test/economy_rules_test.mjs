import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const project = process.env.GCLOUD_PROJECT ?? 'demo-hackaton-hello-world';
assert.equal(project, 'demo-hackaton-hello-world');
for (const name of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  assert.match(process.env[name] ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
}
const db = 'http://' + process.env.FIRESTORE_EMULATOR_HOST;
const auth = 'http://' + process.env.FIREBASE_AUTH_EMULATOR_HOST;
const base = 'projects/' + project + '/databases/(default)/documents';
const token = session => ({Authorization: 'Bearer ' + (session?.token ?? 'owner')});
const period = new Date(Date.now() - 5 * 3600000).toISOString().slice(0, 7);
function encode(x) {
  if (typeof x === 'boolean') return {booleanValue:x};
  if (typeof x === 'string') return {stringValue:x};
  if (typeof x === 'number') return Number.isInteger(x) ? {integerValue:String(x)} : {doubleValue:x};
  return {mapValue:{fields:fields(x)}};
}
const fields = obj => Object.fromEntries(Object.entries(obj).map(([k,v])=>[k,encode(v)]));
async function request(url, options = {}, statuses = [200]) {
  const response = await fetch(url, {signal:AbortSignal.timeout(30000), ...options});
  const body = await response.json();
  assert.ok(statuses.includes(response.status), response.status + ': ' + JSON.stringify(body));
  return {status:response.status, body};
}
async function signIn() {
  const {body} = await request(auth + '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key', {
    method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({returnSecureToken:true}),
  });
  return {uid:body.localId,token:body.idToken};
}
function write(path, data, {update=false, exists, timestamps=[]} = {}) {
  return {update:{name:base+'/'+path,fields:fields(data)},
    ...(update ? {updateMask:{fieldPaths:Object.keys(data)}} : {}),
    ...(exists === undefined ? {} : {currentDocument:{exists}}),
    ...(timestamps.length ? {updateTransforms:timestamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))} : {})};
}
async function commit(session,writes,statuses=[200]) {
  return request(db+'/v1/'+base+':commit',{
    method:'POST',headers:{...token(session),'Content-Type':'application/json'},
    body:JSON.stringify({writes}),
  },statuses);
}
async function get(session,path,statuses=[200]) {
  return request(db+'/v1/'+base+'/'+path,{headers:token(session)},statuses);
}
const root = uid => 'users/'+uid;
const account = uid => root(uid)+'/private/account';
const profile = (name='Ana') => ({
  name,xp:20,monthlyXp:20,rankingPeriod:period,profileVersion:1,districtKey:'',
  averageStars:0,reviewCount:0,
});
function initialization(session, overrides={}) {
  return [
    write(root(session.uid),{...profile(),...overrides},{exists:false,timestamps:['createdAt','updatedAt']}),
    write(account(session.uid),{phoneNumber:'',email:'',availableCoins:10},{exists:false}),
  ];
}
const a=await signIn(), b=await signIn();
await commit(a,initialization(a));
await commit(b,initialization(b));
await get(b,root(a.uid));
await get(b,account(a.uid),[403]);
await get(a,account(a.uid));
await commit(a,[write(root(a.uid),{xp:9999},{update:true})],[403]);
await commit(a,[write(root(a.uid),{monthlyXp:9999},{update:true})],[403]);
await commit(a,[write(root(a.uid),{averageStars:5},{update:true})],[403]);
await commit(a,[write(account(a.uid),{availableCoins:9999},{update:true})],[403]);
await commit(a,[write(root(a.uid),{phoneNumber:'secret'},{update:true})],[403]);
await commit(a,[write(root(a.uid),{name:'Nombre actualizado'},{update:true})]);
await commit(a,[write(account(a.uid),{phoneNumber:'+51900000000'},{update:true})]);
await commit(a,[write(root(a.uid)+'/movimientos/forged',{deltaXpTotal:15})],[403]);
await commit(a,[write('serviceConfirmations/forged',{clientUid:a.uid})],[403]);
await get(a,'phoneIndex/+51900000000',[403]);

// Welcome creation is all-or-nothing and a retry cannot recreate the documents.
const c=await signIn();
await commit(c,[initialization(c)[0]],[403]);
await get(c,root(c.uid),[404]);
await commit(c,initialization(c,{xp:200}),[403]);
await get(c,root(c.uid),[404]);
await commit(c,initialization(c,{rankingPeriod:'2099-01'}),[403]);
const concurrent=await Promise.all([
  commit(c,initialization(c),[200,400,403,409]),
  commit(c,initialization(c),[200,400,403,409]),
]);
assert.equal(concurrent.filter(r=>r.status===200).length,1);
assert.equal((await get(c,root(c.uid))).body.fields.xp.integerValue,'20');
assert.equal((await get(c,account(c.uid))).body.fields.availableCoins.integerValue,'10');

// Seed legacy data through emulator admin, not production, then exercise owner migration.
const legacy=await signIn();
await commit(null,[write(root(legacy.uid),{name:'Antiguo',xp:325,weeklyXp:90,
  monthlyXp:50,rankingPeriod:'2020-01',phoneNumber:'999',email:'old@example.test',
  availableCoins:7,communityId:'ate',fcmToken:'private-token'})]);
await get(b,root(legacy.uid),[403]);
const migration={name:'Antiguo',xp:325,weeklyXp:90,monthlyXp:0,rankingPeriod:period,
  profileVersion:1,districtKey:'',averageStars:0,reviewCount:0,communityId:'ate'};
await commit(legacy,[
  write(root(legacy.uid),migration),
  write(account(legacy.uid),{phoneNumber:'999',email:'old@example.test',availableCoins:7}),
  write(root(legacy.uid)+'/private/proximity',{kind:'proximity',uid:legacy.uid,
    communityId:'ate',fcmToken:'private-token'}),
]);
await get(b,root(legacy.uid));
await get(b,root(legacy.uid)+'/private/proximity',[403]);
assert.equal((await get(legacy,account(legacy.uid))).body.fields.availableCoins.integerValue,'7');
assert.equal((await get(legacy,root(legacy.uid))).body.fields.xp.integerValue,'325');
await commit(legacy,[write(root(legacy.uid),{monthlyXp:50},{update:true})],[403]);

const future=await signIn();
await commit(null,[write(root(future.uid),{...profile(),xp:100,monthlyXp:25,rankingPeriod:'2099-01'})]);
await commit(future,[write(root(future.uid),{rankingPeriod:period,monthlyXp:0},{update:true})],[403]);
await commit(future,[write(root(future.uid),{name:'Reloj corregido'},{update:true})]);

// District/period filtering, >0 and total-XP tie break use the same query as Flutter.
const prefix='district-'+randomUUID();
for (const [i,monthlyXp,xp,rankingPeriod,districtKey] of [
  [1,30,100,period,prefix],[2,30,200,period,prefix],[3,0,300,period,prefix],
  [4,100,400,'2020-01',prefix],[5,100,500,period,prefix+'-other'],
]) {
  await commit(null,[write('users/ranking-'+prefix+'-'+i,{
    ...profile(),monthlyXp,xp,rankingPeriod,districtKey,
  })]);
}
const filter=(fieldPath,op,value)=>({fieldFilter:{field:{fieldPath},op,value:encode(value)}});
const query=await request(db+'/v1/'+base+':runQuery',{
  method:'POST',headers:{...token(a),'Content-Type':'application/json'},
  body:JSON.stringify({structuredQuery:{
    from:[{collectionId:'users'}],
    where:{compositeFilter:{op:'AND',filters:[
      filter('profileVersion','EQUAL',1),filter('districtKey','EQUAL',prefix),
      filter('rankingPeriod','EQUAL',period),filter('monthlyXp','GREATER_THAN',0),
    ]}},
    orderBy:[{field:{fieldPath:'monthlyXp'},direction:'DESCENDING'},
      {field:{fieldPath:'xp'},direction:'DESCENDING'}],limit:50,
  }}),
});
const rows=query.body.flatMap(x=>x.document?[x.document]:[]);
assert.equal(rows.length,2);
assert.ok(rows[0].name.endsWith('-2'));
assert.ok(rows[1].name.endsWith('-1'));
console.log('Economía fase 1: privacidad, bono atómico, reintentos, migración, reloj futuro y ranking verificados.');

