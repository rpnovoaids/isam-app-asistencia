const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

function dniToEmail(dni) {
    return `${dni}@colegio.local`;
}

async function crearUsuarioAuthYFirestore({
                                              dni,
                                              password,
                                              nombres,
                                              rol,
                                              estudianteId = null,
                                              seccionesIds = [],
                                          }) {
    const email = dniToEmail(dni);
    let userRecord;

    try {
        userRecord = await auth.getUserByEmail(email);
        console.log(`Usuario Auth ya existe: ${email}`);
    } catch (error) {
        userRecord = await auth.createUser({
            email,
            password,
            displayName: nombres,
            emailVerified: true,
            disabled: false,
        });

        console.log(`Usuario Auth creado: ${email}`);
    }

    await db.collection("usuarios").doc(userRecord.uid).set(
        {
            dni,
            nombres,
            rol,
            estudianteId,
            seccionesIds,
            creadoEn: admin.firestore.FieldValue.serverTimestamp(),
            actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
    );

    console.log(`Documento usuario creado/actualizado: ${nombres}`);

    return userRecord.uid;
}

async function seed() {
    console.log("Iniciando creación de colecciones y documentos...");

    // =========================
    // GRADOS
    // =========================

    const grados = [
        {
            id: "grado_1",
            nombre: "1° Secundaria",
            nivel: "Secundaria",
            orden: 1,
        },
        {
            id: "grado_2",
            nombre: "2° Secundaria",
            nivel: "Secundaria",
            orden: 2,
        },
        {
            id: "grado_3",
            nombre: "3° Secundaria",
            nivel: "Secundaria",
            orden: 3,
        },
    ];

    for (const grado of grados) {
        await db.collection("grados").doc(grado.id).set(grado, { merge: true });
        console.log(`Grado creado: ${grado.nombre}`);
    }

    // =========================
    // SECCIONES
    // =========================

    const secciones = [
        {
            id: "sec_1a",
            gradoId: "grado_1",
            nombre: "A",
            turno: "Mañana",
            horaIngreso: "07:00",
        },
        {
            id: "sec_1b",
            gradoId: "grado_1",
            nombre: "B",
            turno: "Mañana",
            horaIngreso: "07:00",
        },
        {
            id: "sec_2a",
            gradoId: "grado_2",
            nombre: "A",
            turno: "Mañana",
            horaIngreso: "07:00",
        },
        {
            id: "sec_3a",
            gradoId: "grado_3",
            nombre: "A",
            turno: "Mañana",
            horaIngreso: "07:00",
        },
    ];

    for (const seccion of secciones) {
        await db
            .collection("secciones")
            .doc(seccion.id)
            .set(seccion, { merge: true });

        console.log(`Sección creada: ${seccion.id}`);
    }

    // =========================
    // USUARIOS CON ROLES
    // =========================

    const auxiliarUid = await crearUsuarioAuthYFirestore({
        dni: "10000001",
        password: "123456",
        nombres: "Auxiliar Principal",
        rol: "auxiliar",
        seccionesIds: ["sec_1a", "sec_1b", "sec_2a", "sec_3a"],
    });

    const directivoUid = await crearUsuarioAuthYFirestore({
        dni: "10000002",
        password: "123456",
        nombres: "Director Académico",
        rol: "directivo",
        seccionesIds: [],
    });

    const docenteUid = await crearUsuarioAuthYFirestore({
        dni: "10000003",
        password: "123456",
        nombres: "Docente Tutor 1A",
        rol: "docente",
        seccionesIds: ["sec_1a"],
    });

    const padreUid = await crearUsuarioAuthYFirestore({
        dni: "20000001",
        password: "123456",
        nombres: "Padre de Familia",
        rol: "padre",
        estudianteId: "est_001",
        seccionesIds: [],
    });

    await crearUsuarioAuthYFirestore({
        dni: "70000001",
        password: "123456",
        nombres: "Luis Ramírez Soto",
        rol: "estudiante",
        estudianteId: "est_001",
        seccionesIds: [],
    });

    // =========================
    // ESTUDIANTES
    // =========================

    const estudiantes = [
        {
            id: "est_001",
            dni: "70000001",
            nombres: "Luis",
            apellidos: "Ramírez Soto",
            gradoId: "grado_1",
            seccionId: "sec_1a",
            padreUid: padreUid,
            estado: "activo",
        },
        {
            id: "est_002",
            dni: "70000002",
            nombres: "María",
            apellidos: "Gómez Rojas",
            gradoId: "grado_1",
            seccionId: "sec_1a",
            padreUid: null,
            estado: "activo",
        },
        {
            id: "est_003",
            dni: "70000003",
            nombres: "Carlos",
            apellidos: "Pérez Quispe",
            gradoId: "grado_1",
            seccionId: "sec_1a",
            padreUid: null,
            estado: "activo",
        },
        {
            id: "est_004",
            dni: "70000004",
            nombres: "Ana",
            apellidos: "Torres Huamán",
            gradoId: "grado_1",
            seccionId: "sec_1a",
            padreUid: null,
            estado: "activo",
        },
        {
            id: "est_005",
            dni: "70000005",
            nombres: "José",
            apellidos: "Flores Díaz",
            gradoId: "grado_1",
            seccionId: "sec_1b",
            padreUid: null,
            estado: "activo",
        },
        {
            id: "est_006",
            dni: "70000006",
            nombres: "Valeria",
            apellidos: "Mendoza Salas",
            gradoId: "grado_2",
            seccionId: "sec_2a",
            padreUid: null,
            estado: "activo",
        },
        {
            id: "est_007",
            dni: "70000007",
            nombres: "Diego",
            apellidos: "Castillo León",
            gradoId: "grado_3",
            seccionId: "sec_3a",
            padreUid: null,
            estado: "activo",
        },
    ];

    const estudiantesBatch = db.batch();

    for (const estudiante of estudiantes) {
        const ref = db.collection("estudiantes").doc(estudiante.id);

        estudiantesBatch.set(
            ref,
            {
                ...estudiante,
                creadoEn: admin.firestore.FieldValue.serverTimestamp(),
                actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );
    }

    await estudiantesBatch.commit();
    console.log("Estudiantes creados correctamente.");

    // =========================
    // CATÁLOGO DE ESTADOS
    // Opcional, pero útil para documentar los estados
    // =========================

    const estadosAsistencia = [
        {
            id: "A",
            codigo: "A",
            nombre: "Asistió puntual",
            requiereJustificacion: false,
            orden: 1,
        },
        {
            id: "T",
            codigo: "T",
            nombre: "Tardanza",
            requiereJustificacion: false,
            orden: 2,
        },
        {
            id: "TJ",
            codigo: "TJ",
            nombre: "Tardanza justificada",
            requiereJustificacion: true,
            orden: 3,
        },
        {
            id: "F",
            codigo: "F",
            nombre: "Falta",
            requiereJustificacion: false,
            orden: 4,
        },
        {
            id: "FJ",
            codigo: "FJ",
            nombre: "Falta justificada",
            requiereJustificacion: true,
            orden: 5,
        },
        {
            id: "R",
            codigo: "R",
            nombre: "Retiro autorizado",
            requiereJustificacion: true,
            orden: 6,
        },
    ];

    for (const estado of estadosAsistencia) {
        await db
            .collection("estados_asistencia")
            .doc(estado.id)
            .set(estado, { merge: true });

        console.log(`Estado creado: ${estado.codigo}`);
    }

    console.log("");
    console.log("========================================");
    console.log("DATOS BASE CREADOS CORRECTAMENTE");
    console.log("========================================");
    console.log("");
    console.log("Credenciales de prueba:");
    console.log("Auxiliar  -> DNI: 10000001 | Contraseña: 123456");
    console.log("Directivo -> DNI: 10000002 | Contraseña: 123456");
    console.log("Docente   -> DNI: 10000003 | Contraseña: 123456");
    console.log("Padre     -> DNI: 20000001 | Contraseña: 123456");
    console.log("Alumno    -> DNI: 70000001 | Contraseña: 123456");
    console.log("");
    console.log("UID Auxiliar:", auxiliarUid);
    console.log("UID Directivo:", directivoUid);
    console.log("UID Docente:", docenteUid);

    process.exit(0);
}

seed().catch((error) => {
    console.error("Error ejecutando seed:", error);
    process.exit(1);
});