import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'admin_ui_components.dart';
import 'historial_viajes_screen.dart';
import 'grafica_viajes_widget.dart';
import 'catalogos_screen.dart'; // <-- IMPORTANTE: Asegúrate de haber creado este archivo

class AdminDashboardScreen extends StatefulWidget {
  final String nombre;
  final String rol;

  const AdminDashboardScreen({
    super.key,
    required this.nombre,
    required this.rol,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _indiceSeleccionado = 0;

  void _cerrarSesion() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _seleccionarMenu(int index, bool esMovil) {
    setState(() {
      _indiceSeleccionado = index;
    });
    if (esMovil) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double anchoPantalla = MediaQuery.of(context).size.width;
    final bool esEscritorio = anchoPantalla >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: esEscritorio
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF111C44),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                _obtenerTituloPantalla(),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              centerTitle: true,
            ),
      drawer: esEscritorio ? null : Drawer(child: _buildSidebar(esMovil: true)),
      body: Row(
        children: [
          if (esEscritorio) _buildSidebar(esMovil: false),
          Expanded(
            child: Column(
              children: [
                if (esEscritorio) _buildTopNavbar(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(esEscritorio ? 30.0 : 15.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.05, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: Container(
                        key: ValueKey<int>(_indiceSeleccionado),
                        width: double.infinity,
                        height: double.infinity,
                        child: _getPantallaContenido(anchoPantalla),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool esMovil}) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF111C44),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_center,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.rol.toUpperCase(),
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                BotonLateralAnimado(
                  icono: Icons.insert_chart_rounded,
                  titulo: 'Panel General',
                  estaSeleccionado: _indiceSeleccionado == 0,
                  onTap: () => _seleccionarMenu(0, esMovil),
                ),
                BotonLateralAnimado(
                  icono: Icons.compare_arrows_rounded,
                  titulo: 'Conciliaciones',
                  estaSeleccionado: _indiceSeleccionado == 1,
                  onTap: () => _seleccionarMenu(1, esMovil),
                ),
                BotonLateralAnimado(
                  icono: Icons.local_shipping_rounded,
                  titulo: 'Historial de Viajes',
                  estaSeleccionado: _indiceSeleccionado == 2,
                  onTap: () => _seleccionarMenu(2, esMovil),
                ),
                BotonLateralAnimado(
                  icono: Icons.category_rounded,
                  titulo: 'Catálogos',
                  estaSeleccionado: _indiceSeleccionado == 3,
                  onTap: () => _seleccionarMenu(3, esMovil),
                ),
                if (widget.rol.toLowerCase().contains('super') ||
                    widget.rol.toLowerCase().contains('admin'))
                  BotonLateralAnimado(
                    icono: Icons.manage_accounts_rounded,
                    titulo: 'Usuarios y Permisos',
                    estaSeleccionado: _indiceSeleccionado == 4,
                    onTap: () => _seleccionarMenu(4, esMovil),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _cerrarSesion,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavbar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              _obtenerTituloPantalla(),
              key: ValueKey<int>(_indiceSeleccionado),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.grey,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 15),
          const CircleAvatar(
            backgroundColor: Color(0xFF4A5D6A),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _obtenerTituloPantalla() {
    switch (_indiceSeleccionado) {
      case 0:
        return 'Resumen Operativo';
      case 1:
        return 'Conciliación de Materiales';
      case 2:
        return 'Historial Completo';
      case 3:
        return 'Administración de Catálogos';
      case 4:
        return 'Control de Usuarios';
      default:
        return 'Panel de Control';
    }
  }

  Widget _getPantallaContenido(double anchoPantalla) {
    switch (_indiceSeleccionado) {
      case 0:
        return _buildDashboardMockup(anchoPantalla);
      case 1:
        return const Center(
          child: Text(
            'Módulo de Conciliaciones (Próximamente)',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
        );
      case 2:
        return const HistorialViajesScreen();
      case 3:
        return const CatalogosScreen(); // <-- ¡AQUÍ ESTÁ LA MAGIA!
      default:
        return const Center(child: Text('Módulo en construcción'));
    }
  }

  Widget _buildDashboardMockup(double anchoPantalla) {
    const t1 = TarjetaEstadisticaAnimada(
      titulo: 'Viajes Hoy',
      valor: '24',
      icono: Icons.local_shipping,
      colorIcono: Colors.blue,
    );
    const t2 = TarjetaEstadisticaAnimada(
      titulo: 'Volumen (m³)',
      valor: '340.5',
      icono: Icons.layers,
      colorIcono: Colors.green,
    );
    const t3 = TarjetaEstadisticaAnimada(
      titulo: 'En Tránsito',
      valor: '5',
      icono: Icons.timer,
      colorIcono: Colors.orange,
    );
    const t4 = TarjetaEstadisticaAnimada(
      titulo: 'Alertas',
      valor: '0',
      icono: Icons.warning_rounded,
      colorIcono: Colors.red,
    );

    Widget layoutTarjetas;
    if (anchoPantalla >= 1100) {
      layoutTarjetas = const Row(
        children: [
          t1,
          SizedBox(width: 20),
          t2,
          SizedBox(width: 20),
          t3,
          SizedBox(width: 20),
          t4,
        ],
      );
    } else if (anchoPantalla >= 600) {
      layoutTarjetas = const Column(
        children: [
          Row(children: [t1, SizedBox(width: 20), t2]),
          SizedBox(height: 20),
          Row(children: [t3, SizedBox(width: 20), t4]),
        ],
      );
    } else {
      layoutTarjetas = const Column(
        children: [
          Row(children: [t1]),
          SizedBox(height: 15),
          Row(children: [t2]),
          SizedBox(height: 15),
          Row(children: [t3]),
          SizedBox(height: 15),
          Row(children: [t4]),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        layoutTarjetas,
        const SizedBox(height: 30),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const GraficaViajesSemanal(),
          ),
        ),
      ],
    );
  }
}
