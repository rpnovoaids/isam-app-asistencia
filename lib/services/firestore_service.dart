import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/asistencia.dart';
import '../models/estudiante.dart';
import '../models/bimestre.dart';
import '../models/grado.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String fechaKey(DateTime fecha) {
    return DateFormat('yyyyMMdd').format(fecha);
  }

  String abreviarDia(DateTime fecha) {
    const dias = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];

    return dias[fecha.weekday - 1];
  }

  int calcularBimestre(DateTime fecha) {
    final mes = fecha.month;

    if (mes <= 3) return 1;
    if (mes <= 5) return 2;
    if (mes <= 8) return 3;

    return 4;
  }

  bool esFinDeSemana(DateTime fecha) {
    return fecha.weekday == DateTime.saturday ||
        fecha.weekday == DateTime.sunday;
  }

  List<DateTime> generarFechasBimestre({
    required DateTime inicio,
    required DateTime fin,
    bool excluirFinesSemana = true,
  }) {
    final fechas = <DateTime>[];

    DateTime actual = inicio;

    while (!actual.isAfter(fin)) {
      if (excluirFinesSemana) {
        if (!esFinDeSemana(actual)) {
          fechas.add(actual);
        }
      } else {
        fechas.add(actual);
      }

      actual = actual.add(const Duration(days: 1));
    }

    return fechas;
  }

  Stream<List<Grado>> streamGrados() {
    return _db
        .collection('grados')
        .orderBy('orden')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Grado.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> streamSecciones() {
    return _db.collection('secciones').snapshots().asyncMap(
          (snapshot) async {
        final gradosSnapshot =
        await _db.collection('grados').get();

        final gradosMap = {
          for (var g in gradosSnapshot.docs)
            g.id: g.data()['nombre'] ?? ''
        };

        final secciones = snapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'nombre': data['nombre'] ?? '',
            'gradoId': data['gradoId'] ?? '',
            'gradoNombre':
            gradosMap[data['gradoId']] ?? '',
            'turno': data['turno'] ?? '',
            'activo': data['activo'] ?? true,
          };
        }).toList();

        secciones.sort((a, b) {
          return '${a['gradoNombre']} ${a['nombre']}'
              .compareTo(
            '${b['gradoNombre']} ${b['nombre']}',
          );
        });

        return secciones;
      },
    );
  }

  Stream<List<Bimestre>> streamBimestres() {
    return _db
        .collection('bimestres')
        .orderBy('numero')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bimestre.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> guardarGrado({
    required String nombre,
    required int orden,
  }) async {
    await _db.collection('grados').add({
      'nombre': nombre,
      'orden': orden,
      'nivel': 'Secundaria',
      'activo': true,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> guardarSeccion({
    required String gradoId,
    required String nombre,
    required String turno,
  }) async {
    await _db.collection('secciones').add({
      'gradoId': gradoId,
      'nombre': nombre,
      'turno': turno,
      'activo': true,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> guardarBimestre({
    required String nombre,
    required int numero,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    await _db.collection('bimestres').add({
      'nombre': nombre,
      'numero': numero,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'cerrado': false,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Estudiante>> streamEstudiantesPorSeccion(
      String seccionId,
      ) {
    return _db
        .collection('estudiantes')
        .where('seccionId', isEqualTo: seccionId)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final estudiantes = snapshot.docs
          .map((doc) => Estudiante.fromFirestore(doc))
          .toList();

      estudiantes.sort(
            (a, b) => a.nombreCompleto.compareTo(
          b.nombreCompleto,
        ),
      );

      return estudiantes;
    });
  }

  Stream<List<Asistencia>> streamAsistenciaPorFechaYSeccion({
    required String seccionId,
    required DateTime fecha,
  }) {
    final key = fechaKey(fecha);

    return _db
        .collection('asistencias')
        .where('seccionId', isEqualTo: seccionId)
        .where('fechaKey', isEqualTo: key)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Asistencia.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> guardarAsistenciaMasiva({
    required String seccionId,
    required DateTime fecha,
    required String marcadoPorUid,
    required Map<String, String> estadosPorEstudiante,
    required Map<String, String> justificacionesPorEstudiante,
  }) async {
    if (esFinDeSemana(fecha)) {
      throw Exception(
        'No se puede registrar asistencia en fines de semana',
      );
    }

    final batch = _db.batch();

    final key = fechaKey(fecha);

    final bimestre = calcularBimestre(fecha);

    for (final entry in estadosPorEstudiante.entries) {
      final estudianteId = entry.key;

      final estado = entry.value;

      final justificacion =
          justificacionesPorEstudiante[estudianteId]
              ?.trim() ??
              '';

      final docId = '${key}_$estudianteId';

      final docRef =
      _db.collection('asistencias').doc(docId);

      batch.set(
        docRef,
        {
          'fechaKey': key,
          'fecha': Timestamp.fromDate(
            DateTime(
              fecha.year,
              fecha.month,
              fecha.day,
              7,
              0,
            ),
          ),
          'horaIngresoReferencia': '07:00',
          'bimestre': bimestre,
          'estudianteId': estudianteId,
          'seccionId': seccionId,
          'estado': estado,
          'justificacion': justificacion,
          'marcadoPorUid': marcadoPorUid,
          'actualizadoEn':
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<List<Estudiante>> obtenerEstudiantesPorSeccion(
      String seccionId,
      ) async {
    final snapshot = await _db
        .collection('estudiantes')
        .where('seccionId', isEqualTo: seccionId)
        .where('activo', isEqualTo: true)
        .get();

    final estudiantes = snapshot.docs
        .map((doc) => Estudiante.fromFirestore(doc))
        .toList();

    estudiantes.sort(
          (a, b) => a.nombreCompleto.compareTo(
        b.nombreCompleto,
      ),
    );

    return estudiantes;
  }

  Future<List<Asistencia>> obtenerAsistenciaPorBimestre({
    required String seccionId,
    required int bimestre,
  }) async {
    final snapshot = await _db
        .collection('asistencias')
        .where('seccionId', isEqualTo: seccionId)
        .where('bimestre', isEqualTo: bimestre)
        .get();

    return snapshot.docs
        .map((doc) => Asistencia.fromFirestore(doc))
        .toList();
  }

  Future<Map<String, Map<String, Asistencia>>>
  obtenerMapaAsistenciaBimestral({
    required String seccionId,
    required int bimestre,
  }) async {
    final asistencias =
    await obtenerAsistenciaPorBimestre(
      seccionId: seccionId,
      bimestre: bimestre,
    );

    final mapa =
    <String, Map<String, Asistencia>>{};

    for (final asistencia in asistencias) {
      mapa[asistencia.estudianteId] ??= {};

      mapa[asistencia.estudianteId]! [
      asistencia.fechaKey] = asistencia;
    }

    return mapa;
  }

  Future<void> actualizarEstadoBimestre({
    required String bimestreId,
    required bool cerrado,
  }) async {
    await _db
        .collection('bimestres')
        .doc(bimestreId)
        .update({
      'cerrado': cerrado,
      'actualizadoEn':
      FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarGrado(
      String gradoId,
      ) async {
    final batch = _db.batch();

    /// eliminar secciones del grado
    final seccionesSnapshot = await _db
        .collection('secciones')
        .where('gradoId', isEqualTo: gradoId)
        .get();

    for (final doc in seccionesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    /// eliminar grado
    batch.delete(
      _db.collection('grados').doc(gradoId),
    );

    await batch.commit();
  }

  Future<void> eliminarSeccion(
      String seccionId,
      ) async {
    await _db
        .collection('secciones')
        .doc(seccionId)
        .delete();
  }

  Future<void> actualizarBimestre({
    required String bimestreId,
    required String nombre,
    required int numero,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    await _db
        .collection('bimestres')
        .doc(bimestreId)
        .update({
      'nombre': nombre,
      'numero': numero,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'actualizadoEn':
      FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarBimestre(
      String bimestreId,
      ) async {
    await _db
        .collection('bimestres')
        .doc(bimestreId)
        .delete();
  }
}
