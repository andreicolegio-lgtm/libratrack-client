// lib/main.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';
import 'package:libratrack_client/src/features/home/home_screen.dart';

void main() {
  runApp(const LibraTrackApp());
}

/// Widget raíz de la aplicación.
class LibraTrackApp extends StatefulWidget {
  const LibraTrackApp({super.key});

  @override
  State<LibraTrackApp> createState() => _LibraTrackAppState();
}

class _LibraTrackAppState extends State<LibraTrackApp> {
  final AuthService _authService = AuthService();
  Future<String?>? _tokenCheckFuture;

  @override
  void initState() {
    super.initState();
    _tokenCheckFuture = _authService.getToken();
  }

  // --- CORREGIDO: Tema de la Aplicación para Consistencia ---
  ThemeData _buildDarkTheme() {
    const Color primaryColor = Colors.blue;
    const Color secondaryColor = Color(0xFF1E88E5); 
    const Color background = Color(0xFF121212);
    const Color surfaceColor = Color(0xFF1E1E1E); 

    return ThemeData(
      // 1. Color y Brillo
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background, 

      // 2. Tipografía (Consistencia en la Jerarquía)
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14.0, color: Colors.grey[300]),
        labelLarge: TextStyle(fontSize: 16.0, color: Colors.grey[500]),
      ),
      
      // 3. Estilo de Componentes
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      // CORREGIDO: Uso de 'CardThemeData' en lugar de 'CardTheme'
      cardTheme: const CardThemeData( 
        color: surfaceColor, 
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
      // CORREGIDO: Eliminamos la referencia obsoleta a 'background' en otros temas si existía.
      // Aquí está implícito y no causará el error.
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibraTrack',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: FutureBuilder<String?>(
        future: _tokenCheckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}