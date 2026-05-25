import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/estudiante.dart';
import '../models/asistencia.dart';
import '../services/firestore_service.dart';

class AsistenciaRapidaPage extends StatefulWidget {
  final String seccionId;
  final AppUser usuario;

  const AsistenciaRapidaPage({
    super.key,
    required this.seccionId,
    required this.usuario,
  });

  @override
  State<AsistenciaRapidaPage> createState() => _AsistenciaRapidaPageState();
}

class _AsistenciaRapidaPageState extends State<AsistenciaRapidaPage> {
  final _firestoreService = FirestoreService();
  final _busquedaController = TextEditingController();

  DateTime _fecha = DateTime.now();
  String _filtro = '';
  bool _guardando = false;

  String? _ultimaCargaKey;
  String? _ultimaFirmaAsistencias;

  bool _hayRegistroPrevio = false;

  final Map<String, String> _estados = {};
  final Map<String, String> _justificaciones = {};

  final List<String> _opcionesEstado = [
    'A',
    'T',
    'TJ',
    'F',
    'FJ',
    'R',
  ];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String _fechaTexto(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  String _claveCarga() {
    final fechaKey = _firestoreService.fechaKey(_fecha);
    return '${widget.seccionId}_$fechaKey';
  }

  String _firmaAsistencias(List<Asistencia> asistencias) {
    final partes = asistencias.map((asistencia) {
      return '${asistencia.estudianteId}|${asistencia.estado}|${asistencia.justificacion}';
    }).toList();

    partes.sort();

    return partes.join('¬');
  }

  List<Estudiante> _filtrarEstudiantes(List<Estudiante> estudiantes) {
    if (_filtro.trim().isEmpty) {
      return estudiantes;
    }

    final filtro = _filtro.toLowerCase().trim();

    return estudiantes.where((estudiante) {
      return estudiante.nombreCompleto.toLowerCase().contains(filtro) ||
          estudiante.dni.contains(filtro);
    }).toList();
  }

  void _cargarAsistenciasExistentes({
    required List<Estudiante> estudiantes,
    required List<Asistencia> asistencias,
  }) {
    final claveActual = _claveCarga();
    final firmaActual = _firmaAsistencias(asistencias);

    if (_ultimaCargaKey == claveActual &&
        _ultimaFirmaAsistencias == firmaActual) {
      return;
    }

    final asistenciasMap = {
      for (final asistencia in asistencias) asistencia.estudianteId: asistencia,
    };

    _estados.clear();
    _justificaciones.clear();

    for (final estudiante in estudiantes) {
      final asistencia = asistenciasMap[estudiante.id];

      _estados[estudiante.id] = asistencia?.estado ?? 'A';
      _justificaciones[estudiante.id] = asistencia?.justificacion ?? '';
    }

    _hayRegistroPrevio = asistencias.isNotEmpty;
    _ultimaCargaKey = claveActual;
    _ultimaFirmaAsistencias = firmaActual;
  }

  void _resetearCargaDeFecha() {
    _ultimaCargaKey = null;
    _ultimaFirmaAsistencias = null;
    _hayRegistroPrevio = false;
    _estados.clear();
    _justificaciones.clear();
  }

  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
      locale: const Locale('es', 'PE'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fecha = fechaSeleccionada;
        _resetearCargaDeFecha();
      });
    }
  }

  bool _requiereJustificacion(String estado) {
    return estado == 'TJ' || estado == 'FJ' || estado == 'R';
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
        return estado;
    }
  }

  Color _colorEstado(String estado) {
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

  Future<void> _editarJustificacion(Estudiante estudiante) async {
    final controller = TextEditingController(
      text: _justificaciones[estudiante.id] ?? '',
    );

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Justificación: ${estudiante.nombres}'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Motivo o justificación',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_alt),
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
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (resultado != null) {
      setState(() {
        _justificaciones[estudiante.id] = resultado.trim();
      });
    }
  }

  Future<void> _guardarAsistencia(List<Estudiante> estudiantes) async {
    for (final estudiante in estudiantes) {
      final estado = _estados[estudiante.id] ?? 'A';
      final justificacion = _justificaciones[estudiante.id] ?? '';

      if (_requiereJustificacion(estado) && justificacion.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falta justificación para ${estudiante.nombreCompleto}',
            ),
          ),
        );
        return;
      }
    }

    final estabaRegistrada = _hayRegistroPrevio;

    setState(() {
      _guardando = true;
    });

    try {
      final estadosPorEstudiante = {
        for (final estudiante in estudiantes)
          estudiante.id: _estados[estudiante.id] ?? 'A',
      };

      await _firestoreService.guardarAsistenciaMasiva(
        seccionId: widget.seccionId,
        fecha: _fecha,
        marcadoPorUid: widget.usuario.uid,
        estadosPorEstudiante: estadosPorEstudiante,
        justificacionesPorEstudiante: _justificaciones,
      );

      if (!mounted) return;

      setState(() {
        _hayRegistroPrevio = true;
        _ultimaFirmaAsistencias = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estabaRegistrada
                ? 'Asistencia actualizada correctamente'
                : 'Asistencia guardada correctamente',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar asistencia: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _resumenRegistro() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hayRegistroPrevio
            ? Colors.blue.withOpacity(0.10)
            : Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hayRegistroPrevio
              ? Colors.blue.withOpacity(0.30)
              : Colors.green.withOpacity(0.30),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hayRegistroPrevio ? Icons.update : Icons.add_task,
            color: _hayRegistroPrevio ? Colors.blue : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _hayRegistroPrevio
                  ? 'Ya existe asistencia registrada para esta sección y fecha. Puede actualizarla.'
                  : 'No hay asistencia registrada para esta sección y fecha. Se creará un nuevo registro.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _hayRegistroPrevio
                    ? Colors.blue.shade800
                    : Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoChip(String estado) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _colorEstado(estado),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        estado,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _itemEstudiante(Estudiante estudiante) {
    final estado = _estados[estudiante.id] ?? 'A';
    final justificacion = _justificaciones[estudiante.id] ?? '';
    final tieneJustificacion = justificacion.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: ListTile(
          leading: _estadoChip(estado),
          title: Text(
            estudiante.nombreCompleto,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DNI: ${estudiante.dni}'),
              Text(
                _textoEstado(estado),
                style: TextStyle(
                  color: _colorEstado(estado),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (tieneJustificacion)
                Text(
                  'Justificación: $justificacion',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              DropdownButton<String>(
                value: estado,
                items: _opcionesEstado.map((opcion) {
                  return DropdownMenuItem<String>(
                    value: opcion,
                    child: Text(opcion),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _estados[estudiante.id] = value;

                    if (!_requiereJustificacion(value)) {
                      _justificaciones[estudiante.id] = '';
                    }
                  });

                  if (_requiereJustificacion(value)) {
                    _editarJustificacion(estudiante);
                  }
                },
              ),
              IconButton(
                tooltip: 'Justificación',
                icon: Icon(
                  tieneJustificacion
                      ? Icons.note_alt
                      : Icons.note_alt_outlined,
                  color: tieneJustificacion ? Colors.blue : null,
                ),
                onPressed: () {
                  _editarJustificacion(estudiante);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asistenciaStream =
    _firestoreService.streamAsistenciaPorFechaYSeccion(
      seccionId: widget.seccionId,
      fecha: _fecha,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia rápida'),
        actions: [
          IconButton(
            tooltip: 'Seleccionar fecha',
            icon: const Icon(Icons.calendar_month),
            onPressed: _seleccionarFecha,
          ),
        ],
      ),
      body: StreamBuilder<List<Estudiante>>(
        stream: _firestoreService.streamEstudiantesPorSeccion(
          widget.seccionId,
        ),
        builder: (context, estudiantesSnapshot) {
          if (estudiantesSnapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar estudiantes: ${estudiantesSnapshot.error}',
              ),
            );
          }

          if (!estudiantesSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final estudiantes = estudiantesSnapshot.data ?? [];

          return StreamBuilder<List<Asistencia>>(
            key: ValueKey(_claveCarga()),
            stream: asistenciaStream,
            builder: (context, asistenciasSnapshot) {
              if (asistenciasSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar asistencia: ${asistenciasSnapshot.error}',
                  ),
                );
              }

              if (!asistenciasSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final asistencias = asistenciasSnapshot.data ?? [];

              _cargarAsistenciasExistentes(
                estudiantes: estudiantes,
                asistencias: asistencias,
              );

              final estudiantesFiltrados = _filtrarEstudiantes(estudiantes);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fecha: ${_fechaTexto(_fecha)} | Ingreso: 7:00 a. m.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _seleccionarFecha,
                              icon: const Icon(Icons.edit_calendar),
                              label: const Text('Cambiar'),
                            ),
                          ],
                        ),
                        _resumenRegistro(),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _busquedaController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar por nombre o DNI',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _filtro = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: estudiantes.isEmpty
                        ? const Center(
                      child: Text(
                        'No hay estudiantes para mostrar',
                      ),
                    )
                        : estudiantesFiltrados.isEmpty
                        ? const Center(
                      child: Text(
                        'No se encontraron estudiantes con ese filtro',
                      ),
                    )
                        : ListView.builder(
                      itemCount: estudiantesFiltrados.length,
                      itemBuilder: (context, index) {
                        final estudiante =
                        estudiantesFiltrados[index];

                        return _itemEstudiante(estudiante);
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: _guardando
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : Icon(
                            _hayRegistroPrevio
                                ? Icons.update
                                : Icons.save,
                          ),
                          label: Text(
                            _guardando
                                ? 'Guardando...'
                                : _hayRegistroPrevio
                                ? 'Actualizar asistencia'
                                : 'Guardar asistencia',
                          ),
                          onPressed: _guardando || estudiantes.isEmpty
                              ? null
                              : () => _guardarAsistencia(estudiantes),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}