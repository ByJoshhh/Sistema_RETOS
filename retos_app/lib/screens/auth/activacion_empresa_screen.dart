import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class ActivacionEmpresaScreen extends StatefulWidget {
  const ActivacionEmpresaScreen({super.key});

  @override
  State<ActivacionEmpresaScreen> createState() =>
      _ActivacionEmpresaScreenState();
}

class _ActivacionEmpresaScreenState extends State<ActivacionEmpresaScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _ocultarPass = true;

  Future<void> _canjearCodigo() async {
    if (_codigoController.text.isEmpty ||
        _nombreController.text.isEmpty ||
        _usuarioController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _mostrarSnack('Por favor completa todos los campos', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Esta ruta es pública, no necesitamos token aquí
      final url = Uri.parse('${Config.apiUrl}/api/activacion/registrar-admin');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'codigo_token': _codigoController.text.trim().toUpperCase(),
          'nombre_completo': _nombreController.text.trim(),
          'username': _usuarioController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        if (mounted) {
          // Si todo salió bien, le mostramos éxito y lo regresamos al Login
          _mostrarSnack('¡Éxito! ${data['mensaje']}', Colors.green);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
      } else {
        _mostrarSnack(data['mensaje'] ?? 'Código inválido', Colors.red);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B3674)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.business_center,
                  size: 60,
                  color: Color(0xFF4318FF),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Activa tu Empresa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ingresa el código proporcionado por GYBSA para configurar tu cuenta de Administrador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 30),

                // --- CÓDIGO DE ACTIVACIÓN ---
                TextField(
                  controller: _codigoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Código de Activación',
                    hintText: 'Ej. PATOS-2026-VIP',
                    prefixIcon: const Icon(Icons.key, color: Colors.orange),
                    filled: true,
                    fillColor: Colors.orange.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.orange,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // --- DATOS DEL NUEVO ADMIN ---
                TextField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Tu Nombre Completo',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _usuarioController,
                  decoration: InputDecoration(
                    labelText: 'Usuario para iniciar sesión',
                    prefixIcon: const Icon(Icons.account_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPass,
                  decoration: InputDecoration(
                    labelText: 'Contraseña Segura',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPass ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _ocultarPass = !_ocultarPass),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- BOTÓN FINAL ---
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4318FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isLoading ? null : _canjearCodigo,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Validar y Crear Cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
