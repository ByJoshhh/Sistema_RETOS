import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class DialogoNuevoUsuario extends StatefulWidget {
  final Map<String, dynamic>? usuarioEdicion; // Si viene lleno, es modo EDICIÓN

  const DialogoNuevoUsuario({super.key, this.usuarioEdicion});

  @override
  State<DialogoNuevoUsuario> createState() => _DialogoNuevoUsuarioState();
}

class _DialogoNuevoUsuarioState extends State<DialogoNuevoUsuario> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _rolSeleccionado;
  bool _isLoading = false;
  bool _ocultarPass = true;

  final List<String> _roles = ['checador_banco', 'checador_obra', 'residente'];

  @override
  void initState() {
    super.initState();
    // Si estamos en modo edición, llenamos las cajas de texto con los datos actuales
    if (widget.usuarioEdicion != null) {
      _nombreController.text = widget.usuarioEdicion!['nombre_completo'];
      _usernameController.text = widget.usuarioEdicion!['username'];

      // Aseguramos que el rol exista en nuestra lista para que el Dropdown no truene
      String rolDB = widget.usuarioEdicion!['rol'].toString().toLowerCase();
      if (_roles.contains(rolDB)) {
        _rolSeleccionado = rolDB;
      }
    }
  }

  void _guardarUsuario() async {
    final bool esEdicion = widget.usuarioEdicion != null;

    if (_nombreController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _rolSeleccionado == null) {
      _mostrarSnack('Por favor llena todos los campos', Colors.orange);
      return;
    }

    // Si es nuevo, la contraseña es obligatoria. Si es edición, puede ir vacía.
    if (!esEdicion && _passwordController.text.isEmpty) {
      _mostrarSnack(
        'La contraseña es obligatoria para nuevos usuarios',
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token_seguridad');
      final int idEmpresa = prefs.getInt('id_empresa') ?? 1;

      if (token == null) return;

      // Si es edición, usamos PUT con el ID en la URL. Si es nuevo, usamos POST.
      final url = esEdicion
          ? Uri.parse(
              '${Config.apiUrl}/api/usuarios/${widget.usuarioEdicion!['id_usuario']}',
            )
          : Uri.parse('${Config.apiUrl}/api/usuarios');

      final bodyData = json.encode({
        'id_empresa': idEmpresa,
        'nombre_completo': _nombreController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'rol': _rolSeleccionado,
      });

      final response = esEdicion
          ? await http.put(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: bodyData,
            )
          : await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: bodyData,
            );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          _mostrarSnack(data['mensaje'], Colors.green);
        }
      } else {
        _mostrarSnack(data['mensaje'] ?? 'Error al guardar', Colors.red);
      }
    } catch (e) {
      _mostrarSnack('Error de conexión con el servidor', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final bool esEdicion = widget.usuarioEdicion != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            esEdicion ? Icons.manage_accounts : Icons.person_add,
            color: const Color(0xFF4318FF),
          ),
          const SizedBox(width: 10),
          Text(
            esEdicion ? 'Editar Empleado' : 'Nuevo Empleado',
            style: const TextStyle(
              color: Color(0xFF2B3674),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.badge),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario (Para iniciar sesión)',
                  prefixIcon: Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _ocultarPass,
                decoration: InputDecoration(
                  labelText: esEdicion
                      ? 'Nueva Contraseña (Opcional)'
                      : 'Contraseña',
                  hintText: esEdicion
                      ? 'Déjala en blanco para no cambiarla'
                      : '',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPass ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarPass = !_ocultarPass),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Asignar Rol',
                  prefixIcon: Icon(Icons.work),
                ),
                items: _roles.map((rol) {
                  return DropdownMenuItem(
                    value: rol,
                    child: Text(rol.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _rolSeleccionado = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4318FF),
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _guardarUsuario,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(esEdicion ? 'Guardar Cambios' : 'Crear Acceso'),
        ),
      ],
    );
  }
}
