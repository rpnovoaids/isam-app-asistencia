import 'package:cloud_firestore/cloud_firestore.dart';

class Estudiante {
  final String id;
  final String dni;
  final String nombres;
  final String apellidos;
  final String gradoId;
  final String seccionId;
  final String? padreUid;

  Estudiante({
    required this.id,
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.gradoId,
    required this.seccionId,
    this.padreUid,
  });

  factory Estudiante.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return Estudiante(
      id: doc.id,
      dni: data['dni'] ?? '',
      nombres: data['nombres'] ?? '',
      apellidos: data['apellidos'] ?? '',
      gradoId: data['gradoId'] ?? '',
      seccionId: data['seccionId'] ?? '',
      padreUid: data['padreUid'],
    );
  }

  String get nombreCompleto => '$apellidos, $nombres';
}