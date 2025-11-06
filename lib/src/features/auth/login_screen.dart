// lib/src/features/auth/login_screen.dart
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

  // NUEVO: Clave global para identificar y validar el formulario.
  // Esta clave nos permite acceder al estado del 'Form' desde cualquier parte
  // de este widget (como el botón de 'ElevatedButton').
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Método de lógica de negocio llamado al pulsar el botón "Iniciar Sesión".
  /// Implementa la "mejor práctica" de 'BuildContext' asíncrono.
  Future<void> _handleLogin() async {

    // NUEVO: Paso 1 - Validar el formulario.
    // Usamos la _formKey para decirle al 'Form' que ejecute todos los 'validator'
    // de sus campos 'TextFormField'.
    // Si 'validate()' devuelve 'false', algún campo no es válido.
    if (!_formKey.currentState!.validate()) {
      return; // Detenemos la ejecución si la validación falla.
    }

    // Si la validación es exitosa, continuamos...

    // 2. Mostrar la rueda de carga
    setState(() {
      _isLoading = true;
    });

    // 3. (Mejor Práctica) Guardar 'context' en variables locales
    final navContext = Navigator.of(context);
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // 4. Llamar al servicio de login.
      // (El 'AuthService' se encargará de guardar el token internamente)
      await _authService.login(
        _emailController.text, // .text ya está validado (no está vacío)
        _passwordController.text, // .text ya está validado (no está vacío)
      );
      
      // 5. (Éxito) Navegar a la pantalla principal.
      navContext.pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } catch (e) {
      // 6. (Error) Ocultar la rueda de carga
      // (NUEVO: Hacemos el setState solo si el widget sigue "montado")
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // 7. Mostrar el mensaje de error de la API
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red, // Color para errores
        ),
      );
    }
  }

  // NUEVO: Nos aseguramos de limpiar los controladores cuando
  // el widget se destruye para liberar memoria.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          // NUEVO: Envolvemos la columna en un widget 'Form'
          // y le asignamos nuestra clave global '_formKey'.
          child: Form(
            key: _formKey,
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
                    // NUEVO: Función de validación
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El email es obligatorio.';
                      }
                      // Validación simple de email (mejora futura: regex)
                      if (!value.contains('@') || !value.contains('.')) {
                         return 'Por favor, introduce un email válido.';
                      }
                      return null; // 'null' significa que es válido
                    },
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
                    // NUEVO: Función de validación
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es obligatoria.';
                      }
                      // (En el futuro, podríamos añadir: 'value.length < 8')
                      return null; // 'null' significa que es válido
                    },
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
                        ? const CircularProgressIndicator(color: Colors.white)
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
      ),
    );
  }
}