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
  if (x instanceof Date) return {timestampValue:x.toISOString()};
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
// Helpers above are local-only. Test writes use the same six-document protocol
// as ServiceEconomyEngine; negative cases deliberately tamper with that protocol.
function decode(fieldsMap) {
  return Object.fromEntries(Object.entries(fieldsMap).map(([k,v])=>[k,
    'integerValue' in v ? Number(v.integerValue) :
    'doubleValue' in v ? v.doubleValue :
    'stringValue' in v ? v.stringValue :
    'booleanValue' in v ? v.booleanValue : v.timestampValue]));
}
async function newUser(name) {
  const s=await signIn();
  await commit(s,initialization(s,{name}));
  return s;
}
async function setupPost(provider,suffix='') {
  const id='service-'+randomUUID()+suffix;
  await commit(null,[write('posts/'+id,{category:'service',status:'active',authorId:provider.uid})]);
  return id;
}
const key=(p,c,s,n)=>p+'_'+c+'_'+s+'_'+n;
async function build(client,provider,postId,operationId,rating=4,slot=1,p=period) {
  const beforeC=await get(client,root(client.uid));
  const beforeP=await get(client,root(provider.uid));
  const c=decode(beforeC.body.fields), s=decode(beforeP.body.fields);
  const id=key(p,client.uid,provider.uid,slot);
  const reward=(data,xp)=>({
    xp:data.xp+xp,monthlyXp:(data.rankingPeriod===p ? data.monthlyXp:0)+xp,
    rankingPeriod:p,lastServiceConfirmation:id,
  });
  const movement=(uid,other,type,xp)=>({
    id,confirmationId:id,uid,counterpartyUid:other,type,sourceId:postId,
    deltaXpTotal:xp,deltaXpMonth:xp,deltaCoins:0,period:p,status:'released',
  });
  const writes=[
    write(root(client.uid),reward(c,15),{update:true,timestamps:['updatedAt']}),
    write(root(provider.uid),{...reward(s,25),reviewCount:s.reviewCount+1,
      averageStars:(s.averageStars*s.reviewCount+rating)/(s.reviewCount+1)},
      {update:true,timestamps:['updatedAt']}),
    write('serviceConfirmations/'+id,{
      id,clientUid:client.uid,providerUid:provider.uid,postId,period:p,slot,rating,operationId,
    },{exists:false,timestamps:['createdAt']}),
    write(root(client.uid)+'/serviceOperations/'+operationId,{
      confirmationId:id,postId,providerUid:provider.uid,period:p,slot,rating,
    },{exists:false,timestamps:['createdAt']}),
    write(root(client.uid)+'/movimientos/'+id,
      movement(client.uid,provider.uid,'service_used_client',15),{exists:false,timestamps:['createdAt']}),
    write(root(provider.uid)+'/movimientos/'+id,
      movement(provider.uid,client.uid,'service_provided',25),{exists:false,timestamps:['createdAt']}),
  ];
  // Optimistic preconditions mimic the snapshots read by the Flutter transaction.
  writes[0].currentDocument={updateTime:beforeC.body.updateTime};
  writes[1].currentDocument={updateTime:beforeP.body.updateTime};
  return {writes,id};
}
const client=await newUser('Cliente'), provider=await newUser('Proveedor');
const stranger=await newUser('Ajeno');
const post=await setupPost(provider);
const first=await build(client,provider,post,'operation-00000001');

// Atomicity: omitting either user, either ledger or the receipt is denied.
for (const index of [0,1,3,4,5]) {
  await commit(client,first.writes.filter((_,i)=>i!==index),[403]);
}
assert.equal((await get(client,root(client.uid))).body.fields.xp.integerValue,'20');
assert.equal((await get(provider,root(provider.uid))).body.fields.xp.integerValue,'20');
await get(client,'serviceConfirmations/'+first.id,[404]);

