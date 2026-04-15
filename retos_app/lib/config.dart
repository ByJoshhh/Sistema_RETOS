// lib/config.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Config {
  // SWITCH MAESTRO
  // Ponlo en 'false' para trabajar en tu compu (Local)
  // Ponlo en 'true' ANTES de compilar para Netlify (Render)
  static const bool esProduccion = false;

  static String get apiUrl {
    if (esProduccion) {
      // --- NUBE (Render) ---
      return 'https://api-retos.onrender.com';
    } else {
      // --- LOCAL (Tu compu) ---
      if (kIsWeb) {
        return 'http://localhost:3000'; // Si corres en Chrome
      } else {
        // Si corres en emulador Android o celular físico
        try {
          if (Platform.isAndroid) return 'http://10.0.2.2:3000';
        } catch (e) {
          return 'http://localhost:3000';
        }
        return 'http://localhost:3000';
      }
    }
  }
}
