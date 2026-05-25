import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

import 'admin/bimestres_page.dart';
import 'admin/estudiantes_page.dart';
import 'admin/grados_page.dart';
import 'admin/secciones_page.dart';
import 'admin/usuarios_page.dart';

import 'asistencia_rapida_page.dart';
import 'reporte_bimestral_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  final _authService = AuthService();

  final _firestoreService =
  FirestoreService();

  Map<String, dynamic>?
  _seccionSeleccionada;

  final _buscarController =
  TextEditingController();

  Future<void> _cerrarSesion() async {
    await _authService.logout();
  }

  Future<void> _seleccionarSeccion(
      List<Map<String, dynamic>>
      secciones,
      ) async {
    List<Map<String, dynamic>>
    filtradas = List.from(
      secciones,
    );

    await showDialog(
      context: context,

      builder: (_) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            return AlertDialog(
              title: const Text(
                'Seleccionar sección',
              ),

              content: SizedBox(
                width: 450,
                height: 500,

                child: Column(
                  children: [
                    TextField(
                      controller:
                      _buscarController,

                      decoration:
                      const InputDecoration(
                        hintText:
                        'Buscar sección...',
                        prefixIcon:
                        Icon(
                          Icons.search,
                        ),
                        border:
                        OutlineInputBorder(),
                      ),

                      onChanged: (
                          value,
                          ) {
                        setModalState(() {
                          filtradas =
                              secciones.where(
                                    (
                                    s,
                                    ) {
                                  final texto =
                                  '${s['gradoNombre']} ${s['nombre']}'
                                      .toLowerCase();

                                  return texto.contains(
                                    value
                                        .toLowerCase(),
                                  );
                                },
                              ).toList();
                        });
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Expanded(
                      child:
                      ListView.builder(
                        itemCount:
                        filtradas.length,

                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          final seccion =
                          filtradas[
                          index];

                          return Card(
                            child:
                            ListTile(
                              leading:
                              CircleAvatar(
                                child: Text(
                                  seccion[
                                  'nombre'],
                                ),
                              ),

                              title: Text(
                                seccion[
                                'gradoNombre'],
                              ),

                              subtitle:
                              Text(
                                'Sección ${seccion['nombre']}',
                              ),

                              onTap: () {
                                setState(() {
                                  _seccionSeleccionada =
                                      seccion;
                                });

                                Navigator.pop(
                                  context,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream:
      _authService.streamUsuarioActual(),

      builder: (
          context,
          userSnapshot,
          ) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (userSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error al cargar usuario: ${userSnapshot.error}'),
            ),
          );
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'El usuario inició sesión, pero no tiene perfil registrado en Firestore.',
              ),
            ),
          );
        }

        final usuario =
        userSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Sistema de Asistencia',
            ),

            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout,
                ),

                onPressed:
                _cerrarSesion,
              ),
            ],
          ),

          body: Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),

            child:
            StreamBuilder<
                List<
                    Map<String, dynamic>
                >
            >(
              stream:
              _firestoreService
                  .streamSecciones(),

              builder: (
                  context,
                  snapshot,
                  ) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                final secciones =
                    snapshot.data ?? [];

                final permitidas =
                usuario
                    .seccionesIds
                    .isEmpty
                    ? secciones
                    : secciones.where(
                      (
                      s,
                      ) {
                    return usuario
                        .seccionesIds
                        .contains(
                      s['id'],
                    );
                  },
                ).toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [
                      Container(
                        width:
                        double.infinity,

                        padding:
                        const EdgeInsets.all(
                          20,
                        ),

                        decoration:
                        BoxDecoration(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primaryContainer,

                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [
                            const Text(
                              'Bienvenido',
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              usuario.nombres,

                              style:
                              const TextStyle(
                                fontSize:
                                24,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Chip(
                              label: Text(
                                usuario.rol
                                    .toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      const Text(
                        'Sección seleccionada',

                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      InkWell(
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),

                        onTap: () {
                          _seleccionarSeccion(
                            permitidas,
                          );
                        },

                        child: Container(
                          width:
                          double.infinity,

                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),

                          decoration:
                          BoxDecoration(
                            border: Border.all(
                              color:
                              Colors.grey,
                            ),

                            borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups,
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child: Text(
                                  _seccionSeleccionada ==
                                      null
                                      ? 'Seleccione una sección'
                                      : '${_seccionSeleccionada!['gradoNombre']} - Sección ${_seccionSeleccionada!['nombre']}',

                                  style:
                                  const TextStyle(
                                    fontSize:
                                    16,
                                  ),
                                ),
                              ),

                              const Icon(
                                Icons
                                    .arrow_drop_down,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      SizedBox(
                        width:
                        double.infinity,

                        child:
                        FilledButton.icon(
                          icon:
                          const Icon(
                            Icons.check,
                          ),

                          label: const Text(
                            'Asistencia rápida',
                          ),

                          style:
                          FilledButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(
                              vertical:
                              18,
                            ),
                          ),

                          onPressed:
                          _seccionSeleccionada ==
                              null
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                    AsistenciaRapidaPage(
                                      seccionId:
                                      _seccionSeleccionada![
                                      'id'],

                                      usuario:
                                      usuario,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SizedBox(
                        width:
                        double.infinity,

                        child:
                        OutlinedButton.icon(
                          icon:
                          const Icon(
                            Icons.bar_chart,
                          ),

                          label: const Text(
                            'Reporte bimestral',
                          ),

                          style:
                          OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(
                              vertical:
                              18,
                            ),
                          ),

                          onPressed:
                          _seccionSeleccionada ==
                              null
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                    ReporteBimestralPage(
                                      seccionId:
                                      _seccionSeleccionada![
                                      'id'],
                                    ),
                              ),
                            );
                          },
                        ),
                      ),

                      if (usuario
                          .esAdministrador)
                        ...[
                          const SizedBox(
                            height: 36,
                          ),

                          const Divider(),

                          const SizedBox(
                            height: 20,
                          ),

                          const Text(
                            'Administración',

                            style: TextStyle(
                              fontSize:
                              20,

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          Wrap(
                            spacing: 12,
                            runSpacing:
                            12,

                            children: [
                              _menuCard(
                                titulo:
                                'Grados',

                                icono:
                                Icons
                                    .school,

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                      const GradosPage(),
                                    ),
                                  );
                                },
                              ),

                              _menuCard(
                                titulo:
                                'Secciones',

                                icono:
                                Icons
                                    .groups,

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                      const SeccionesPage(),
                                    ),
                                  );
                                },
                              ),

                              _menuCard(
                                titulo:
                                'Bimestres',

                                icono:
                                Icons
                                    .calendar_month,

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                      const BimestresPage(),
                                    ),
                                  );
                                },
                              ),

                              _menuCard(
                                titulo:
                                'Usuarios',

                                icono:
                                Icons.people,

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                      const UsuariosPage(),
                                    ),
                                  );
                                },
                              ),

                              _menuCard(
                                titulo:
                                'Estudiantes',

                                icono:
                                Icons.badge,

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                      const EstudiantesPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _menuCard({
    required String titulo,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      height: 110,

      child: Card(
        elevation: 2,

        child: InkWell(
          borderRadius:
          BorderRadius.circular(
            12,
          ),

          onTap: onTap,

          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [
              Icon(
                icono,
                size: 38,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                titulo,

                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}