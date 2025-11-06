// lib/src/features/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Controladores
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Servicios y estado
  final _authService = AuthService();
  bool _isLoading = false;

  // NUEVO: Clave global para identificar y validar el formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Método de lógica de negocio para manejar el registro (RF01)
  Future<void> _handleRegister() async {
    
    // NUEVO: Paso 1 - Validar el formulario.
    // Si 'validate()' devuelve 'false', los 'validator' de los
    // campos mostrarán los mensajes de error y detendremos la ejecución.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Si la validación es exitosa, continuamos...

    // 2. Mostrar la rueda de carga
    setState(() {
      _isLoading = true;
    });

    // 3. (Buena Práctica) Guardar 'context' en variables locales
    final navContext = Navigator.of(context);
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // 4. Llamar al servicio de registro
      await _authService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      // 5. (Éxito) Ocultar rueda de carga
      // (NUEVO: Comprobamos 'mounted' por si el usuario cerró la app
      // mientras la API respondía)
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // 6. Mostrar mensaje de éxito
      msgContext.showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Ya puedes iniciar sesión.'),
          backgroundColor: Colors.green,
        ),
      );

      // 7. Navegar de vuelta al Login
      navContext.pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

    } catch (e) {
      // 8. (Error) Ocultar rueda de carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // 9. Mostrar mensaje de error (ej. "Email ya existe")
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NUEVO: Limpiamos los controladores para liberar memoria
  // cuando el widget es destruido.
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NUEVO: Añadimos un AppBar para que el usuario pueda "volver"
      // visualmente al login si entra aquí por error.
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent, // Se integra con el fondo
        elevation: 0, // Sin sombra
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          // NUEVO: Envolvemos la columna en un widget 'Form'
          // y le asignamos nuestra clave global '_formKey'.
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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

                  // --- Campo de Nombre de Usuario ---
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de Usuario',
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
                        return 'El nombre de usuario es obligatorio.';
                      }
                      if (value.trim().length < 3) {
                         return 'Debe tener al menos 3 caracteres.';
                      }
                      return null; // Válido
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // --- Campo de Email ---
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
                      if (!value.contains('@') || !value.contains('.')) {
                         return 'Por favor, introduce un email válido.';
                      }
                      return null; // Válido
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // --- Campo de Contraseña ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
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
                      if (value.length < 8) {
                         return 'La contraseña debe tener al menos 8 caracteres.';
                      }
                      return null; // Válido
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // --- Botón de Registrarse ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleRegister, 
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Registrarse',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // --- Botón "Volver a Iniciar Sesión" ---
                  TextButton(
                    // NUEVO: Cambiamos 'Navigator.push' por 'Navigator.pop'
                    // Esta es la acción correcta, ya que solo queremos "cerrar"
                    // esta pantalla y volver a la anterior (que es 'LoginScreen').
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '¿Ya tienes cuenta? Inicia sesión',
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