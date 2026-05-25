import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/grado.dart';
import '../../services/firestore_service.dart';

class GradosPage extends StatefulWidget {
  const GradosPage({super.key});

  @override
  State<GradosPage> createState() => _GradosPageState();
}

class _GradosPageState extends State<GradosPage> {
  final service = FirestoreService();

  final _nombreController = TextEditingController();

  final _ordenController = TextEditingController();

  Future<void> _mostrarDialogoNuevoGrado() async {
    _nombreController.clear();
    _ordenController.clear();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Nuevo grado'),

          content: SizedBox(
            width: 400,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                TextField(
                  controller: _nombreController,

                  decoration: const InputDecoration(
                    labelText: 'Nombre del grado',
                    hintText: 'Ejemplo: 1° Secundaria',
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _ordenController,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: 'Orden',
                    hintText: 'Ejemplo: 1',
                  ),
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
                if (_nombreController.text.trim().isEmpty) {
                  return;
                }

                await service.guardarGrado(
                  nombre: _nombreController.text.trim(),
                  orden:
                  int.tryParse(
                    _ordenController.text.trim(),
                  ) ??
                      0,
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

  Future<void> _editarGrado(
      Grado grado,
      ) async {
    final nombreController = TextEditingController(
      text: grado.nombre,
    );

    final ordenController = TextEditingController(
      text: grado.orden.toString(),
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar grado'),

          content: SizedBox(
            width: 400,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                TextField(
                  controller: nombreController,

                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: ordenController,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: 'Orden',
                  ),
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
                await FirebaseFirestore.instance
                    .collection('grados')
                    .doc(grado.id)
                    .update({
                  'nombre':
                  nombreController.text.trim(),

                  'orden':
                  int.tryParse(
                    ordenController.text.trim(),
                  ) ??
                      grado.orden,
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

  Future<void> _eliminarGrado(
      Grado grado,
      ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar grado'),

          content: Text(
            '¿Desea eliminar "${grado.nombre}"?\n\n'
                'También se eliminarán sus secciones.',
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

    await service.eliminarGrado(grado.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de grados'),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevoGrado,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<Grado>>(
        stream: service.streamGrados(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final grados = snapshot.data!;

          if (grados.isEmpty) {
            return const Center(
              child: Text('No hay grados registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),

            itemCount: grados.length,

            itemBuilder: (_, index) {
              final grado = grados[index];

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
                      grado.orden.toString(),
                    ),
                  ),

                  title: Text(
                    grado.nombre,

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  subtitle: Text(
                    grado.nivel,
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),

                        onPressed: () {
                          _editarGrado(grado);
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete),

                        onPressed: () {
                          _eliminarGrado(grado);
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