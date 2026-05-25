class Bimestre {
  final String id;
  final String nombre;
  final int numero;
  final String fechaInicio;
  final String fechaFin;
  final bool cerrado;

  Bimestre({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.fechaInicio,
    required this.fechaFin,
    required this.cerrado,
  });

  factory Bimestre.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    return Bimestre(
      id: id,
      nombre: data['nombre'] ?? '',
      numero: data['numero'] ?? 1,
      fechaInicio: data['fechaInicio'] ?? '',
      fechaFin: data['fechaFin'] ?? '',
      cerrado: data['cerrado'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'numero': numero,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'cerrado': cerrado,
    };
  }
}