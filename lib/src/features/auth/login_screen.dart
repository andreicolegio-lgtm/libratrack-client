// Archivo: lib/src/features/auth/login_screen.dart
// (¡ACTUALIZADO - SPRINT 10: GOOGLE SIGN-IN!)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/registration_screen.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Maneja el login con Email/Contraseña
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final msgContext = ScaffoldMessenger.of(context);

    try {
      await authService.login(
        _emailController.text,
        _passwordController.text,
      );
      // Éxito: AuthWrapper navega
    } on ApiException catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; }); 
        SnackBarHelper.showTopSnackBar(msgContext, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: ${e.toString()}', isError: true);
      }
    }
  }

  // --- ¡NUEVO MÉTODO (ID: QA-091)! ---
  /// Maneja el login con Google
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final msgContext = ScaffoldMessenger.of(context);

    try {
      await authService.signInWithGoogle();
      // Éxito: AuthWrapper navega
    } on ApiException catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        SnackBarHelper.showTopSnackBar(msgContext, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: ${e.toString()}', isError: true);
      }
    }
  }
  // ---

  void _goToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bienvenido a LibraTrack',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // --- Campo de Email ---
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, introduce tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Campo de Contraseña ---
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, introduce tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- Botón de Login ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Iniciar Sesión'),
                  ),
                  const SizedBox(height: 24),

                  // --- ¡NUEVO DIVISOR (ID: QA-091)! ---
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[700])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text("O", style: textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- ¡NUEVO BOTÓN DE GOOGLE (ID: QA-091)! ---
                  OutlinedButton.icon(
                    icon: const Text('G'),
                    label: const Text('Continuar con Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                  ),
                  // ---

                  const SizedBox(height: 24),

                  // --- Botón de Registro ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: _isLoading ? null : _goToRegistration,
                        child: const Text('Regístrate'),
                      ),
                    ],
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