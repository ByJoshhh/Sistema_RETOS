import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart'; // <-- 1. Importamos el switch maestro

class ConsultaScreen extends StatefulWidget {
  const ConsultaScreen({super.key});

  @override
  State<ConsultaScreen> createState() => _ConsultaScreenState();
}

class _ConsultaScreenState extends State<ConsultaScreen> {
  List<dynamic> _historial = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  // --- GET: Traer todos los viajes de Node.js protegidos con Token ---
  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tokenSeguridad = prefs.getString('token_seguridad');

      if (tokenSeguridad == null) {
        setState(() {
          _errorMessage =
              'Sesión expirada o no válida. Vuelve a iniciar sesión.';
          _isLoading = false;
        });
        return;
      }

      // --- 2. USAMOS EL ARCHIVO MAESTRO ---
      final url = Uri.parse('${Config.apiUrl}/api/suministros');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenSeguridad',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        setState(() {
          _historial = data['datos'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['mensaje'] ?? 'Error al cargar los datos';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión con el servidor.';
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(dynamic fechaIso) {
    if (fechaIso == null) return 'Fecha no disponible';
    try {
      final DateTime fecha = DateTime.parse(fechaIso.toString()).toLocal();
      return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fechaIso.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Historial de Viajes',
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
      body: RefreshIndicator(
        onRefresh: _cargarHistorial,
        color: const Color(0xFF4A5D6A),
        child: _construirCuerpo(),
      ),
    );
  }

  Widget _construirCuerpo() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4A5D6A)),
            SizedBox(height: 15),
            Text(
              'Cargando registros...',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 15),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A5D6A),
                ),
                onPressed: _cargarHistorial,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            const Text(
              'Aún no hay viajes registrados.',
              style: TextStyle(color: Colors.blueGrey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15.0),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final viaje = _historial[index];
        final bool enTransito = viaje['estatus'] == 'En tránsito';

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      viaje['folio_suministro'] ?? 'S/N',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2229),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: enTransito
                            ? Colors.orange[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: enTransito
                              ? Colors.orange.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Text(
                        viaje['estatus'] ?? 'Desconocido',
                        style: TextStyle(
                          color: enTransito
                              ? Colors.orange[800]
                              : Colors.green[800],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 25, thickness: 1, color: Colors.black12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatearFecha(viaje['fecha_hora']),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.landscape,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Origen: ${viaje['nombre_banco'] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Destino: ${viaje['nombre_destino'] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            viaje['unidad'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.layers,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "${viaje['cantidad_m3']} m3 de ${viaje['nombre_material']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
