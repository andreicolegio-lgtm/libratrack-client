// lib/src/features/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 
// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:libratrack_client/src/core/l10n/app_localizations.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _authService = AuthService();
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) { return; }
    setState(() { _isLoading = true; });

    final navContext = Navigator.of(context);
    final msgContext = ScaffoldMessenger.of(context);

    try {
      final PerfilUsuario nuevoUsuario = await _authService.register(
        _usernameController.text, 
        _emailController.text, 
        _passwordController.text
      );

      if (!mounted) return;
      setState(() { _isLoading = false; });

      // (Usamos el l10n capturado)
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        '¡Registro exitoso! Bienvenido, ${nuevoUsuario.username}. Por favor, inicia sesión.', 
        isError: false
      );
      
      navContext.pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        e.toString().replaceFirst("Exception: ", ""), 
        isError: true
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- ¡NUEVO! Obtenemos las traducciones ---
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                
                Text(
                  l10n.appTitle, // <-- TRADUCIDO
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 48), 
                ),
                const SizedBox(height: 64.0), 

                _buildInputField(
                  context,
                  controller: _usernameController,
                  labelText: l10n.registerUsernameLabel, // <-- TRADUCIDO
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) { return l10n.registerUsernameRequired; } // <-- TRADUCIDO
                    if (value.trim().length < 4) { return l10n.registerUsernameLength; } // <-- TRADUCIDO
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                _buildInputField(
                  context,
                  controller: _emailController,
                  labelText: l10n.loginEmailLabel, // <-- TRADUCIDO
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) { return l10n.loginEmailRequired; } // <-- TRADUCIDO
                    if (!value.contains('@') || !value.contains('.')) { return l10n.loginEmailInvalid; } // <-- TRADUCIDO
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                _buildInputField(
                  context,
                  controller: _passwordController,
                  labelText: l10n.loginPasswordLabel, // <-- TRADUCIDO
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) { return l10n.loginPasswordRequired; } // <-- TRADUCIDO
                    if (value.length < 8) { return l10n.registerPasswordLength; } // <-- TRADUCIDO
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.registerTitle, // <-- TRADUCIDO
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 16.0),
                
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pop(); 
                  },
                  child: Text(
                    l10n.registerLoginPrompt, // <-- TRADUCIDO
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (Widget _buildInputField sin cambios)
  Widget _buildInputField(
    BuildContext context,
    {
      required TextEditingController controller,
      required String labelText,
      TextInputType keyboardType = TextInputType.text,
      bool isPassword = false,
      String? Function(String?)? validator,
    }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      style: Theme.of(context).textTheme.bodyMedium, 
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}