const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'falcaobarbershopv2'
});

const db = admin.firestore();

const COLLECTIONS = [
  'posts',
  'profissionais',
  'clientes',
  'barbearias',
  'servicos',
  'agendamentos',
];

const OLD_BUCKET = 'falcaobarbershop-67c44.firebasestorage.app';
const NEW_BUCKET = 'falcaobarbershopv2.firebasestorage.app';

async function updateCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  if (snapshot.empty) {
    console.log(`[${collectionName}] vazia, a saltar.`);
    return 0;
  }

  const batch = db.batch();
  let count = 0;

  snapshot.forEach(doc => {
    const data = doc.data();
    const updates = {};

    Object.entries(data).forEach(([key, value]) => {
      if (typeof value === 'string' && value.includes(OLD_BUCKET)) {
        updates[key] = value.replace(OLD_BUCKET, NEW_BUCKET);
        console.log(`[${collectionName}] ${doc.id}.${key} → actualizado`);
        count++;
      }
    });

    if (Object.keys(updates).length > 0) {
      batch.update(doc.ref, updates);
    }
  });

  await batch.commit();
  return count;
}

async function main() {
  let total = 0;
  for (const col of COLLECTIONS) {
    const updated = await updateCollection(col);
    total += updated;
  }
  console.log(`\nConcluído — ${total} campo(s) actualizados.`);
}

main().catch(console.error);