import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:share_plus/share_plus.dart';

import '../models/asistencia.dart';
import '../models/bimestre.dart';
import '../models/estudiante.dart';

import '../services/firestore_service.dart';

class ReporteBimestralPage extends StatefulWidget {
  final String seccionId;

  const ReporteBimestralPage({
    super.key,
    required this.seccionId,
  });

  @override
  State<ReporteBimestralPage> createState() => _ReporteBimestralPageState();
}

class _ReporteBimestralPageState extends State<ReporteBimestralPage> {
  final _service = FirestoreService();
  final _db = FirebaseFirestore.instance;

  String? _bimestreIdSeleccionado;

  List<Bimestre> _bimestres = [];

  bool _localeInicializado = false;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _inicializarLocale();
  }

  Future<void> _inicializarLocale() async {
    await initializeDateFormatting('es_PE', null);

    if (!mounted) return;

    setState(() {
      _localeInicializado = true;
    });
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'A':
        return Colors.green;
      case 'T':
        return Colors.orange;
      case 'TJ':
        return Colors.amber.shade700;
      case 'F':
        return Colors.red;
      case 'FJ':
        return Colors.deepOrange;
      case 'R':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'A':
        return 'Asistió';
      case 'T':
        return 'Tardanza';
      case 'TJ':
        return 'Tardanza justificada';
      case 'F':
        return 'Falta';
      case 'FJ':
        return 'Falta justificada';
      case 'R':
        return 'Retiro';
      default:
        return '';
    }
  }

  List<DateTime> _generarFechas(
      DateTime inicio,
      DateTime fin,
      ) {
    final fechas = <DateTime>[];

    DateTime actual = inicio;

    while (!actual.isAfter(fin)) {
      if (actual.weekday != DateTime.saturday &&
          actual.weekday != DateTime.sunday) {
        fechas.add(actual);
      }

      actual = actual.add(const Duration(days: 1));
    }

    return fechas;
  }

  Bimestre? get _bimestreSeleccionado {
    try {
      return _bimestres.firstWhere(
            (b) => b.id == _bimestreIdSeleccionado,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _cargarDatosReporte() async {
    final estudiantes = await _service.obtenerEstudiantesPorSeccion(
      widget.seccionId,
    );

    estudiantes.sort(
          (a, b) {
        return a.nombreCompleto.toUpperCase().compareTo(
          b.nombreCompleto.toUpperCase(),
        );
      },
    );

    final asistencias = await _service.obtenerAsistenciaPorBimestre(
      seccionId: widget.seccionId,
      bimestre: _bimestreSeleccionado!.numero,
    );

    return {
      'estudiantes': estudiantes,
      'asistencias': asistencias,
    };
  }

  Map<String, Map<String, Asistencia>> _crearMapaAsistencias(
      List<Asistencia> asistencias,
      ) {
    final mapa = <String, Map<String, Asistencia>>{};

    for (final asistencia in asistencias) {
      mapa[asistencia.estudianteId] ??= {};
      mapa[asistencia.estudianteId]![asistencia.fechaKey] = asistencia;
    }

    return mapa;
  }

  String _csvCampo(dynamic valor) {
    final texto = valor?.toString() ?? '';
    final escapado = texto.replaceAll('"', '""');

    return '"$escapado"';
  }

  String _nombreArchivoSeguro(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<String> _obtenerNombreSeccion() async {
    final seccionDoc = await _db
        .collection('secciones')
        .doc(widget.seccionId)
        .get();

    if (!seccionDoc.exists) {
      return 'Sección no encontrada';
    }

    final seccionData = seccionDoc.data() ?? {};
    final gradoId = seccionData['gradoId'];
    final nombreSeccion = seccionData['nombre'] ?? '';

    String gradoNombre = '';

    if (gradoId != null && gradoId.toString().isNotEmpty) {
      final gradoDoc = await _db.collection('grados').doc(gradoId).get();

      if (gradoDoc.exists) {
        final gradoData = gradoDoc.data() ?? {};
        gradoNombre = gradoData['nombre'] ?? '';
      }
    }

    if (gradoNombre.isEmpty) {
      return 'Sección $nombreSeccion';
    }

    return '$gradoNombre - Sección $nombreSeccion';
  }

  Future<void> _exportarAsistencia() async {
    final bimestre = _bimestreSeleccionado;

    if (bimestre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un bimestre para exportar.'),
        ),
      );
      return;
    }

    setState(() {
      _exportando = true;
    });

    try {
      final datos = await _cargarDatosReporte();

      final estudiantes = datos['estudiantes'] as List<Estudiante>;
      final asistencias = datos['asistencias'] as List<Asistencia>;

      final inicio = DateTime.parse(bimestre.fechaInicio);
      final fin = DateTime.parse(bimestre.fechaFin);
      final fechas = _generarFechas(inicio, fin);

      final mapa = _crearMapaAsistencias(asistencias);
      final nombreSeccion = await _obtenerNombreSeccion();

      final buffer = StringBuffer();

      buffer.writeln([_csvCampo('IE. Ignacia Velásquez')].join(','));
      buffer.writeln([_csvCampo('Reporte de asistencia bimestral')].join(','));

      buffer.writeln([
        _csvCampo('Bimestre'),
        _csvCampo(bimestre.nombre),
      ].join(','));

      buffer.writeln([
        _csvCampo('Sección'),
        _csvCampo(nombreSeccion),
      ].join(','));

      buffer.writeln([
        _csvCampo('Fecha de exportación'),
        _csvCampo(
          DateFormat('dd/MM/yyyy HH:mm', 'es_PE').format(DateTime.now()),
        ),
      ].join(','));

      buffer.writeln('');

      final cabecera = <String>[
        'N°',
        'DNI',
        'Apellidos y nombres',
        ...fechas.map(
              (fecha) => DateFormat('dd/MM/yyyy', 'es_PE').format(fecha),
        ),
        'Total A',
        'Total T',
        'Total TJ',
        'Total F',
        'Total FJ',
        'Total R',
      ];

      buffer.writeln(cabecera.map(_csvCampo).join(','));

      for (final entry in estudiantes.asMap().entries) {
        final index = entry.key;
        final estudiante = entry.value;

        int totalA = 0;
        int totalT = 0;
        int totalTJ = 0;
        int totalF = 0;
        int totalFJ = 0;
        int totalR = 0;

        final filaEstados = <String>[];

        for (final fecha in fechas) {
          final key = _service.fechaKey(fecha);
          final asistencia = mapa[estudiante.id]?[key];
          final estado = asistencia?.estado ?? '-';

          switch (estado) {
            case 'A':
              totalA++;
              break;
            case 'T':
              totalT++;
              break;
            case 'TJ':
              totalTJ++;
              break;
            case 'F':
              totalF++;
              break;
            case 'FJ':
              totalFJ++;
              break;
            case 'R':
              totalR++;
              break;
          }

          filaEstados.add(estado);
        }

        final fila = <String>[
          '${index + 1}',
          estudiante.dni,
          estudiante.nombreCompleto,
          ...filaEstados,
          totalA.toString(),
          totalT.toString(),
          totalTJ.toString(),
          totalF.toString(),
          totalFJ.toString(),
          totalR.toString(),
        ];

        buffer.writeln(fila.map(_csvCampo).join(','));
      }

      buffer.writeln('');
      buffer.writeln([_csvCampo('Leyenda')].join(','));
      buffer.writeln([_csvCampo('A'), _csvCampo(_textoEstado('A'))].join(','));
      buffer.writeln([_csvCampo('T'), _csvCampo(_textoEstado('T'))].join(','));
      buffer.writeln([
        _csvCampo('TJ'),
        _csvCampo(_textoEstado('TJ')),
      ].join(','));
      buffer.writeln([_csvCampo('F'), _csvCampo(_textoEstado('F'))].join(','));
      buffer.writeln([
        _csvCampo('FJ'),
        _csvCampo(_textoEstado('FJ')),
      ].join(','));
      buffer.writeln([_csvCampo('R'), _csvCampo(_textoEstado('R'))].join(','));

      final nombreArchivo =
          'asistencia_${_nombreArchivoSeguro(bimestre.nombre)}_${_nombreArchivoSeguro(nombreSeccion)}.csv';

      final archivo = File('${Directory.systemTemp.path}/$nombreArchivo');

      await archivo.writeAsString(
        '\uFEFF${buffer.toString()}',
        flush: true,
      );

      await Share.shareXFiles(
        [XFile(archivo.path)],
        text:
        'Reporte de asistencia - ${bimestre.nombre} - IE. Ignacia Velásquez',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte exportado correctamente.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar reporte: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exportando = false;
        });
      }
    }
  }

  Widget _estadoCelda(String estado) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _estadoColor(estado),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            estado,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _leyenda() {
    final estados = ['A', 'T', 'TJ', 'F', 'FJ', 'R'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: estados.map((estado) {
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: _estadoColor(estado),
            child: Text(
              estado,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          label: Text(_textoEstado(estado)),
        );
      }).toList(),
    );
  }

  Widget _selectorBimestre() {
    return DropdownButtonFormField<String>(
      value: _bimestreIdSeleccionado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Seleccione bimestre',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_month),
      ),
      selectedItemBuilder: (context) {
        return _bimestres.map((bimestre) {
          final inicio = DateFormat(
            'dd/MM/yyyy',
            'es_PE',
          ).format(DateTime.parse(bimestre.fechaInicio));

          final fin = DateFormat(
            'dd/MM/yyyy',
            'es_PE',
          ).format(DateTime.parse(bimestre.fechaFin));

          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${bimestre.nombre} ($inicio - $fin)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      items: _bimestres.map((bimestre) {
        final inicio = DateFormat(
          'dd/MM/yyyy',
          'es_PE',
        ).format(DateTime.parse(bimestre.fechaInicio));

        final fin = DateFormat(
          'dd/MM/yyyy',
          'es_PE',
        ).format(DateTime.parse(bimestre.fechaFin));

        return DropdownMenuItem<String>(
          value: bimestre.id,
          child: Text(
            '${bimestre.nombre} ($inicio - $fin)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _bimestreIdSeleccionado = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInicializado) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte bimestral'),
        actions: [
          IconButton(
            tooltip: 'Exportar asistencia',
            icon: _exportando
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.file_download),
            onPressed: _exportando || _bimestreSeleccionado == null
                ? null
                : _exportarAsistencia,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<List<Bimestre>>(
              stream: _service.streamBimestres(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error al cargar bimestres: ${snapshot.error}',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                _bimestres = snapshot.data ?? [];

                if (_bimestres.isEmpty) {
                  return const Center(
                    child: Text('No hay bimestres registrados'),
                  );
                }

                final existe = _bimestres.any(
                      (b) => b.id == _bimestreIdSeleccionado,
                );

                if (!existe) {
                  _bimestreIdSeleccionado = null;
                }

                return Column(
                  children: [
                    _selectorBimestre(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _exportando
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.file_download),
                        label: Text(
                          _exportando
                              ? 'Exportando...'
                              : 'Exportar asistencia',
                        ),
                        onPressed: _exportando || _bimestreSeleccionado == null
                            ? null
                            : _exportarAsistencia,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _leyenda(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _bimestreSeleccionado == null
                  ? const Center(
                child: Text(
                  'Seleccione un bimestre para visualizar el reporte',
                ),
              )
                  : FutureBuilder<Map<String, dynamic>>(
                future: _cargarDatosReporte(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar reporte: ${snapshot.error}',
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final estudiantes =
                  snapshot.data!['estudiantes'] as List<Estudiante>;

                  final asistencias =
                  snapshot.data!['asistencias'] as List<Asistencia>;

                  final inicio = DateTime.parse(
                    _bimestreSeleccionado!.fechaInicio,
                  );

                  final fin = DateTime.parse(
                    _bimestreSeleccionado!.fechaFin,
                  );

                  final fechas = _generarFechas(inicio, fin);

                  final mapa = _crearMapaAsistencias(asistencias);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 14,
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade200,
                        ),
                        columns: [
                          const DataColumn(
                            label: SizedBox(
                              width: 55,
                              child: Text(
                                'N°',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: SizedBox(
                              width: 260,
                              child: Text(
                                'Apellidos y nombres',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          ...fechas.map(
                                (fecha) {
                              final dia = DateFormat(
                                'dd/MM',
                                'es_PE',
                              ).format(fecha);

                              final nombreDia = DateFormat(
                                'EEE',
                                'es_PE',
                              ).format(fecha);

                              return DataColumn(
                                label: SizedBox(
                                  width: 58,
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dia,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        nombreDia.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        rows: estudiantes.asMap().entries.map(
                              (entry) {
                            final index = entry.key;
                            final estudiante = entry.value;

                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 55,
                                    child: Center(
                                      child: Text('${index + 1}'),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 260,
                                    child: Text(
                                      estudiante.nombreCompleto,
                                    ),
                                  ),
                                ),
                                ...fechas.map(
                                      (fecha) {
                                    final key = _service.fechaKey(fecha);
                                    final asistencia =
                                    mapa[estudiante.id]?[key];
                                    final estado =
                                        asistencia?.estado ?? '-';

                                    return DataCell(
                                      _estadoCelda(estado),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}