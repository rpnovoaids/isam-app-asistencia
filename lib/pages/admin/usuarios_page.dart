import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> roles = [
    'directivo',
    'docente',
    'auxiliar',
    'padre',
    'estudiante',
  ];

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

  String rolSeleccionado = 'docente';
  bool activo = true;

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizarRol(String? rol) {
    final valor = rol?.trim().toLowerCase();

    if (valor == null || valor.isEmpty) {
      return 'docente';
    }

    if (valor == 'director') {
      return 'directivo';
    }

    if (roles.contains(valor)) {
      return valor;
    }

    return 'docente';
  }

  String _textoRol(String rol) {
    switch (rol) {
      case 'directivo':
        return 'DIRECTIVO';
      case 'docente':
        return 'DOCENTE';
      case 'auxiliar':
        return 'AUXILIAR';
      case 'padre':
        return 'PADRE';
      case 'estudiante':
        return 'ESTUDIANTE';
      default:
        return rol.toUpperCase();
    }
  }

  IconData _iconoRol(String rol) {
    switch (rol) {
      case 'directivo':
        return Icons.admin_panel_settings;
      case 'docente':
        return Icons.school;
      case 'auxiliar':
        return Icons.support_agent;
      case 'padre':
        return Icons.family_restroom;
      case 'estudiante':
        return Icons.badge;
      default:
        return Icons.person;
    }
  }

  Color _colorPorTexto(String texto) {
    if (texto.trim().isEmpty) {
      return Colors.grey;
    }

    final inicial = texto.trim().toUpperCase().codeUnitAt(0);
    final index = inicial % _coloresIniciales.length;

    return _coloresIniciales[index];
  }

  String _inicialNombre(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return '?';
    }

    return texto.trim()[0].toUpperCase();
  }

  Future<void> _mostrarDialogo({
    DocumentSnapshot? usuario,
  }) async {
    _dniController.clear();
    _nombresController.clear();
    _correoController.clear();
    _passwordController.clear();

    rolSeleccionado = 'docente';
    activo = true;

    if (usuario != null) {
      final data = usuario.data() as Map<String, dynamic>;

      _dniController.text = data['dni'] ?? '';
      _nombresController.text = data['nombres'] ?? '';
      _correoController.text = data['correo'] ?? data['email'] ?? '';
      rolSeleccionado = _normalizarRol(data['rol']);
      activo = data['activo'] ?? true;
    }

    await showDialog(
      context: context,
      builder: (_) {
        String rolTemporal = rolSeleccionado;
        bool activoTemporal = activo;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                usuario == null ? 'Nuevo usuario' : 'Editar usuario',
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
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (usuario == null)
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                      if (usuario == null) const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: roles.contains(rolTemporal)
                            ? rolTemporal
                            : 'docente',
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.manage_accounts),
                        ),
                        items: roles.map((rol) {
                          return DropdownMenuItem<String>(
                            value: rol,
                            child: Row(
                              children: [
                                Icon(
                                  _iconoRol(rol),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(_textoRol(rol)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setModalState(() {
                            rolTemporal = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: activoTemporal,
                        title: const Text('Activo'),
                        subtitle: Text(
                          activoTemporal
                              ? 'El usuario podrá ingresar al sistema.'
                              : 'El usuario permanecerá registrado, pero inactivo.',
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
                    final correo = _correoController.text.trim();
                    final password = _passwordController.text.trim();

                    if (dni.isEmpty || nombres.isEmpty || correo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Complete DNI, nombres y correo.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (usuario == null && password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La contraseña debe tener mínimo 6 caracteres.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (usuario == null) {
                        final cred =
                        await _auth.createUserWithEmailAndPassword(
                          email: correo,
                          password: password,
                        );

                        await _db.collection('usuarios').doc(cred.user!.uid).set({
                          'uid': cred.user!.uid,
                          'dni': dni,
                          'nombres': nombres,
                          'correo': correo,
                          'email': correo,
                          'rol': rolTemporal,
                          'activo': activoTemporal,
                          'estudianteId': null,
                          'seccionesIds': [],
                          'creadoEn': FieldValue.serverTimestamp(),
                          'actualizadoEn': FieldValue.serverTimestamp(),
                        });
                      } else {
                        await _db.collection('usuarios').doc(usuario.id).update({
                          'dni': dni,
                          'nombres': nombres,
                          'correo': correo,
                          'email': correo,
                          'rol': rolTemporal,
                          'activo': activoTemporal,
                          'actualizadoEn': FieldValue.serverTimestamp(),
                        });
                      }

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar usuario: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    usuario == null ? 'Guardar' : 'Actualizar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarUsuario(String uid) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar usuario'),
          content: const Text(
            '¿Desea eliminar este usuario?\n\n'
                'Esto eliminará el perfil en Firestore, pero no elimina la cuenta de Firebase Authentication.',
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

    await _db.collection('usuarios').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogo();
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar usuarios: ${snapshot.error}',
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
              child: Text('No hay usuarios registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final usuario = docs[index];
              final data = usuario.data() as Map<String, dynamic>;

              final nombres = data['nombres']?.toString() ?? '';
              final correo = data['correo']?.toString() ??
                  data['email']?.toString() ??
                  '';
              final dni = data['dni']?.toString() ?? '';
              final rol = _normalizarRol(data['rol']);
              final estaActivo = data['activo'] == true;

              final textoParaAvatar = nombres.trim().isNotEmpty
                  ? nombres
                  : correo;

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
                    nombres.isNotEmpty ? nombres : 'Sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(correo),
                      Text('DNI: $dni'),
                      Row(
                        children: [
                          Icon(
                            _iconoRol(rol),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text('Rol: ${_textoRol(rol)}'),
                        ],
                      ),
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
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _mostrarDialogo(usuario: usuario);
                        },
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _eliminarUsuario(usuario.id);
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