import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ticket_acarreo_screen.dart';

class RegistroImagenesAcarreoScreen extends StatefulWidget {
  final Map<String, dynamic> datosViaje;
  final double distanciaKm;
  final double cantidadM3;

  const RegistroImagenesAcarreoScreen({
    super.key,
    required this.datosViaje,
    required this.distanciaKm,
    required this.cantidadM3,
  });

  @override
  State<RegistroImagenesAcarreoScreen> createState() =>
      _RegistroImagenesAcarreoScreenState();
}

class _RegistroImagenesAcarreoScreenState
    extends State<RegistroImagenesAcarreoScreen> {
  XFile? _fotoPlacaLlegada;
  XFile? _fotoMaterialDescarga;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _tomarFoto(bool esPlaca) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() {
          if (esPlaca) {
            _fotoPlacaLlegada = photo;
          } else {
            _fotoMaterialDescarga = photo;
          }
        });
      }
    } catch (e) {
      // Manejar error visual
    }
  }

  Future<void> _guardarRecepcion() async {
    if (_fotoPlacaLlegada == null || _fotoMaterialDescarga == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faltan fotos por capturar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // --- NUEVO: LEER EL TOKEN DE LA MEMORIA ---
      final prefs = await SharedPreferences.getInstance();
      final String? tokenSeguridad = prefs.getString('token_seguridad');

      if (tokenSeguridad == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Sesión no válida. Vuelva a iniciar sesión.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // CONEXIÓN A LA NUBE EN RENDER
      final String ipServidor = 'https://api-retos.onrender.com';
      final url = Uri.parse('$ipServidor/api/acarreos');

      // --- MODIFICADO: Solo enviamos datos de la operación.
      // Ya NO enviamos id_empresa ni id_checador_obra. ---
      final bodyData = json.encode({
        "folio_suministro": widget.datosViaje['folio_suministro'],
        "distancia_km": widget.distanciaKm,
        "cantidad_m3_recibida": widget.cantidadM3,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $tokenSeguridad', // <-- NUEVO: Enviamos el token al guardia
        },
        body: bodyData,
      );

      final data = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['exito'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TicketAcarreoScreen(
              datosViaje: widget.datosViaje,
              folioAcarreo: data['folio_acarreo'],
              kmReales: widget.distanciaKm,
              m3Reales: widget.cantidadM3,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['mensaje'] ?? 'No se pudo guardar'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión con el servidor'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _visorDeFoto(XFile? foto, String titulo, VoidCallback onPresionar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, size: 30),
              onPressed: onPresionar,
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onPresionar,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: foto == null
                ? const Center(
                    child: Text(
                      'Tocar para capturar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(foto.path, fit: BoxFit.cover)
                        : Image.file(File(foto.path), fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Acarreo Material',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1C2229),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione las 2 imágenes para guardar:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 30),
            _visorDeFoto(
              _fotoPlacaLlegada,
              'Placa del Camión:',
              () => _tomarFoto(true),
            ),
            const SizedBox(height: 30),
            _visorDeFoto(
              _fotoMaterialDescarga,
              'Material Cargado en el Camión:',
              () => _tomarFoto(false),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5D6A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _guardarRecepcion,
                  child: Text(
                    _isSubmitting ? 'GUARDANDO...' : 'Guardar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '• Antes de crear el ticket se deben tomar las fotos de la placa y de la caja del camión',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
