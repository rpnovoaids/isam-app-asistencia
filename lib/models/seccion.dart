import 'package:cloud_firestore/cloud_firestore.dart';

class Seccion {
  final String id;
  final String gradoId;
  final String nombre;
  final String turno;
  final bool activo;

  Seccion({
    required this.id,
    required this.gradoId,
    required this.nombre,
    required this.turno,
    required this.activo,
  });

  factory Seccion.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return Seccion(
      id: doc.id,
      gradoId: data['gradoId'] ?? '',
      nombre: data['nombre'] ?? '',
      turno: data['turno'] ?? '',
      activo: data['activo'] ?? true,
    );
  }
}