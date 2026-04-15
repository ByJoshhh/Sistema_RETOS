import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart'; // <-- 1. Importamos el switch maestro

class DialogoNuevaUnidad extends StatefulWidget {
  const DialogoNuevaUnidad({super.key});

  @override
  State<DialogoNuevaUnidad> createState() => _DialogoNuevaUnidadState();
}

class _DialogoNuevaUnidadState extends State<DialogoNuevaUnidad> {
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _capacidadController = TextEditingController();
  bool _isLoading = false;

  void _guardarUnidad() async {
    if (_placaController.text.isEmpty || _capacidadController.text.isEmpty) {
      _mostrarSnack('Por favor llena todos los campos', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token_seguridad');

      if (token == null) {
        _mostrarSnack('Sesión expirada. Sal y vuelve a entrar.', Colors.red);
        return;
      }

      // --- 2. USAMOS EL ARCHIVO MAESTRO ---
      final url = Uri.parse('${Config.apiUrl}/api/unidades');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'placa': _placaController.text.trim().toUpperCase(),
          'capacidad_m3': double.tryParse(_capacidadController.text) ?? 0.0,
        }),
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
      _mostrarSnack(
        'Error de conexión: ¿Está encendido el servidor?',
        Colors.red,
      );
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.local_shipping, color: Color(0xFF4318FF)),
          SizedBox(width: 10),
          Text(
            'Nueva Unidad',
            style: TextStyle(
              color: Color(0xFF2B3674),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _placaController,
              decoration: const InputDecoration(
                labelText: 'Placa / Económico',
                prefixIcon: Icon(Icons.pin),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _capacidadController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Capacidad (m³)',
                prefixIcon: Icon(Icons.straighten),
                suffixText: 'm³',
              ),
            ),
          ],
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
          onPressed: _isLoading ? null : _guardarUnidad,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
