import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart'; // <-- 1. Importamos el switch maestro

class ImpresionTicketScreen extends StatefulWidget {
  const ImpresionTicketScreen({super.key});

  @override
  State<ImpresionTicketScreen> createState() => _ImpresionTicketScreenState();
}

class _ImpresionTicketScreenState extends State<ImpresionTicketScreen> {
  final TextEditingController _folioController = TextEditingController();
  bool _isLoading = false;
  String? _ticketEncontrado;

  Future<void> _buscarTicket() async {
    final folioBuscado = _folioController.text.trim().toUpperCase();

    if (folioBuscado.isEmpty) {
      _mostrarAlerta('Por favor, ingrese un folio válido', Colors.orange[800]!);
      return;
    }

    setState(() {
      _isLoading = true;
      _ticketEncontrado = null;
    });

    try {
      // --- 2. USAMOS EL ARCHIVO MAESTRO ---
      final url = Uri.parse('${Config.apiUrl}/api/suministros/$folioBuscado');

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        setState(() {
          _ticketEncontrado = data['viaje']['folio_suministro'];
        });
      } else {
        _mostrarAlerta(data['mensaje'] ?? 'El folio no existe', Colors.red);
      }
    } catch (e) {
      print("Error al buscar: $e");
      _mostrarAlerta('Error de conexión con el servidor', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Impresión de Ticket',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buscar Suministro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2229),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Ingrese el folio exacto para buscarlo en la base de datos.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _folioController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Ej. GYB-1234',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.blueGrey,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFF4A5D6A),
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _buscarTicket(),
                        ),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: _isLoading ? null : _buscarTicket,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          height: 55,
                          width: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A5D6A),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A5D6A).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(15.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              child: _ticketEncontrado == null
                  ? const SizedBox.shrink()
                  : _buildTicketCard(_ticketEncontrado!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(String folio) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Column(
        children: [
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C2229),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'TICKET DE SUMINISTRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      const Text(
                        'FOLIO CONFIRMADO',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        folio,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: QrImageView(
                          data: folio,
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1C2229),
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: List.generate(20, (index) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: index % 2 == 0
                            ? Colors.grey.shade300
                            : Colors.transparent,
                      ),
                    );
                  }),
                ),

                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Muestre este código al Checador de Obra',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: 300,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conectando a impresora Bluetooth...'),
                  ),
                );
              },
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text(
                'Imprimir Recibo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
