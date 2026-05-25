const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

const OLD_DOMAIN = "colegio.local";
const NEW_DOMAIN = "iv.edu.pe";

function oldEmailFromDni(dni) {
return `${dni}@${OLD_DOMAIN}`;
}

function newEmailFromDni(dni) {
return `${dni}@${NEW_DOMAIN}`;
}

async function updateAuthEmailByUid(uid, dni) {
const oldEmail = oldEmailFromDni(dni);
const newEmail = newEmailFromDni(dni);

try {
const user = await auth.getUser(uid);

if (user.email === newEmail) {
console.log(`Auth ya actualizado: ${newEmail}`);
return;
}

if (user.email !== oldEmail) {
console.log(
`Aviso: el usuario ${uid} tiene correo ${user.email}, no ${oldEmail}. Se actualizará a ${newEmail}.`
);
}

await auth.updateUser(uid, {
email: newEmail,
emailVerified: true,
});

console.log(`Auth actualizado: ${oldEmail} -> ${newEmail}`);
} catch (error) {
console.error(`Error actualizando Auth UID ${uid}:`, error.message);
}
}

async function updateUsuariosCollection() {
console.log("Actualizando colección usuarios...");

const snapshot = await db.collection("usuarios").get();

if (snapshot.empty) {
console.log("No hay documentos en usuarios.");
return;
}

const batch = db.batch();
let contador = 0;

for (const doc of snapshot.docs) {
const data = doc.data();
const dni = data.dni;

if (!dni) {
console.log(`Documento sin DNI omitido: ${doc.id}`);
continue;
}

const newEmail = newEmailFromDni(dni);

await updateAuthEmailByUid(doc.id, dni);

batch.set(
doc.ref,
{
email: newEmail,
correo: newEmail,
dominioAuth: NEW_DOMAIN,
actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
},
{ merge: true }
);

contador++;
}

await batch.commit();

console.log(`Colección usuarios actualizada. Total: ${contador}`);
}

async function updateOtherCollectionsIfEmailExists(collectionName) {
console.log(`Revisando colección ${collectionName}...`);

const snapshot = await db.collection(collectionName).get();

if (snapshot.empty) {
console.log(`Colección ${collectionName} vacía o inexistente.`);
return;
}

const batch = db.batch();
let contador = 0;

for (const doc of snapshot.docs) {
const data = doc.data();
const updates = {};

if (
typeof data.email === "string" &&
data.email.endsWith(`@${OLD_DOMAIN}`)
) {
updates.email = data.email.replace(`@${OLD_DOMAIN}`, `@${NEW_DOMAIN}`);
}

if (
typeof data.correo === "string" &&
data.correo.endsWith(`@${OLD_DOMAIN}`)
) {
updates.correo = data.correo.replace(`@${OLD_DOMAIN}`, `@${NEW_DOMAIN}`);
}

if (Object.keys(updates).length > 0) {
updates.actualizadoEn = admin.firestore.FieldValue.serverTimestamp();

batch.set(doc.ref, updates, { merge: true });
contador++;
}
}

if (contador > 0) {
await batch.commit();
}

console.log(`Colección ${collectionName} actualizada. Total: ${contador}`);
}

async function migrate() {
console.log("======================================");
console.log("MIGRACIÓN DE DOMINIO FIREBASE");
console.log(`De: ${OLD_DOMAIN}`);
console.log(`A : ${NEW_DOMAIN}`);
console.log("======================================");

await updateUsuariosCollection();

await updateOtherCollectionsIfEmailExists("estudiantes");
await updateOtherCollectionsIfEmailExists("docentes");
await updateOtherCollectionsIfEmailExists("padres");
await updateOtherCollectionsIfEmailExists("auxiliares");
await updateOtherCollectionsIfEmailExists("directivos");

console.log("");
console.log("Migración finalizada correctamente.");
console.log("");
console.log("Nuevas credenciales de prueba:");
console.log("Auxiliar  -> DNI: 10000001 | Email interno: 10000001@iv.edu.pe");
console.log("Directivo -> DNI: 10000002 | Email interno: 10000002@iv.edu.pe");
console.log("Docente   -> DNI: 10000003 | Email interno: 10000003@iv.edu.pe");
console.log("Padre     -> DNI: 20000001 | Email interno: 20000001@iv.edu.pe");
console.log("Alumno    -> DNI: 70000001 | Email interno: 70000001@iv.edu.pe");

process.exit(0);
}

migrate().catch((error) => {
console.error("Error durante la migración:", error);
process.exit(1);
});