import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/registration_screen.dart';
import 'package:libratrack_client/src/features/home/home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para leer el texto de los campos
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController();
  
  // Instancia de nuestro servicio de autenticación
  final _authService = AuthService();
  // Variable de estado para mostrar la rueda de carga
  bool _isLoading = false;

  /// Método de lógica de negocio llamado al pulsar el botón "Iniciar Sesión".
  /// Implementa la "mejor práctica" de 'BuildContext' asíncrono.
  Future<void> _handleLogin() async {
    // 1. Mostrar la rueda de carga
    setState(() {
      _isLoading = true;
    });

    // 2. (Mejor Práctica) Guardar 'context' en variables locales
    // Esto evita la advertencia "Don't use 'BuildContext's across async gaps".
    // Nos aseguramos de que, si el usuario sale de la pantalla mientras
    // la API responde, no intentemos usar un 'context' que ya no existe.
    final navContext = Navigator.of(context);
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // 3. Llamar al servicio de login.
      // El 'AuthService' se encargará de guardar el token internamente.
      await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      // 4. (Éxito) Navegar a la pantalla principal.
      // Usamos 'pushReplacement' para que el usuario no pueda "volver"
      // a la pantalla de Login una vez autenticado.
      navContext.pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } catch (e) {
      // 5. (Error) Ocultar la rueda de carga
      setState(() {
        _isLoading = false;
      });
      
      // 6. Mostrar el mensaje de error de la API (ej. "Usuario o contraseña incorrectos")
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red, // Color para errores
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView( // Permite scroll si el teclado tapa
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                
                const Text(
                  'LibraTrack',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48.0),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true, // Oculta el texto
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Botón "Iniciar Sesión"
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  // Llama a _handleLogin. Se deshabilita si _isLoading es true
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      // Muestra rueda de carga si está ocupado
                      ? const CircularProgressIndicator(color: Colors.white)
                      // Muestra el texto si está libre
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 16.0),
                
                // Enlace a "Registro"
                TextButton(
                  onPressed: _isLoading ? null : () { // Deshabilitado si está cargando
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                    );
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: Colors.blue[300]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}