// Tampered reward / coins / reputation must not bypass server checks.
for (const [index,field,value] of [[0,'xp',500],[1,'xp',500],[1,'averageStars',5],[1,'reviewCount',9]]) {
  const bad=structuredClone(first.writes);
  bad[index].update.fields[field]=encode(value);
  await commit(client,bad,[403]);
}
const extraCoins=[...first.writes,write(account(client.uid),{availableCoins:11},{update:true})];
await commit(client,extraCoins,[403]);
for (const invalidRating of [0,6,4.5]) {
  const bad=await build(client,provider,post,'operation-00000001',invalidRating);
  await commit(client,bad.writes,[403]);
}
const self=await build(provider,provider,post,'operation-self-0001');
await commit(provider,self.writes,[400,403]);
const missingFirst=await build(stranger,provider,post,'operation-missing1',4,2);
await commit(stranger,missingFirst.writes,[403]);
const forgedOwner=await build(client,stranger,post,'operation-forged01');
await commit(client,forgedOwner.writes,[403]);

await commit(client,first.writes);
const c=decode((await get(client,root(client.uid))).body.fields);
const p=decode((await get(provider,root(provider.uid))).body.fields);
assert.equal(c.xp,35);assert.equal(c.monthlyXp,35);
assert.equal(p.xp,45);assert.equal(p.monthlyXp,45);
assert.equal(p.averageStars,4);assert.equal(p.reviewCount,1);
assert.equal(decode((await get(client,account(client.uid))).body.fields).availableCoins,10);
assert.equal(decode((await get(provider,account(provider.uid))).body.fields).availableCoins,10);
await get(client,root(client.uid)+'/movimientos/'+first.id);
await get(provider,root(provider.uid)+'/movimientos/'+first.id);
await get(stranger,'serviceConfirmations/'+first.id,[403]);
await get(client,root(provider.uid)+'/movimientos/'+first.id,[403]);

// No editing, deleting or reusing already-existing economic evidence.
for (const path of ['serviceConfirmations/'+first.id,
  root(client.uid)+'/movimientos/'+first.id,
  root(client.uid)+'/serviceOperations/operation-00000001']) {
  await commit(client,[write(path,{rating:5},{update:true})],[403]);
  await commit(client,[{delete:base+'/'+path}],[403]);
}
const replay=await build(client,provider,post,'operation-00000001',4,2);
await commit(client,replay.writes,[400,403,409]);
const second=await build(client,provider,post,'operation-00000002',2,2);
await commit(client,second.writes);
assert.equal(decode((await get(provider,root(provider.uid))).body.fields).averageStars,3);
const third=await build(client,provider,post,'operation-00000003',5,3);
await commit(client,third.writes,[403]);
assert.equal(decode((await get(client,root(client.uid))).body.fields).xp,50);

// Reusing old evidence cannot authorize another XP increment.
await commit(client,[write(root(client.uid),{xp:65},{update:true,timestamps:['updatedAt']})],[403]);
// A failed transaction never leaves a confirmation or a ledger.
await get(client,'serviceConfirmations/'+third.id,[404]);
await get(client,root(client.uid)+'/movimientos/'+third.id,[404]);

// Current period is server-validated; lazy reset preserves total and private coins.
const oldClient=await newUser('Mes anterior'), oldProvider=await newUser('Mes anterior proveedor');
await commit(null,[
  write(root(oldClient.uid),{xp:100,monthlyXp:90,rankingPeriod:'2020-01'},{update:true}),
  write(root(oldProvider.uid),{xp:200,monthlyXp:70,rankingPeriod:'2020-01'},{update:true}),
]);
const oldPost=await setupPost(oldProvider);
const future=await build(oldClient,oldProvider,oldPost,'operation-future01',5,1,'2099-01');
await commit(oldClient,future.writes,[403]);
const reset=await build(oldClient,oldProvider,oldPost,'operation-reset001',5);
await commit(oldClient,reset.writes);
const resetC=decode((await get(oldClient,root(oldClient.uid))).body.fields);
const resetP=decode((await get(oldProvider,root(oldProvider.uid))).body.fields);
assert.equal(resetC.xp,115);assert.equal(resetC.monthlyXp,15);
assert.equal(resetP.xp,225);assert.equal(resetP.monthlyXp,25);
assert.equal(decode((await get(oldClient,account(oldClient.uid))).body.fields).availableCoins,10);

