import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dialogo_nuevo_usuario.dart';
import '../../config.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  // --- FUNCIÓN PARA TRAER EL PERSONAL DESDE EL BACKEND ---
  Future<void> _cargarUsuarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token_seguridad');

      if (token == null) return;

      final url = Uri.parse('${Config.apiUrl}/api/usuarios');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _usuarios = data['datos'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNCIÓN PARA EL BOTÓN DE BLOQUEO (BAJA LÓGICA) ---
  void _confirmarBloqueo(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Bloquear Acceso'),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas dar de baja a ${usuario['nombre_completo']}?\n\nEsta persona ya no podrá entrar al sistema.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final String? token = prefs.getString('token_seguridad');
                final url = Uri.parse(
                  '${Config.apiUrl}/api/usuarios/${usuario['id_usuario']}',
                );

                final response = await http.delete(
                  url,
                  headers: {'Authorization': 'Bearer $token'},
                );

                if (response.statusCode == 200) {
                  _mostrarSnack(
                    'Usuario bloqueado correctamente',
                    Colors.redAccent,
                  );
                  _cargarUsuarios(); // Refrescamos la tabla
                }
              } catch (e) {
                _mostrarSnack('Error al conectar con el servidor', Colors.red);
                setState(() => _isLoading = false);
              }
            },
            child: const Text(
              'Bloquear',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSnack(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Control de Personal y Accesos',
          style: TextStyle(
            color: Color(0xFF2B3674),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Personal Activo: ${_usuarios.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4318FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text(
                        'Agregar Empleado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const DialogoNuevoUsuario(),
                        ).then((creado) {
                          if (creado == true) {
                            setState(() => _isLoading = true);
                            _cargarUsuarios();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 30),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4318FF),
                          ),
                        )
                      : _usuarios.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay personal registrado en esta empresa.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                const Color(0xFFF4F7FE),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Nombre Completo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B3674),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Usuario',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B3674),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Rol Asignado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B3674),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Estatus',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B3674),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Acciones',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B3674),
                                    ),
                                  ),
                                ),
                              ],
                              rows: _usuarios.map((u) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        u['nombre_completo'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(u['username'] ?? 'N/A')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          (u['rol'] ?? 'N/A')
                                              .toUpperCase()
                                              .replaceAll('_', ' '),
                                          style: TextStyle(
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        'ACTIVO',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          // BOTÓN EDITAR
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    DialogoNuevoUsuario(
                                                      usuarioEdicion: u,
                                                    ),
                                              ).then((actualizado) {
                                                if (actualizado == true) {
                                                  setState(
                                                    () => _isLoading = true,
                                                  );
                                                  _cargarUsuarios();
                                                }
                                              });
                                            },
                                          ),
                                          // BOTÓN BLOQUEAR
                                          IconButton(
                                            icon: const Icon(
                                              Icons.block,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _confirmarBloqueo(u),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
