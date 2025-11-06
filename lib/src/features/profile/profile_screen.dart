// lib/src/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/core/services/user_service.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 
import 'package:libratrack_client/src/features/auth/login_screen.dart';
// --- NUEVA IMPORTACIÓN ---
import 'package:libratrack_client/src/features/moderacion/moderacion_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- Servicios ---
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // --- Estado de la UI ---
  bool _isScreenLoading = true;
  String? _loadingError;
  bool _isLoadingUpdate = false;
  bool _isLoadingPasswordChange = false;
  bool _isLoadingLogout = false;

  // --- Formulario de Perfil (Username) ---
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  String _originalUsername = "";

  // --- Formulario de Cambio de Contraseña ---
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();

  // --- NUEVO: Estado de Roles (RF03) ---
  String? _userRol; // Almacena el rol del usuario (ej. "ROLE_MODERADOR")

  // ===================================================================
  // LÓGICA DE CARGA DE DATOS
  // ===================================================================

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      // 1. Llama al servicio (que devuelve PerfilUsuario)
      final PerfilUsuario perfil = await _userService.getMiPerfil();
      if (!mounted) return;
      
      // 2. Rellena los controladores
      _nombreController.text = perfil.username;
      _emailController.text = perfil.email;
      _originalUsername = perfil.username; 
      
      // 3. NUEVO: Almacena el rol del usuario
      setState(() {
        _userRol = perfil.rol; // <-- Aquí guardamos el rol
        _isScreenLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString().replaceFirst("Exception: ", "");
          _isScreenLoading = false;
        });
      }
    }
  }

  // ===================================================================
  // LÓGICA DE ACTUALIZACIÓN DE PERFIL (Username)
  // ===================================================================

  Future<void> _handleUpdateProfile() async {
    // ... (código existente de _handleUpdateProfile sin cambios)
    if (!_profileFormKey.currentState!.validate()) { return; }
    final String nuevoUsername = _nombreController.text.trim();
    if (nuevoUsername == _originalUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No has realizado ningún cambio.'), backgroundColor: Colors.grey),
      );
      return;
    }
    setState(() { _isLoadingUpdate = true; });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      final PerfilUsuario perfilActualizado = await _userService.updateMiPerfil(nuevoUsername);
      if (!mounted) return;
      setState(() {
        _nombreController.text = perfilActualizado.username; 
        _originalUsername = perfilActualizado.username;
        _isLoadingUpdate = false;
      });
      msgContext.showSnackBar(
        const SnackBar(content: Text('¡Nombre de usuario actualizado!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingUpdate = false; });
      msgContext.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
      );
    }
  }
  
  // ===================================================================
  // LÓGICA DE CAMBIO DE CONTRASEÑA
  // ===================================================================

  Future<void> _handleChangePassword() async {
    // ... (código existente de _handleChangePassword sin cambios)
    if (!_passwordFormKey.currentState!.validate()) { return; }
    setState(() { _isLoadingPasswordChange = true; });
    final msgContext = ScaffoldMessenger.of(context);
    final String actual = _contrasenaActualController.text;
    final String nueva = _nuevaContrasenaController.text;
    try {
      await _userService.changePassword(actual, nueva);
      if (!mounted) return;
      setState(() {
        _isLoadingPasswordChange = false;
        _contrasenaActualController.clear();
        _nuevaContrasenaController.clear();
      });
      FocusScope.of(context).unfocus(); 
      msgContext.showSnackBar(
        const SnackBar(content: Text('¡Contraseña actualizada con éxito!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingPasswordChange = false; });
      msgContext.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
      );
    }
  }

  // ===================================================================
  // LÓGICA DE CIERRE DE SESIÓN
  // ===================================================================

  Future<void> _handleLogout() async {
    // ... (código existente de _handleLogout sin cambios)
    setState(() { _isLoadingLogout = true; });
    final nav = Navigator.of(context);
    try {
      await _authService.logout();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingLogout = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  // --- NUEVO MÉTODO DE NAVEGACIÓN ---
  
  /// Navega al panel de moderación
  void _goToModeracionPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModeracionPanelScreen(),
      ),
    );
  }

  // ===================================================================
  // LIMPIEZA
  // ===================================================================

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    super.dispose();
  }

  // ===================================================================
  // INTERFAZ DE USUARIO (UI)
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isScreenLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center( /* ... (código de error sin cambios) ... */ );
    }

    // (ÉXITO) Muestra el formulario con los datos
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ... (Avatar y Formulario de Perfil sin cambios) ...
          const Center(
            child: CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 60),
            ),
          ),
          const SizedBox(height: 32.0),
          Form(
            key: _profileFormKey,
            child: Column( /* ... (Campos de Username y Email sin cambios) ... */
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(
                  controller: _nombreController,
                  labelText: 'Nombre de Usuario',
                  enabled: !_isAnyLoading(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre de usuario no puede estar vacío.';
                    }
                    if (value.trim().length < 4) {
                      return 'Debe tener al menos 4 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildInputField(
                  controller: _emailController,
                  labelText: 'Email',
                  enabled: false,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  onPressed: _isAnyLoading() ? null : _handleUpdateProfile, 
                  child: _isLoadingUpdate
                      ? _buildSmallSpinner()
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
          
          // ... (Divisor y Formulario de Contraseña sin cambios) ...
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),
          Text(
            'Cambiar Contraseña',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Form(
            key: _passwordFormKey,
            child: Column( /* ... (Campos de Contraseña sin cambios) ... */
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(
                  controller: _contrasenaActualController,
                  labelText: 'Contraseña actual',
                  enabled: !_isAnyLoading(),
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña actual es obligatoria.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildInputField(
                  controller: _nuevaContrasenaController,
                  labelText: 'Nueva contraseña',
                  enabled: !_isAnyLoading(),
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La nueva contraseña es obligatoria.';
                    }
                    if (value.length < 8) {
                      return 'Debe tener al menos 8 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  onPressed: _isAnyLoading() ? null : _handleChangePassword,
                  child: _isLoadingPasswordChange
                      ? _buildSmallSpinner()
                      : const Text(
                          'Cambiar Contraseña',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
          
          // --- NUEVO: Botón de Panel de Moderación (RF03) ---
          // Comprueba si el rol del usuario (guardado en _userRol)
          // es el de Moderador.
          if (_userRol == 'ROLE_MODERADOR') ...[
            const SizedBox(height: 32.0), // Espacio extra
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700], // Color distintivo (Naranja)
                foregroundColor: Colors.black, // Texto oscuro para contraste
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: _isAnyLoading() ? null : _goToModeracionPanel,
              child: const Text(
                'Panel de Moderación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          // --- FIN DEL CÓDIGO NUEVO ---
          
          const SizedBox(height: 16.0),

          // --- Botón Cerrar Sesión (RF02) ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            onPressed: _isAnyLoading() ? null : _handleLogout,
            child: _isLoadingLogout
                ? _buildSmallSpinner()
                : const Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Helpers de UI (sin cambios) ---

  bool _isAnyLoading() {
    return _isLoadingUpdate || _isLoadingPasswordChange || _isLoadingLogout;
  }

  Widget _buildSmallSpinner() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      // ... (código de _buildInputField sin cambios)
      controller: controller,
      enabled: enabled,
      obscureText: isPassword,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.grey[400],
      ),
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey[800]!),
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