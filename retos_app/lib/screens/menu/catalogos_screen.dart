import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dialogo_nueva_unidad.dart';
import '../../config.dart'; // <-- 1. Importamos el switch maestro

class CatalogosScreen extends StatelessWidget {
  const CatalogosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administración de Catálogos',
            style: TextStyle(
              color: Color(0xFF2B3674),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              indicatorColor: const Color(0xFF4318FF),
              indicatorWeight: 4,
              labelColor: const Color(0xFF4318FF),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.local_shipping), text: 'Unidades'),
                Tab(icon: Icon(Icons.layers), text: 'Materiales'),
                Tab(icon: Icon(Icons.landscape), text: 'Bancos'),
                Tab(icon: Icon(Icons.domain), text: 'Destinos'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Expanded(
            child: TabBarView(
              children: [
                _TabUnidades(),
                Center(
                  child: Text(
                    'Catálogo de Materiales (En construcción)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Center(
                  child: Text(
                    'Catálogo de Bancos (En construcción)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Center(
                  child: Text(
                    'Catálogo de Destinos (En construcción)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabUnidades extends StatefulWidget {
  const _TabUnidades();

  @override
  State<_TabUnidades> createState() => _TabUnidadesState();
}

class _TabUnidadesState extends State<_TabUnidades> {
  List<dynamic> _unidades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
  }

  Future<void> _cargarUnidades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token_seguridad');

      if (token == null) return;

      // --- 2. USAMOS EL ARCHIVO MAESTRO ---
      final url = Uri.parse('${Config.apiUrl}/api/unidades');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _unidades = data['datos'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total de Camiones: ${_unidades.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4318FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Agregar Unidad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DialogoNuevaUnidad(),
                  ).then((creado) {
                    if (creado == true) _cargarUnidades();
                  });
                },
              ),
            ],
          ),
          const Divider(height: 30),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4318FF)),
                  )
                : _unidades.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no hay unidades registradas.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFF4F7FE),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'ID',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B3674),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Placa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B3674),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Capacidad (m³)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B3674),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Acciones',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B3674),
                            ),
                          ),
                        ),
                      ],
                      rows: _unidades.map((u) {
                        return DataRow(
                          cells: [
                            DataCell(Text(u['id_unidad'].toString())),
                            DataCell(
                              Text(
                                u['placa'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${u['capacidad_m3'] ?? 0} m³',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
