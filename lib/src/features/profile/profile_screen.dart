// lib/src/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/core/services/user_service.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 
import 'package:libratrack_client/src/features/auth/login_screen.dart';

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
  bool _isScreenLoading = true; // Para la carga inicial de la página
  String? _loadingError;
  bool _isLoadingUpdate = false; // Para el botón "Guardar Cambios"
  bool _isLoadingPasswordChange = false; // NUEVO: Para "Cambiar Contraseña"
  bool _isLoadingLogout = false; // Para el botón "Cerrar Sesión"

  // --- Controladores y Keys del Formulario (RF04) ---
  
  // NUEVO: Llave para el formulario de actualización de perfil (username)
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  String _originalUsername = "";

  // NUEVO: Llave y controladores para el formulario de cambio de contraseña
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();

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
      final PerfilUsuario perfil = await _userService.getMiPerfil();
      if (!mounted) return;
      _nombreController.text = perfil.username;
      _emailController.text = perfil.email;
      _originalUsername = perfil.username; 
      setState(() {
        _isScreenLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingError = e.toString().replaceFirst("Exception: ", "");
        _isScreenLoading = false;
      });
    }
  }

  // ===================================================================
  // LÓGICA DE ACTUALIZACIÓN DE PERFIL (Username)
  // ===================================================================

  Future<void> _handleUpdateProfile() async {
    // 1. Validar SÓLO el formulario de perfil
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    final String nuevoUsername = _nombreController.text.trim();
    if (nuevoUsername == _originalUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No has realizado ningún cambio.'), backgroundColor: Colors.grey),
      );
      return;
    }

    setState(() {
      _isLoadingUpdate = true;
    });
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
      setState(() {
        _isLoadingUpdate = false;
      });
      msgContext.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
      );
    }
  }
  
  // ===================================================================
  // NUEVA LÓGICA DE CAMBIO DE CONTRASEÑA (RF04)
  // ===================================================================

  Future<void> _handleChangePassword() async {
    // 1. Validar SÓLO el formulario de contraseña
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    // 2. Iniciar el estado de carga
    setState(() {
      _isLoadingPasswordChange = true;
    });

    final msgContext = ScaffoldMessenger.of(context);
    final String actual = _contrasenaActualController.text;
    final String nueva = _nuevaContrasenaController.text;

    try {
      // 3. Llamar al servicio que acabamos de crear
      await _userService.changePassword(actual, nueva);

      // 4. (ÉXITO) Limpiar campos y notificar
      if (!mounted) return;
      setState(() {
        _isLoadingPasswordChange = false;
        _contrasenaActualController.clear();
        _nuevaContrasenaController.clear();
      });
      
      // Asegurarse de que el foco se quite de los campos
      FocusScope.of(context).unfocus(); 

      msgContext.showSnackBar(
        const SnackBar(content: Text('¡Contraseña actualizada con éxito!'), backgroundColor: Colors.green),
      );

    } catch (e) {
      // 5. (ERROR) Mostrar error de la API (ej. "La contraseña actual es incorrecta")
      if (!mounted) return;
      setState(() {
        _isLoadingPasswordChange = false;
      });
      
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  // ===================================================================
  // LÓGICA DE CIERRE DE SESIÓN
  // ===================================================================

  Future<void> _handleLogout() async {
    setState(() {
      _isLoadingLogout = true;
    });
    final nav = Navigator.of(context);
    try {
      await _authService.logout();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLogout = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  // ===================================================================
  // LIMPIEZA
  // ===================================================================

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _contrasenaActualController.dispose(); // NUEVO
    _nuevaContrasenaController.dispose(); // NUEVO
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el perfil:\n$_loadingError',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // (ÉXITO) Muestra el formulario con los datos
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // --- Avatar ---
          const Center(
            child: CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 60),
            ),
          ),
          const SizedBox(height: 32.0),

          // --- Formulario de Perfil (Username) ---
          Form(
            key: _profileFormKey, // NUEVO: Llave de formulario 1
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(
                  controller: _nombreController,
                  labelText: 'Nombre de Usuario',
                  enabled: _isAnyLoading(),
                  validator: (value) { // NUEVO: Validación
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
                  enabled: false, // El email no se puede cambiar
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

          // --- Divisor ---
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),

          // --- Formulario de Cambio de Contraseña ---
          Text(
            'Cambiar Contraseña',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          Form(
            key: _passwordFormKey, // NUEVO: Llave de formulario 2
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(
                  controller: _contrasenaActualController,
                  labelText: 'Contraseña actual',
                  enabled: _isAnyLoading(),
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
                  enabled: _isAnyLoading(),
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
                    backgroundColor: Colors.grey[700], // Color distinto
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
          
          const SizedBox(height: 32.0),

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

  /// NUEVO: Helper para deshabilitar botones si CUALQUIER acción está en curso
  bool _isAnyLoading() {
    return _isLoadingUpdate || _isLoadingPasswordChange || _isLoadingLogout;
  }

  /// NUEVO: Helper para los spinners de los botones
  Widget _buildSmallSpinner() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }

  // Widget auxiliar para construir los campos de texto
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    bool isPassword = false, // NUEVO
    String? Function(String?)? validator, // NUEVO
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: isPassword, // NUEVO
      validator: validator, // NUEVO
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
        // NUEVO: Bordes de error y foco para la validación
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