import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';
import 'package:libratrack_client/src/features/home/home_screen.dart';

void main() {
  runApp(const LibraTrackApp());
}

/// Widget raíz de la aplicación.
///
/// Se convierte en un [StatefulWidget] para poder gestionar el estado
/// de "comprobación de autenticación" al inicio de la app.
class LibraTrackApp extends StatefulWidget {
  const LibraTrackApp({super.key});

  @override
  State<LibraTrackApp> createState() => _LibraTrackAppState();
}

class _LibraTrackAppState extends State<LibraTrackApp> {
  final AuthService _authService = AuthService();
  
  /// Un [Future] que representa la comprobación del token.
  /// Lo guardamos en el estado para evitar que se llame múltiples veces
  /// cada vez que el widget se reconstruye.
  Future<String?>? _tokenCheckFuture;

  @override
  void initState() {
    super.initState();
    // 1. Al iniciar la app, llamamos UNA VEZ al método para comprobar el token
    _tokenCheckFuture = _authService.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibraTrack',
      debugShowCheckedModeBanner: false, // Oculta la cinta de "Debug"
      
      // Tema Oscuro (Mejor Práctica)
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      
      /// Lógica de Enrutamiento Inicial (Splash Screen)
      ///
      /// Usamos un [FutureBuilder] para mostrar una pantalla de carga
      /// mientras comprobamos si existe un token guardado.
      home: FutureBuilder<String?>(
        future: _tokenCheckFuture, // El 'Future' que estamos esperando
        builder: (context, snapshot) {
          
          /// Caso 1: Aún estamos comprobando (esperando el 'Future').
          /// Mostramos una pantalla de carga (Splash Screen).
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          /// Caso 2: Comprobación terminada y SÍ HAY un token.
          /// 'snapshot.hasData' es true y 'snapshot.data' (el token) no es nulo.
          if (snapshot.hasData && snapshot.data != null) {
            // El usuario ya está logueado -> Ve directo al Catálogo
            return const HomeScreen();
          }
          
          /// Caso 3: Comprobación terminada y NO HAY token (o hay error).
          // El usuario no está logueado -> Ve al Login
          return const LoginScreen();
        },
      ),
    );
  }
}