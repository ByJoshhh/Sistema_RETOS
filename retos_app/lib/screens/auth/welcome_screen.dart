import 'package:flutter/material.dart';
import 'login_screen.dart'; // Ya no necesita ../ ni carpetas, solo el nombre porque viven juntos

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Column(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 80,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'WELCOME TO SYCORE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Registro de Entrega de Material\n\npor Transporte a Obra o Suministro',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 50),

                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A5D6A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Continuar',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  '© 2026 Tecnologico Superior De Poza Rica',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
