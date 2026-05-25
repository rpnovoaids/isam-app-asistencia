class Grado {
  final String id;
  final String nombre;
  final int orden;
  final String nivel;
  final bool activo;

  Grado({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.nivel,
    required this.activo,
  });

  factory Grado.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    return Grado(
      id: id,
      nombre: data['nombre'] ?? '',
      orden: data['orden'] ?? 0,
      nivel: data['nivel'] ?? '',
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'orden': orden,
      'nivel': nivel,
      'activo': activo,
    };
  }
}