const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function crearGrados() {
    const grados = [
        { id: "1_sec", nombre: "1° Secundaria", orden: 1 },
        { id: "2_sec", nombre: "2° Secundaria", orden: 2 },
        { id: "3_sec", nombre: "3° Secundaria", orden: 3 },
        { id: "4_sec", nombre: "4° Secundaria", orden: 4 },
        { id: "5_sec", nombre: "5° Secundaria", orden: 5 },
    ];

    const batch = db.batch();

    for (const grado of grados) {
        const ref = db.collection("grados").doc(grado.id);

        batch.set(ref, {
            nombre: grado.nombre,
            nivel: "Secundaria",
            orden: grado.orden,
            activo: true,
            creadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    await batch.commit();

    console.log("Grados creados.");
}

async function crearSecciones() {
    const letras = ["A", "B", "C"];

    const batch = db.batch();

    for (let grado = 1; grado <= 5; grado++) {
        for (const letra of letras) {
            const id = `${grado}_sec_${letra}`;

            batch.set(db.collection("secciones").doc(id), {
                gradoId: `${grado}_sec`,
                nombre: letra,
                turno: "Mañana",
                activo: true,
                creadoEn: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }

    await batch.commit();

    console.log("Secciones creadas.");
}

async function crearBimestres() {
    const anio = 2026;

    const bimestres = [
        {
            id: "bim1",
            nombre: "I Bimestre",
            numero: 1,
            fechaInicio: `${anio}-03-01`,
            fechaFin: `${anio}-05-15`,
        },
        {
            id: "bim2",
            nombre: "II Bimestre",
            numero: 2,
            fechaInicio: `${anio}-05-16`,
            fechaFin: `${anio}-07-30`,
        },
        {
            id: "bim3",
            nombre: "III Bimestre",
            numero: 3,
            fechaInicio: `${anio}-08-01`,
            fechaFin: `${anio}-10-10`,
        },
        {
            id: "bim4",
            nombre: "IV Bimestre",
            numero: 4,
            fechaInicio: `${anio}-10-11`,
            fechaFin: `${anio}-12-20`,
        },
    ];

    const batch = db.batch();

    for (const item of bimestres) {
        batch.set(db.collection("bimestres").doc(item.id), {
            ...item,
            cerrado: false,
            creadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    await batch.commit();

    console.log("Bimestres creados.");
}

async function migrarEstudiantes() {
    const snapshot = await db.collection("estudiantes").get();

    if (snapshot.empty) {
        console.log("No hay estudiantes.");
        return;
    }

    const batch = db.batch();

    for (const doc of snapshot.docs) {
        batch.set(
            doc.ref,
            {
                activo: true,
                actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );
    }

    await batch.commit();

    console.log("Estudiantes migrados.");
}

async function main() {
    console.log("==================================");
    console.log("CONFIGURANDO ESTRUCTURA ESCOLAR");
    console.log("==================================");

    await crearGrados();
    await crearSecciones();
    await crearBimestres();
    await migrarEstudiantes();

    console.log("Proceso finalizado.");
    process.exit(0);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});