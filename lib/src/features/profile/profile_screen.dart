// lib/src/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';

/// Pantalla para ver y editar el perfil del usuario (Mockup 5).
/// Implementa RF04 (UI) y RF02 (Lógica de Logout).
///
/// Convertido a [StatefulWidget] para gestionar el estado de carga
/// del botón de logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // NUEVO: Instancia del servicio de autenticación
  final AuthService _authService = AuthService();

  // NUEVO: Estado de carga para el botón de logout
  bool _isLoading = false;

  // NUEVO: Controladores para los campos del perfil (RF04)
  // (Por ahora, los inicializamos vacíos. En el futuro, los cargaremos
  // desde la API.)
  final _nombreController = TextEditingController(text: "Nombre actual");
  final _emailController = TextEditingController(text: "email@actual.com");

  /// NUEVO: Lógica para manejar el cierre de sesión (RF02)
  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    // (Buena Práctica) Guardar el contexto del Navigator antes del 'await'
    final nav = Navigator.of(context);

    try {
      // 1. Llama al servicio para borrar el token seguro
      await _authService.logout();

      // 2. (Éxito) Navegación profesional post-logout
      // Usamos 'pushAndRemoveUntil' para limpiar *toda* la pila de navegación.
      // Esto previene que el usuario pueda usar el botón "atrás" de Android
      // para volver a la HomeScreen después de cerrar sesión.
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // 'false' elimina todas las rutas
      );
    } catch (e) {
      // (En caso de que 'logout' falle, ej. no pueda borrar el token)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        // NUEVO: Eliminamos la flecha de "atrás" automática,
        // ya que esta es una pantalla de nivel superior en la barra de pestañas.
        automaticallyImplyLeading: false,
      ),
      // NUEVO: Usamos SingleChildScrollView para evitar que el teclado
      // tape los campos de texto (Pixel overflow)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Avatar (Mockup 5) ---
            const Center(
              child: CircleAvatar(
                radius: 60,
                // (En el futuro, aquí iría la imagen del usuario)
                child: Icon(Icons.person, size: 60),
              ),
            ),
            const SizedBox(height: 32.0),

            // --- Formulario RF04 (Mockup 5) ---
            Text('Nombre de Usuario', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8.0),
            _buildInputField(
              controller: _nombreController,
              labelText: 'Nombre actual',
              // (Lo deshabilitamos por ahora, hasta implementar la lógica RF04)
              enabled: false,
            ),
            
            const SizedBox(height: 16.0),
            
            Text('Email', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8.0),
            _buildInputField(
              controller: _emailController,
              labelText: 'Email actual',
              enabled: false, // Deshabilitado
            ),

            const SizedBox(height: 32.0),

            // --- Botón Guardar Cambios (RF04) ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              // (Deshabilitado por ahora)
              onPressed: null,
              child: const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 16.0),

            // --- Botón Cerrar Sesión (RF02) ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700], // Color rojo para acción destructiva
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: _isLoading ? null : _handleLogout,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Cerrar Sesión',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Widget auxiliar para construir los campos de texto
  // (Reutilizamos el estilo de los mockups)
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder( // Estilo cuando está deshabilitado
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
      ),
    );
  }
}