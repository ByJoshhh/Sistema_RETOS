import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'registro_imagenes_screen.dart';
import '../../config.dart'; // <-- 1. Importamos el switch maestro

class SuministroScreen extends StatefulWidget {
  const SuministroScreen({super.key});

  @override
  State<SuministroScreen> createState() => _SuministroScreenState();
}

class _SuministroScreenState extends State<SuministroScreen> {
  // --- LISTAS DE CATÁLOGOS ---
  List<dynamic> _bancos = [];
  List<dynamic> _materiales = [];
  List<dynamic> _destinos = [];
  List<dynamic> _unidades = [];
  List<dynamic> _residentes = [];
  List<dynamic> _sindicatos = [];

  // --- SELECCIONES ---
  int? _selectedBanco;
  int? _selectedMaterial;
  int? _selectedDestino;
  int? _selectedUnidad;
  int? _selectedResidente;
  int? _selectedSindicato;

  final TextEditingController _cantidadController = TextEditingController();
  bool _isLoadingCatalogos = true;
  String _nombreChecador = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _inicializarYScanner();
  }

  // 1. Leemos la sesión y disparamos la carga de datos
  Future<void> _inicializarYScanner() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreChecador = prefs.getString('nombre_completo') ?? 'Checador';
    });
    _cargarCatalogos();
  }

  // 2. Carga de catálogos con SEGURIDAD (TOKEN)
  Future<void> _cargarCatalogos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token_seguridad');

      if (token == null) {
        _mostrarMensaje('Sesión no válida', Colors.red);
        return;
      }

      final url = Uri.parse('${Config.apiUrl}/api/catalogos');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        setState(() {
          _bancos = data['datos']['bancos'] ?? [];
          _materiales = data['datos']['materiales'] ?? [];
          _destinos = data['datos']['destinos'] ?? [];
          _unidades = data['datos']['unidades'] ?? [];
          _residentes = data['datos']['residentes'] ?? [];
          _sindicatos = data['datos']['sindicatos'] ?? [];
          _isLoadingCatalogos = false;
        });
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión con el servidor', Colors.red);
      setState(() => _isLoadingCatalogos = false);
    }
  }

  // 3. Navegación a la pantalla de fotos (Evidencia)
  void _irAPantallaFotos() {
    if (_selectedBanco == null ||
        _selectedMaterial == null ||
        _selectedDestino == null ||
        _selectedUnidad == null ||
        _selectedResidente == null ||
        _selectedSindicato == null ||
        _cantidadController.text.isEmpty) {
      _mostrarMensaje('Por favor, completa todos los campos', Colors.orange);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroImagenesScreen(
          idBanco: _selectedBanco!,
          idMaterial: _selectedMaterial!,
          idResidente: _selectedResidente!,
          idDestino: _selectedDestino!,
          idSindicato: _selectedSindicato!,
          idUnidad: _selectedUnidad!,
          cantidadM3: double.tryParse(_cantidadController.text) ?? 0,
        ),
      ),
    );
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
      appBar: AppBar(
        title: const Text(
          'Registro de Suministro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1C2229),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoadingCatalogos
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5D6A)),
            )
          // --- ANIMACIÓN DE ENTRADA SUAVE ---
          : TweenAnimationBuilder(
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
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 25),
                    _buildFormCard(),
                    const SizedBox(height: 35),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4A5D6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nombreChecador,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 5),
              const Text(
                'OPERACIÓN EN CAMPO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles del Viaje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2229),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Complete todos los campos para continuar.',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
          const SizedBox(height: 25),

          _buildInputGroup(
            'Volumen a Suministrar',
            Icons.straighten,
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _getModernInputDecoration(
                'Ej. 14.5 m³',
                Icons.straighten,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.black12, thickness: 1),
          ),

          _buildDropdownGroup(
            'Banco Origen',
            Icons.landscape,
            _selectedBanco,
            _bancos,
            'id_banco',
            'nombre_banco',
            (v) => setState(() => _selectedBanco = v),
          ),
          const SizedBox(height: 20),

          _buildDropdownGroup(
            'Material',
            Icons.layers,
            _selectedMaterial,
            _materiales,
            'id_material',
            'nombre_material',
            (v) => setState(() => _selectedMaterial = v),
          ),
          const SizedBox(height: 20),

          _buildDropdownGroup(
            'Residente',
            Icons.person,
            _selectedResidente,
            _residentes,
            'id_residente',
            'nombre_completo',
            (v) => setState(() => _selectedResidente = v),
          ),
          const SizedBox(height: 20),

          _buildDropdownGroup(
            'Destino',
            Icons.place,
            _selectedDestino,
            _destinos,
            'id_destino',
            'nombre_destino',
            (v) => setState(() => _selectedDestino = v),
          ),
          const SizedBox(height: 20),

          _buildDropdownGroup(
            'Sindicato',
            Icons.group,
            _selectedSindicato,
            _sindicatos,
            'id_sindicato',
            'nombre_sindicato',
            (v) => setState(() => _selectedSindicato = v),
          ),
          const SizedBox(height: 20),

          _buildDropdownGroup(
            'Unidad / Camión',
            Icons.local_shipping,
            _selectedUnidad,
            _unidades,
            'id_unidad',
            'placas_o_num',
            (v) => setState(() => _selectedUnidad = v),
          ),
        ],
      ),
    );
  }

  // --- DECORACIÓN MODERNA REUTILIZABLE PARA TODOS LOS INPUTS ---
  InputDecoration _getModernInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
    );
  }

  Widget _buildInputGroup(String label, IconData icon, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.blueGrey,
            ),
          ),
        ),
        field,
      ],
    );
  }

  Widget _buildDropdownGroup(
    String label,
    IconData icon,
    int? val,
    List items,
    String idK,
    String nameK,
    Function(int?) onCh,
  ) {
    return _buildInputGroup(
      label,
      icon,
      DropdownButtonFormField<int>(
        value: val,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.blueGrey,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(20),
        items: items
            .map(
              (i) => DropdownMenuItem<int>(
                value: i[idK],
                child: Text(
                  i[nameK].toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: onCh,
        decoration: _getModernInputDecoration('Seleccionar...', icon),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
        onPressed: _irAPantallaFotos,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CONTINUAR A EVIDENCIA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
