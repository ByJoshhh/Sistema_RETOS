import 'package:flutter/material.dart';
import './screens/auth/welcome_screen.dart'; // El ./ le dice "busca desde aquí"

void main() {
  runApp(const RetosApp());
}

class RetosApp extends StatelessWidget {
  const RetosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WELCOME TO SYCORE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
    );
  }
}
