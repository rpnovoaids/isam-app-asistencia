import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../models/bimestre.dart';
import '../../services/firestore_service.dart';

class BimestresPage extends StatefulWidget {
  const BimestresPage({super.key});

  @override
  State<BimestresPage> createState() =>
      _BimestresPageState();
}

class _BimestresPageState
    extends State<BimestresPage> {
  final _service = FirestoreService();

  final _nombreController =
  TextEditingController();

  final _numeroController =
  TextEditingController();

  DateTime? _fechaInicio;

  DateTime? _fechaFin;

  bool _localeInicializado = false;

  @override
  void initState() {
    super.initState();
    _inicializarLocale();
  }

  Future<void> _inicializarLocale() async {
    await initializeDateFormatting(
      'es_PE',
      null,
    );

    setState(() {
      _localeInicializado = true;
    });
  }

  String _formatearFecha(
      DateTime fecha,
      ) {
    return DateFormat(
      'dd/MM/yyyy',
      'es_PE',
    ).format(fecha);
  }

  Future<void> _seleccionarFechaInicio()
  async {
    final fecha =
    await showDatePicker(
      context: context,
      initialDate:
      _fechaInicio ??
          DateTime.now(),
      firstDate:
      DateTime(2020),
      lastDate:
      DateTime(2100),
      locale: const Locale(
        'es',
        'PE',
      ),
    );

    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
    }
  }

  Future<void> _seleccionarFechaFin()
  async {
    final fecha =
    await showDatePicker(
      context: context,
      initialDate:
      _fechaFin ??
          DateTime.now(),
      firstDate:
      DateTime(2020),
      lastDate:
      DateTime(2100),
      locale: const Locale(
        'es',
        'PE',
      ),
    );

    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
    }
  }

  Future<void> _mostrarDialogo({
    Bimestre? bimestre,
  }) async {
    _nombreController.clear();
    _numeroController.clear();

    _fechaInicio = null;
    _fechaFin = null;

    if (bimestre != null) {
      _nombreController.text =
          bimestre.nombre;

      _numeroController.text =
          bimestre.numero.toString();

      _fechaInicio =
          DateTime.parse(
            bimestre.fechaInicio,
          );

      _fechaFin =
          DateTime.parse(
            bimestre.fechaFin,
          );
    }

    await showDialog(
      context: context,

      builder: (_) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            return AlertDialog(
              title: Text(
                bimestre == null
                    ? 'Nuevo bimestre'
                    : 'Editar bimestre',
              ),

              content: SizedBox(
                width: 420,

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [
                    TextField(
                      controller:
                      _nombreController,

                      decoration:
                      const InputDecoration(
                        labelText:
                        'Nombre',
                        border:
                        OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                      _numeroController,

                      keyboardType:
                      TextInputType
                          .number,

                      decoration:
                      const InputDecoration(
                        labelText:
                        'Número',
                        border:
                        OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    InkWell(
                      onTap: () async {
                        await _seleccionarFechaInicio();

                        setModalState(
                              () {},
                        );
                      },

                      child: InputDecorator(
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Fecha inicio',
                          border:
                          OutlineInputBorder(),
                        ),

                        child: Text(
                          _fechaInicio ==
                              null
                              ? 'Seleccione fecha'
                              : _formatearFecha(
                            _fechaInicio!,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    InkWell(
                      onTap: () async {
                        await _seleccionarFechaFin();

                        setModalState(
                              () {},
                        );
                      },

                      child: InputDecorator(
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Fecha cierre',
                          border:
                          OutlineInputBorder(),
                        ),

                        child: Text(
                          _fechaFin ==
                              null
                              ? 'Seleccione fecha'
                              : _formatearFecha(
                            _fechaFin!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    'Cancelar',
                  ),
                ),

                FilledButton(
                  onPressed: () async {
                    if (_nombreController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    if (_numeroController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    if (_fechaInicio ==
                        null ||
                        _fechaFin ==
                            null) {
                      return;
                    }

                    if (bimestre ==
                        null) {
                      await _service
                          .guardarBimestre(
                        nombre:
                        _nombreController
                            .text
                            .trim(),

                        numero: int.parse(
                          _numeroController
                              .text
                              .trim(),
                        ),

                        fechaInicio:
                        _fechaInicio!
                            .toIso8601String(),

                        fechaFin:
                        _fechaFin!
                            .toIso8601String(),
                      );
                    } else {
                      await _service
                          .actualizarBimestre(
                        bimestreId:
                        bimestre.id,

                        nombre:
                        _nombreController
                            .text
                            .trim(),

                        numero: int.parse(
                          _numeroController
                              .text
                              .trim(),
                        ),

                        fechaInicio:
                        _fechaInicio!
                            .toIso8601String(),

                        fechaFin:
                        _fechaFin!
                            .toIso8601String(),
                      );
                    }

                    if (mounted) {
                      Navigator.pop(
                        context,
                      );
                    }
                  },

                  child: Text(
                    bimestre == null
                        ? 'Guardar'
                        : 'Actualizar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminar(
      Bimestre bimestre,
      ) async {
    final confirmar =
    await showDialog<bool>(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Eliminar bimestre',
          ),

          content: Text(
            '¿Desea eliminar ${bimestre.nombre}?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await _service.eliminarBimestre(
      bimestre.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInicializado) {
      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de bimestres',
        ),
      ),

      floatingActionButton:
      FloatingActionButton(
        onPressed: () {
          _mostrarDialogo();
        },

        child: const Icon(
          Icons.add,
        ),
      ),

      body: StreamBuilder<
          List<Bimestre>>(
        stream:
        _service.streamBimestres(),

        builder:
            (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final bimestres =
              snapshot.data ?? [];

          if (bimestres.isEmpty) {
            return const Center(
              child: Text(
                'No hay bimestres registrados',
              ),
            );
          }

          return ListView.builder(
            padding:
            const EdgeInsets.all(
              12,
            ),

            itemCount:
            bimestres.length,

            itemBuilder:
                (context, index) {
              final bimestre =
              bimestres[index];

              final inicio =
              _formatearFecha(
                DateTime.parse(
                  bimestre
                      .fechaInicio,
                ),
              );

              final fin =
              _formatearFecha(
                DateTime.parse(
                  bimestre
                      .fechaFin,
                ),
              );

              return Card(
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),

                child: ListTile(
                  leading:
                  CircleAvatar(
                    child: Text(
                      bimestre.numero
                          .toString(),
                    ),
                  ),

                  title: Text(
                    bimestre.nombre,
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [
                      Text(
                        'Inicio: $inicio',
                      ),

                      Text(
                        'Cierre: $fin',
                      ),

                      Text(
                        bimestre.cerrado
                            ? 'Estado: Cerrado'
                            : 'Estado: Abierto',
                      ),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      IconButton(
                        icon:
                        const Icon(
                          Icons.edit,
                        ),

                        onPressed: () {
                          _mostrarDialogo(
                            bimestre:
                            bimestre,
                          );
                        },
                      ),

                      IconButton(
                        icon:
                        const Icon(
                          Icons.delete,
                        ),

                        onPressed: () {
                          _eliminar(
                            bimestre,
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