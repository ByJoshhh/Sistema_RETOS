import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart'; // <-- 1. Importamos el switch maestro

class HistorialViajesScreen extends StatefulWidget {
  const HistorialViajesScreen({super.key});

  @override
  State<HistorialViajesScreen> createState() => _HistorialViajesScreenState();
}

class _HistorialViajesScreenState extends State<HistorialViajesScreen> {
  List<dynamic> _viajes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tokenSeguridad = prefs.getString('token_seguridad');

      if (tokenSeguridad == null) {
        setState(() {
          _errorMessage = 'Error de sesión. Vuelve a iniciar sesión.';
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
          _viajes = data['datos'];
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

  String _formatearFecha(String fechaRaw) {
    if (fechaRaw.isEmpty) return 'N/A';
    try {
      return fechaRaw.substring(0, 16).replaceAll('T', ' ');
    } catch (e) {
      return fechaRaw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4318FF)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (_viajes.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay viajes registrados para esta empresa.',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total de registros: ${_viajes.length}',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4318FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar'),
              onPressed: () {
                setState(() => _isLoading = true);
                _cargarHistorial();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return _buildListaMovil();
              } else {
                return _buildTablaWeb();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListaMovil() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _viajes.length,
      itemBuilder: (context, index) {
        final viaje = _viajes[index];
        final bool enTransito = viaje['estatus'] == 'En tránsito';

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200),
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
                      viaje['folio_suministro'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2B3674),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: enTransito
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        viaje['estatus'] ?? 'N/A',
                        style: TextStyle(
                          color: enTransito
                              ? Colors.orange[800]
                              : Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _InfoFilaMovil(
                  icono: Icons.calendar_today,
                  texto: _formatearFecha(viaje['fecha_hora'] ?? ''),
                ),
                const SizedBox(height: 8),
                _InfoFilaMovil(
                  icono: Icons.layers,
                  texto:
                      '${viaje['nombre_material'] ?? 'N/A'}  •  ${viaje['cantidad_m3']} m³',
                  colorResalte: Colors.green[700],
                ),
                const SizedBox(height: 8),
                _InfoFilaMovil(
                  icono: Icons.route,
                  texto:
                      '${viaje['nombre_banco'] ?? 'N/A'} ➔ ${viaje['nombre_destino'] ?? 'N/A'}',
                ),
                const SizedBox(height: 8),
                _InfoFilaMovil(
                  icono: Icons.local_shipping,
                  texto: 'Unidad: ${viaje['unidad'] ?? 'N/A'}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _InfoFilaMovil({
    required IconData icono,
    required String texto,
    Color? colorResalte,
  }) {
    return Row(
      children: [
        Icon(icono, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              color: colorResalte ?? Colors.black87,
              fontWeight: colorResalte != null
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTablaWeb() {
    return Container(
      width: double.infinity,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFF4F7FE),
              ),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(
                  label: Text(
                    'Folio',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Fecha / Hora',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Material',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Banco',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Destino',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Unidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Volumen',
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
              ],
              rows: _viajes.map((viaje) {
                final bool enTransito = viaje['estatus'] == 'En tránsito';
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        viaje['folio_suministro'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(_formatearFecha(viaje['fecha_hora'] ?? ''))),
                    DataCell(Text(viaje['nombre_material'] ?? 'N/A')),
                    DataCell(Text(viaje['nombre_banco'] ?? 'N/A')),
                    DataCell(Text(viaje['nombre_destino'] ?? 'N/A')),
                    DataCell(Text(viaje['unidad'] ?? 'N/A')),
                    DataCell(
                      Text(
                        '${viaje['cantidad_m3']} m³',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: enTransito
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          viaje['estatus'] ?? 'N/A',
                          style: TextStyle(
                            color: enTransito
                                ? Colors.orange[800]
                                : Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