// Racing commits of one operation: one succeeds, the other cannot issue XP twice.
const racer=await newUser('Concurrente');
const race=await build(racer,provider,post,'operation-racing01',5);
const raced=await Promise.all([
  commit(racer,race.writes,[200,400,403,409]),
  commit(racer,race.writes,[200,400,403,409]),
]);
assert.equal(raced.filter(r=>r.status===200).length,1,JSON.stringify(raced));
assert.equal(decode((await get(racer,root(racer.uid))).body.fields).xp,35);
// Activity rewards require evidence and update the profile and ledger together.
const author=await newUser('Autor');
const helper=await newUser('Ayudante');
const favorId='favor-'+randomUUID(), eventId='event-'+randomUUID();
const offerPath='posts/'+favorId+'/helpOffers/'+helper.uid;
await commit(null,[
  write('posts/'+favorId,{category:'help',status:'active',authorId:author.uid}),
  write('posts/'+eventId,{
    category:'event',status:'active',authorId:author.uid,
    details:{startsAt:new Date(Date.now()+3600000)},
  }),
]);
await commit(helper,[write(offerPath,{helperName:'Ayudante'},{exists:false,timestamps:['offeredAt']})]);
const confirmOffer = {
  transform:{document:base+'/'+offerPath,fieldTransforms:[
    {fieldPath:'confirmedAt',setToServerValue:'REQUEST_TIME'},
  ]},
  currentDocument:{exists:true},
};
function activityWrites(type, postId, uid, other, xpBefore, coins) {
  const id=type+'_'+postId;
  return [
    write(root(uid),{
      xp:xpBefore+10,monthlyXp:xpBefore+10,rankingPeriod:period,lastActivityReward:id,
    },{update:true,timestamps:['updatedAt']}),
    write(root(uid)+'/movimientos/'+id,{
      id,confirmationId:id,uid,counterpartyUid:other,type,sourceId:postId,
      deltaXpTotal:10,deltaXpMonth:10,deltaCoins:coins,period,status:'released',
    },{exists:false,timestamps:['createdAt']}),
  ];
}
const favorWrites=activityWrites('favor_completed',favorId,helper.uid,author.uid,20,0);
await commit(author,[confirmOffer],[403]);
await commit(helper,[confirmOffer,...favorWrites],[403]);
await commit(author,favorWrites,[403]);
await commit(author,[confirmOffer,...favorWrites]);
await commit(author,[confirmOffer,...favorWrites],[400,403,409]);
assert.equal(decode((await get(helper,root(helper.uid))).body.fields).xp,30);

const eventWrites=activityWrites('event_attended',eventId,helper.uid,helper.uid,30,3);
const coinWrite=write(account(helper.uid),{availableCoins:13},{update:true});
await commit(helper,[...eventWrites,coinWrite],[403]);
await commit(helper,[write('posts/'+eventId+'/attendance/'+helper.uid,{
  response:'going',
},{exists:false,timestamps:['updatedAt']})]);
await commit(helper,eventWrites,[403]);
await commit(helper,[coinWrite],[403]);
await commit(helper,[...eventWrites,coinWrite]);
await commit(helper,[...eventWrites,coinWrite],[400,403,409]);
assert.equal(decode((await get(helper,root(helper.uid))).body.fields).xp,40);
assert.equal(decode((await get(helper,account(helper.uid))).body.fields).availableCoins,13);

