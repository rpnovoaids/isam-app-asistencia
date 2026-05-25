import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String dni;
  final String nombres;
  final String rol;
  final String? estudianteId;
  final List<String> seccionesIds;
  final bool activo;

  AppUser({
    required this.uid,
    required this.dni,
    required this.nombres,
    required this.rol,
    this.estudianteId,
    required this.seccionesIds,
    required this.activo,
  });

  factory AppUser.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return AppUser(
      uid: doc.id,
      dni: data['dni'] ?? '',
      nombres: data['nombres'] ?? '',
      rol: data['rol'] ?? '',
      estudianteId: data['estudianteId'],
      seccionesIds: List<String>.from(data['seccionesIds'] ?? []),
      activo: data['activo'] ?? true,
    );
  }

  bool get esAuxiliar => rol == 'auxiliar';

  bool get esDocente => rol == 'docente';

  bool get esDirectivo => rol == 'directivo';

  bool get esPadre => rol == 'padre';

  bool get esEstudiante => rol == 'estudiante';

  bool get esAdministrador => rol == 'directivo';

  bool get puedeMarcarAsistencia {
    return esAuxiliar || esDocente || esDirectivo;
  }

  bool get puedeVerReportes {
    return esAuxiliar || esDocente || esDirectivo;
  }
}