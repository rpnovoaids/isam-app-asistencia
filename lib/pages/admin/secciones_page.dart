import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class SeccionesPage extends StatefulWidget {
  const SeccionesPage({super.key});

  @override
  State<SeccionesPage> createState() =>
      _SeccionesPageState();
}

class _SeccionesPageState
    extends State<SeccionesPage> {
  final _service = FirestoreService();

  final _nombreController =
  TextEditingController();

  String? _gradoIdSeleccionado;

  final List<String> turnos = [
    'Mañana',
    'Tarde',
  ];

  String turnoSeleccionado = 'Mañana';

  Future<void> _mostrarDialogoNuevaSeccion() async {
    _nombreController.clear();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Nueva sección'),

          content: SizedBox(
            width: 400,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                StreamBuilder(
                  stream: _service.streamGrados(),

                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final grados = snapshot.data!;

                    if (_gradoIdSeleccionado ==
                        null &&
                        grados.isNotEmpty) {
                      _gradoIdSeleccionado =
                          grados.first.id;
                    }

                    return DropdownButtonFormField<
                        String>(
                      value:
                      _gradoIdSeleccionado,

                      decoration:
                      const InputDecoration(
                        labelText: 'Grado',
                      ),

                      items: grados.map((grado) {
                        return DropdownMenuItem(
                          value: grado.id,
                          child:
                          Text(grado.nombre),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          _gradoIdSeleccionado =
                              value;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _nombreController,

                  decoration: const InputDecoration(
                    labelText: 'Sección',
                    hintText: 'Ejemplo: A',
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: turnoSeleccionado,

                  decoration: const InputDecoration(
                    labelText: 'Turno',
                  ),

                  items: turnos.map((turno) {
                    return DropdownMenuItem(
                      value: turno,
                      child: Text(turno),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      turnoSeleccionado =
                          value;
                    });
                  },
                ),
              ],
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
                if (_gradoIdSeleccionado ==
                    null) {
                  return;
                }

                await _service.guardarSeccion(
                  gradoId:
                  _gradoIdSeleccionado!,
                  nombre:
                  _nombreController.text
                      .trim(),
                  turno: turnoSeleccionado,
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarSeccion(
      Map<String, dynamic> seccion,
      ) async {
    final controller =
    TextEditingController(
      text: seccion['nombre'],
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar sección'),

          content: TextField(
            controller: controller,

            decoration: const InputDecoration(
              labelText: 'Nombre',
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
                await FirebaseFirestore.instance
                    .collection('secciones')
                    .doc(seccion['id'])
                    .update({
                  'nombre':
                  controller.text.trim(),
                });

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarSeccion(
      String seccionId,
      ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar sección'),

          content: const Text(
            '¿Desea eliminar esta sección?',
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

    await _service.eliminarSeccion(
      seccionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Gestión de secciones'),
      ),

      floatingActionButton:
      FloatingActionButton(
        onPressed:
        _mostrarDialogoNuevaSeccion,
        child: const Icon(Icons.add),
      ),

      body:
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.streamSecciones(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final secciones =
              snapshot.data ?? [];

          if (secciones.isEmpty) {
            return const Center(
              child: Text(
                'No hay secciones registradas',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),

            itemCount: secciones.length,

            itemBuilder: (_, index) {
              final seccion =
              secciones[index];

              return Card(
                elevation: 2,

                margin: const EdgeInsets.only(
                  bottom: 12,
                ),

                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  leading: CircleAvatar(
                    child: Text(
                      seccion['nombre'],
                    ),
                  ),

                  title: Text(
                    '${seccion['gradoNombre']} "${seccion['nombre']}"',

                    style: const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    'Turno: ${seccion['turno']}',
                  ),

                  trailing: Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      IconButton(
                        icon:
                        const Icon(Icons.edit),

                        onPressed: () {
                          _editarSeccion(
                            seccion,
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                        ),

                        onPressed: () {
                          _eliminarSeccion(
                            seccion['id'],
                          );
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