// Bono unico de la mochila: monto fijo, sin publicacion de origen y una sola vez.
const scout=await newUser('Vecino preparado');
const intruder=await newUser('Intruso');
function backpackWrites(uid,{type='backpack_verified',sourceId='mochila',xp=100,coins=50,
  xpBefore=20,coinsBefore=10,other=uid}={}) {
  const id=type+'_'+sourceId;
  return {
    id,
    user:write(root(uid),{
      xp:xpBefore+xp,monthlyXp:xpBefore+xp,rankingPeriod:period,lastActivityReward:id,
    },{update:true,timestamps:['updatedAt']}),
    movement:write(root(uid)+'/movimientos/'+id,{
      id,confirmationId:id,uid,counterpartyUid:other,type,sourceId,
      deltaXpTotal:xp,deltaXpMonth:xp,deltaCoins:coins,period,status:'released',
    },{exists:false,timestamps:['createdAt']}),
    coins:write(account(uid),{availableCoins:coinsBefore+coins},{update:true}),
  };
}
const bonus=backpackWrites(scout.uid);
// Atomicidad: cada escritura por separado o incompleta se rechaza.
await commit(scout,[bonus.user,bonus.movement],[403]);
await commit(scout,[bonus.movement,bonus.coins],[403]);
await commit(scout,[bonus.user,bonus.coins],[403]);
await commit(scout,[bonus.coins],[403]);
// Montos inflados, origen ajeno, tipo falsificado y ajeno a la cuenta.
const inflatedXp=backpackWrites(scout.uid,{xp:500});
await commit(scout,[inflatedXp.user,inflatedXp.movement,inflatedXp.coins],[403]);
const inflatedCoins=backpackWrites(scout.uid,{coins:500});
await commit(scout,[inflatedCoins.user,inflatedCoins.movement,inflatedCoins.coins],[403]);
const otherSource=backpackWrites(scout.uid,{sourceId:'otra'});
await commit(scout,[otherSource.user,otherSource.movement,otherSource.coins],[403]);
const spoofed=backpackWrites(scout.uid,{type:'favor_completed'});
await commit(scout,[spoofed.user,spoofed.movement,spoofed.coins],[403]);
const foreign=backpackWrites(scout.uid);
await commit(intruder,[foreign.user,foreign.movement,foreign.coins],[403]);
assert.equal(decode((await get(scout,root(scout.uid))).body.fields).xp,20);
assert.equal(decode((await get(scout,account(scout.uid))).body.fields).availableCoins,10);
await get(scout,root(scout.uid)+'/movimientos/'+bonus.id,[404]);

// Reclamo valido: una sola vez, aunque se intente repetir o variar el origen.
await commit(scout,[bonus.user,bonus.movement,bonus.coins]);
assert.equal(decode((await get(scout,root(scout.uid))).body.fields).xp,120);
assert.equal(decode((await get(scout,root(scout.uid))).body.fields).monthlyXp,120);
assert.equal(decode((await get(scout,account(scout.uid))).body.fields).availableCoins,60);
await get(scout,root(scout.uid)+'/movimientos/'+bonus.id);
await commit(scout,[bonus.user,bonus.movement,bonus.coins],[400,403,409]);
const again=backpackWrites(scout.uid,{xpBefore:120,coinsBefore:60});
await commit(scout,[again.user,again.movement,again.coins],[400,403,409]);
const variant=backpackWrites(scout.uid,{sourceId:'otra',xpBefore:120,coinsBefore:60});
await commit(scout,[variant.user,variant.movement,variant.coins],[403]);
assert.equal(decode((await get(scout,root(scout.uid))).body.fields).xp,120);
assert.equal(decode((await get(scout,account(scout.uid))).body.fields).availableCoins,60);
console.log('Visto Bueno, recompensas de actividad y bono de mochila: atomicidad, evidencia, privacidad e idempotencia verificadas.');

