import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class EstudiantesPage extends StatefulWidget {
  const EstudiantesPage({super.key});

  @override
  State<EstudiantesPage> createState() => _EstudiantesPageState();
}

class _EstudiantesPageState extends State<EstudiantesPage> {
  final _db = FirebaseFirestore.instance;
  final _service = FirestoreService();

  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();

  String? _seccionId;
  bool _activo = true;

  final List<Color> _coloresIniciales = const [
    Colors.indigo,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.deepOrange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.cyan,
    Colors.red,
    Colors.deepPurple,
  ];

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  String _inicialNombre(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return '?';
    }

    return texto.trim()[0].toUpperCase();
  }

  Color _colorPorTexto(String texto) {
    if (texto.trim().isEmpty) {
      return Colors.grey;
    }

    final inicial = texto.trim().toUpperCase().codeUnitAt(0);
    final index = inicial % _coloresIniciales.length;

    return _coloresIniciales[index];
  }

  String _nombreCompleto({
    required String apellidos,
    required String nombres,
  }) {
    final apellidosLimpios = apellidos.trim();
    final nombresLimpios = nombres.trim();

    if (apellidosLimpios.isEmpty && nombresLimpios.isEmpty) {
      return '';
    }

    if (apellidosLimpios.isEmpty) {
      return nombresLimpios;
    }

    if (nombresLimpios.isEmpty) {
      return apellidosLimpios;
    }

    return '$apellidosLimpios, $nombresLimpios';
  }

  Future<void> _mostrarDialogo({
    DocumentSnapshot? estudiante,
  }) async {
    _dniController.clear();
    _nombresController.clear();
    _apellidosController.clear();

    _seccionId = null;
    _activo = true;

    if (estudiante != null) {
      final data = estudiante.data() as Map<String, dynamic>;

      _dniController.text = data['dni'] ?? '';
      _nombresController.text = data['nombres'] ?? '';
      _apellidosController.text = data['apellidos'] ?? '';
      _seccionId = data['seccionId'];
      _activo = data['activo'] ?? true;
    }

    await showDialog(
      context: context,
      builder: (_) {
        String? seccionTemporal = _seccionId;
        bool activoTemporal = _activo;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                estudiante == null ? 'Nuevo estudiante' : 'Editar estudiante',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _dniController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'DNI',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nombresController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombres',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _apellidosController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _service.streamSecciones(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              'Error al cargar secciones: ${snapshot.error}',
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final secciones = snapshot.data ?? [];

                          final ids = secciones
                              .map((s) => s['id'].toString())
                              .toSet()
                              .toList();

                          if (seccionTemporal != null &&
                              !ids.contains(seccionTemporal)) {
                            seccionTemporal = null;
                          }

                          return DropdownButtonFormField<String>(
                            value: seccionTemporal,
                            decoration: const InputDecoration(
                              labelText: 'Sección',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.groups),
                            ),
                            items: secciones.map((seccion) {
                              return DropdownMenuItem<String>(
                                value: seccion['id'].toString(),
                                child: Text(
                                  '${seccion['gradoNombre']} - Sección ${seccion['nombre']}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                seccionTemporal = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: activoTemporal,
                        title: const Text('Activo'),
                        subtitle: Text(
                          activoTemporal
                              ? 'El estudiante aparecerá en las listas de asistencia.'
                              : 'El estudiante no aparecerá en asistencia.',
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            activoTemporal = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final dni = _dniController.text.trim();
                    final nombres = _nombresController.text.trim();
                    final apellidos = _apellidosController.text.trim();

                    if (dni.isEmpty || nombres.isEmpty || apellidos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Complete DNI, nombres y apellidos.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (seccionTemporal == null || seccionTemporal!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Seleccione una sección.',
                          ),
                        ),
                      );
                      return;
                    }

                    final nombreCompleto = _nombreCompleto(
                      apellidos: apellidos,
                      nombres: nombres,
                    );

                    final data = {
                      'dni': dni,
                      'nombres': nombres,
                      'apellidos': apellidos,
                      'nombreCompleto': nombreCompleto,
                      'seccionId': seccionTemporal,
                      'activo': activoTemporal,
                      'actualizadoEn': FieldValue.serverTimestamp(),
                    };

                    try {
                      if (estudiante == null) {
                        await _db.collection('estudiantes').add({
                          ...data,
                          'creadoEn': FieldValue.serverTimestamp(),
                        });
                      } else {
                        await _db
                            .collection('estudiantes')
                            .doc(estudiante.id)
                            .update(data);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar estudiante: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    estudiante == null ? 'Guardar' : 'Actualizar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminar(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar estudiante'),
          content: const Text(
            '¿Desea eliminar este estudiante?\n\n'
                'Si solo desea que no aparezca en asistencia, es mejor editarlo y desactivar el estado Activo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await _db.collection('estudiantes').doc(id).delete();
  }

  Future<String> _obtenerTextoSeccion(String? seccionId) async {
    if (seccionId == null || seccionId.isEmpty) {
      return 'Sin sección';
    }

    final seccionDoc = await _db.collection('secciones').doc(seccionId).get();

    if (!seccionDoc.exists) {
      return 'Sección no encontrada';
    }

    final seccionData = seccionDoc.data() ?? {};
    final gradoId = seccionData['gradoId'];

    String gradoNombre = '';

    if (gradoId != null && gradoId.toString().isNotEmpty) {
      final gradoDoc = await _db.collection('grados').doc(gradoId).get();

      if (gradoDoc.exists) {
        final gradoData = gradoDoc.data() ?? {};
        gradoNombre = gradoData['nombre'] ?? '';
      }
    }

    final nombreSeccion = seccionData['nombre'] ?? '';

    if (gradoNombre.isEmpty) {
      return 'Sección $nombreSeccion';
    }

    return '$gradoNombre - Sección $nombreSeccion';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de estudiantes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogo();
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('estudiantes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar estudiantes: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No hay estudiantes registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final estudiante = docs[index];
              final data = estudiante.data() as Map<String, dynamic>;

              final dni = data['dni']?.toString() ?? '';
              final nombres = data['nombres']?.toString() ?? '';
              final apellidos = data['apellidos']?.toString() ?? '';

              final nombreCompleto =
              data['nombreCompleto']?.toString().trim().isNotEmpty == true
                  ? data['nombreCompleto'].toString()
                  : _nombreCompleto(
                apellidos: apellidos,
                nombres: nombres,
              );

              final seccionId = data['seccionId']?.toString();
              final estaActivo = data['activo'] == true;

              final textoParaAvatar =
              apellidos.trim().isNotEmpty ? apellidos : nombres;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorPorTexto(textoParaAvatar),
                    child: Text(
                      _inicialNombre(textoParaAvatar),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    nombreCompleto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: FutureBuilder<String>(
                    future: _obtenerTextoSeccion(seccionId),
                    builder: (context, seccionSnapshot) {
                      final textoSeccion =
                          seccionSnapshot.data ?? 'Cargando sección...';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DNI: $dni'),
                          Text(textoSeccion),
                          Row(
                            children: [
                              Icon(
                                estaActivo
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
                                color: estaActivo
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                estaActivo ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  color: estaActivo
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _mostrarDialogo(estudiante: estudiante);
                        },
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _eliminar(estudiante.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}