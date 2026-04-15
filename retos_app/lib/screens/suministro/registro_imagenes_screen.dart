import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'registro_exitoso_screen.dart';
import '../../config.dart'; // <-- 1. Importamos el switch maestro

class RegistroImagenesScreen extends StatefulWidget {
  final int idBanco;
  final int idMaterial;
  final int idResidente;
  final int idDestino;
  final int idSindicato;
  final int idUnidad;
  final double cantidadM3;

  const RegistroImagenesScreen({
    super.key,
    required this.idBanco,
    required this.idMaterial,
    required this.idResidente,
    required this.idDestino,
    required this.idSindicato,
    required this.idUnidad,
    required this.cantidadM3,
  });

  @override
  State<RegistroImagenesScreen> createState() => _RegistroImagenesScreenState();
}

class _RegistroImagenesScreenState extends State<RegistroImagenesScreen> {
  XFile? _fotoPlacas;
  XFile? _fotoMaterial;
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
          if (esPlaca)
            _fotoPlacas = photo;
          else
            _fotoMaterial = photo;
        });
      }
    } catch (e) {
      _mostrarAlerta('Error al abrir la cámara', Colors.red);
    }
  }

  Future<void> _guardarSuministro() async {
    if (_fotoPlacas == null || _fotoMaterial == null) {
      _mostrarAlerta('Por favor, toma ambas fotografías', Colors.orange[800]!);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final int idChecadorReal = prefs.getInt('id_usuario') ?? 1;
      final int idEmpresaReal = prefs.getInt('id_empresa') ?? 1;
      final String? token = prefs.getString('token_seguridad');

      if (token == null) {
        _mostrarAlerta('Sesión expirada. Vuelve a iniciar sesión.', Colors.red);
        setState(() => _isSubmitting = false);
        return;
      }

      // --- 2. USAMOS EL ARCHIVO MAESTRO ---
      final url = Uri.parse('${Config.apiUrl}/api/suministros');

      final bodyData = json.encode({
        "id_checador": idChecadorReal,
        "id_banco": widget.idBanco,
        "id_material": widget.idMaterial,
        "id_destino": widget.idDestino,
        "id_unidad": widget.idUnidad,
        "cantidad_m3": widget.cantidadM3,
        "id_empresa": idEmpresaReal,
        "id_residente": widget.idResidente,
        "id_sindicato": widget.idSindicato,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: bodyData,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RegistroExitosoScreen(folio: data['folio_qr'] ?? 'SIN-FOLIO'),
          ),
        );
      } else {
        _mostrarAlerta(
          data['mensaje'] ?? 'Error al guardar el viaje',
          Colors.red,
        );
      }
    } catch (e) {
      _mostrarAlerta('Error de conexión con el servidor', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _mostrarAlerta(String mensaje, Color color) {
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

  Widget _visorDeFoto(
    XFile? foto,
    String titulo,
    IconData icono,
    VoidCallback onPresionar,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: Colors.blueGrey, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1C2229),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: onPresionar,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: foto == null
                      ? Colors.grey.shade300
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: foto == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tocar para capturar',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: kIsWeb
                          ? Image.network(
                              foto.path,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Image.file(
                              File(foto.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Evidencia Fotográfica',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1C2229),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5D6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Paso 2 de 2',
                  style: TextStyle(
                    color: Color(0xFF4A5D6A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Capture las fotografías',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2229),
                ),
              ),
              const Text(
                'Ambas imágenes son obligatorias para el registro.',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
              ),
              const SizedBox(height: 25),

              _visorDeFoto(
                _fotoPlacas,
                'Placas de la Unidad',
                Icons.pin,
                () => _tomarFoto(true),
              ),
              const SizedBox(height: 20),

              _visorDeFoto(
                _fotoMaterial,
                'Material Cargado',
                Icons.layers,
                () => _tomarFoto(false),
              ),
              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _guardarSuministro,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GUARDAR REGISTRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.check_circle, color: Colors.white),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
