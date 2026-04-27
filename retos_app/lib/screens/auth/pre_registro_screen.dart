import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'activacion_empresa_screen.dart';

class PreRegistroScreen extends StatefulWidget {
  const PreRegistroScreen({super.key});

  @override
  State<PreRegistroScreen> createState() => _PreRegistroScreenState();
}

class _PreRegistroScreenState extends State<PreRegistroScreen> {
  final _empresaController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Función para mostrar el diálogo de advertencia (Rate Limit)
  void _mostrarDialogoAdvertencia(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obligamos a que lean el mensaje
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text(
              'Aviso de Seguridad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          mensaje,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4318FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _solicitarRegistro() async {
    if (_empresaController.text.isEmpty || _emailController.text.isEmpty) {
      _mostrarSnack('Por favor llena ambos campos', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/api/activacion/solicitar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre_empresa': _empresaController.text.trim(),
          'email_admin': _emailController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      // --- 🛡️ CAPA DE CONCIENCIA: MANEJO DE RATE LIMIT (429) ---
      if (response.statusCode == 429) {
        _mostrarDialogoAdvertencia(
          data['mensaje'] ??
              'Límite de intentos alcanzado. Reintenta más tarde.',
        );
        return;
      }

      if (response.statusCode == 200 && data['exito'] == true) {
        if (mounted) {
          // Informamos al usuario que el código se envió pero que sea cuidadoso con los intentos
          _mostrarSnack(
            '¡Código enviado! Tienes 3 intentos por hora.',
            Colors.green,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ActivacionEmpresaScreen(),
            ),
          );
        }
      } else {
        _mostrarSnack(
          data['mensaje'] ?? 'Error al procesar la solicitud',
          Colors.red,
        );
      }
    } catch (e) {
      _mostrarSnack('Error de conexión con el servidor', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String msj, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msj, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        iconTheme: const IconThemeData(color: Colors.black),
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
                  Icons.rocket_launch,
                  size: 60,
                  color: Color(0xFF4318FF),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Afilia tu Empresa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ingresa los datos para generar tu espacio de trabajo. Se enviará un código a tu correo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _empresaController,
                  decoration: InputDecoration(
                    labelText: 'Razón Social / Constructora',
                    prefixIcon: const Icon(Icons.business_rounded),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Tu Correo Real',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4318FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isLoading ? null : _solicitarRegistro,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enviar Código Mágico',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nota: Por seguridad, solo se permiten 3 solicitudes de código por hora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
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
