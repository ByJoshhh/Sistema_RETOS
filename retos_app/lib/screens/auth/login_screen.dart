import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../menu/main_menu_screen.dart';
import '../../config.dart';
import 'pre_registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Controla si estamos en la pestaña de Dueño o Empleado
  bool _isModoAdmin = false;

  Future<void> _iniciarSesion() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarMensaje('Por favor, ingresa usuario y contraseña', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${Config.apiUrl}/api/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        final usuario = data['usuario'];
        final String rol = usuario['rol'];
        final String nombre = usuario['nombre_completo'];
        final String tokenSeguridad = data['token'];

        // --- VALIDACIÓN DE SEGURIDAD POR PESTAÑA ---

        // 1. Si intenta entrar como Dueño pero su cuenta no es admin
        if (_isModoAdmin && rol != 'admin') {
          _mostrarMensaje(
            'Acceso denegado: Esta pestaña es exclusiva para administradores.',
            Colors.red,
          );
          setState(() => _isLoading = false);
          return;
        }

        // 2. Si intenta entrar como Empleado pero su cuenta es de administrador
        if (!_isModoAdmin && rol == 'admin') {
          _mostrarMensaje(
            'Por favor, inicia sesión en la pestaña de "Dueño".',
            Colors.orange,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Guardar sesión si pasó los filtros
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id_usuario', usuario['id_usuario']);
        await prefs.setInt('id_empresa', usuario['id_empresa']);
        await prefs.setString('nombre_completo', usuario['nombre_completo']);
        await prefs.setString('rol', usuario['rol']);
        await prefs.setString('token_seguridad', tokenSeguridad);

        _mostrarMensaje('¡Bienvenido $nombre!', Colors.green);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainMenuScreen(nombre: nombre, rol: rol),
          ),
        );
      } else {
        _mostrarMensaje(data['mensaje'] ?? 'Error de credenciales', Colors.red);
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión con el servidor', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de la App
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    size: 50,
                    color: Color(0xFF4A5D6A),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SyC.O.R.E.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C2229),
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'SISTEMA DE CONTROL',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Formulario Principal
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INTERRUPTOR DE VISTAS (Toggle)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            _buildToggleButton(
                              'Empleado',
                              !_isModoAdmin,
                              () => setState(() => _isModoAdmin = false),
                            ),
                            _buildToggleButton(
                              'Dueño',
                              _isModoAdmin,
                              () => setState(() => _isModoAdmin = true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2229),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Campos de Texto
                      _buildTextField(
                        _usernameController,
                        'Usuario',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        _passwordController,
                        'Contraseña',
                        Icons.lock_outline,
                        obscure: true,
                      ),
                      const SizedBox(height: 15),

                      // Olvidó su contraseña (Solo Dueño)
                      if (_isModoAdmin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '¿Olvidó su contraseña?',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 35),

                      // Botón Entrar
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A5D6A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: _isLoading ? null : _iniciarSesion,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ENTRAR AL SISTEMA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                      // Registro de Empresa (Solo Dueño)
                      if (_isModoAdmin) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PreRegistroScreen(),
                              ),
                            ),
                            child: const Text(
                              '¿Tu empresa es nueva? Regístrate aquí',
                              style: TextStyle(
                                color: Color(0xFF4A5D6A),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  '© 2026 Tecnologico superior de poza rica',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para los inputs
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF4A5D6A), width: 2),
        ),
      ),
    );
  }

  // Widget auxiliar para el switch
  Widget _buildToggleButton(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF4A5D6A) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
