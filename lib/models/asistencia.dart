import 'package:cloud_firestore/cloud_firestore.dart';

class Asistencia {
  final String id;
  final String fechaKey;
  final DateTime fecha;
  final int bimestre;
  final String estudianteId;
  final String seccionId;
  final String estado;
  final String justificacion;
  final String marcadoPorUid;
  final DateTime? actualizadoEn;

  Asistencia({
    required this.id,
    required this.fechaKey,
    required this.fecha,
    required this.bimestre,
    required this.estudianteId,
    required this.seccionId,
    required this.estado,
    required this.justificacion,
    required this.marcadoPorUid,
    this.actualizadoEn,
  });

  factory Asistencia.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return Asistencia(
      id: doc.id,
      fechaKey: data['fechaKey'] ?? '',
      fecha: data['fecha'] is Timestamp
          ? (data['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      bimestre: data['bimestre'] ?? 1,
      estudianteId: data['estudianteId'] ?? '',
      seccionId: data['seccionId'] ?? '',
      estado: data['estado'] ?? 'A',
      justificacion: data['justificacion'] ?? '',
      marcadoPorUid: data['marcadoPorUid'] ?? '',
      actualizadoEn: data['actualizadoEn'] is Timestamp
          ? (data['actualizadoEn'] as Timestamp).toDate()
          : null,
    );
  }
}
