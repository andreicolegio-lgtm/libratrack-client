// lib/src/features/profile/profile_screen.dart
import 'dart:io'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:cached_network_image/cached_network_image.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/core/utils/api_client.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/core/services/user_service.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 
import 'package:libratrack_client/src/features/auth/login_screen.dart';
import 'package:libratrack_client/src/features/moderacion/moderacion_panel_screen.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart'; 

/// --- ¡ACTUALIZADO (Sprint 3)! ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- Servicios ---
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

  // --- Estado ---
  bool _isScreenLoading = true;
  String? _loadingError;
  bool _isLoadingUpdate = false;
  bool _isLoadingPasswordChange = false;
  bool _isLoadingLogout = false;
  bool _isUploadingFoto = false; // <-- ¡NUEVO!
  
  // ¡NUEVO! Guardamos el perfil completo
  PerfilUsuario? _perfil;

  // --- Controladores ---
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  String _originalUsername = "";
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final PerfilUsuario perfil = await _userService.getMiPerfil();
      if (!mounted) return;
      
      // Actualizamos el estado con el objeto Perfil
      setState(() {
        _perfil = perfil;
        _nombreController.text = perfil.username;
        _emailController.text = perfil.email;
        _originalUsername = perfil.username; 
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
  
  // --- ¡NUEVO MÉTODO! (Petición 6) ---
  /// Lógica completa para elegir y subir la foto de perfil
  Future<void> _handlePickAndUploadFoto() async {
    if (_isAnyLoading()) return;

    // --- ¡CORRECCIÓN! ---
    // Capturamos el contexto ANTES del 'await'
    final msgContext = ScaffoldMessenger.of(context);
    // --- FIN DE LA CORRECCIÓN ---

    // 1. Elegir imagen de la galería
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return; // El usuario canceló
    
    setState(() { _isUploadingFoto = true; });

    try {
      final File imageFile = File(image.path);

      // 2. Subir la imagen a GCS (usando ApiClient)
      final String fotoUrl = await _apiClient.upload(imageFile);
      
      // 3. Enviar la nueva URL a nuestra API para guardarla
      final PerfilUsuario perfilActualizado = await _userService.updateFotoPerfil(fotoUrl);
      
      if (!mounted) return;
      
      // 4. Actualizar la UI
      setState(() {
        _perfil = perfilActualizado; // Actualiza el perfil con la nueva URL
        _isUploadingFoto = false;
      });
      SnackBarHelper.showTopSnackBar(msgContext, '¡Foto de perfil actualizada!', isError: false);

    } catch (e) {
      if (!mounted) return;
      setState(() { _isUploadingFoto = false; });
      SnackBarHelper.showTopSnackBar(msgContext, e.toString(), isError: true);
    }
  }
  
  // ... (Lógica _handleUpdateProfile, _handleChangePassword, _handleLogout, _goToModeracionPanel, _goToSettings sin cambios) ...
  Future<void> _handleUpdateProfile() async {
    if (!_profileFormKey.currentState!.validate()) { return; }
    final String nuevoUsername = _nombreController.text.trim();
    if (nuevoUsername == _originalUsername) {
      SnackBarHelper.showTopSnackBar(
        ScaffoldMessenger.of(context), 
        'No has realizado ningún cambio.', 
        isError: false
      );
      return;
    }
    setState(() { _isLoadingUpdate = true; });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      final PerfilUsuario perfilActualizado = await _userService.updateMiPerfil(nuevoUsername);
      if (!mounted) return;
      setState(() {
        _perfil = perfilActualizado; // Guardamos el perfil actualizado
        _nombreController.text = perfilActualizado.username; 
        _originalUsername = perfilActualizado.username;
        _isLoadingUpdate = false;
      });
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        '¡Nombre de usuario actualizado!', 
        isError: false
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingUpdate = false; });
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        e.toString().replaceFirst("Exception: ", ""), 
        isError: true
      );
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) { return; }
    setState(() { _isLoadingPasswordChange = true; });
    final msgContext = ScaffoldMessenger.of(context);
    final focusScope = FocusScope.of(context);
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
      focusScope.unfocus(); 
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        '¡Contraseña actualizada con éxito!', 
        isError: false
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingPasswordChange = false; });
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        e.toString().replaceFirst("Exception: ", ""), 
        isError: true
      );
    }
  }

  Future<void> _handleLogout() async {
    setState(() { _isLoadingLogout = true; });
    final nav = Navigator.of(context);
    final msgContext = ScaffoldMessenger.of(context);
    try {
      await _authService.logout();
      if (!mounted) return;
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingLogout = false; });
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        'Error al cerrar sesión: ${e.toString()}', 
        isError: true
      );
    }
  }

  void _goToModeracionPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModeracionPanelScreen(),
      ),
    );
  }

  void _goToSettings() {
    SnackBarHelper.showTopSnackBar(
      ScaffoldMessenger.of(context), 
      'Funcionalidad de Ajustes (Modo Oscuro/Claro) Pendiente', 
      isError: false
    );
  }
  // --- Fin de Lógica ---

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LibraTrack', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isScreenLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center(
        child: Text(
          'Error: $_loadingError',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          
          // --- ¡WIDGET DE AVATAR MODIFICADO! (Petición 6) ---
          Center(
            child: Stack(
              children: [
                // El Círculo principal
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  // Si estamos subiendo, mostramos un spinner
                  child: _isUploadingFoto
                      ? const CircularProgressIndicator()
                      // Si tenemos URL, mostramos la imagen de GCS
                      : (_perfil?.fotoPerfilUrl != null)
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _perfil!.fotoPerfilUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 60),
                              ),
                            )
                          // Si no, mostramos el icono por defecto
                          : const Icon(Icons.person, size: 60),
                ),
                // El botón de editar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.edit, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                // El detector de Taps
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isAnyLoading() ? null : _handlePickAndUploadFoto,
                      customBorder: const CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
          
          // --- Formulario de Perfil (Username) ---
          Text('Datos de Usuario', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(
                  context,
                  controller: _nombreController,
                  labelText: 'Nombre de Usuario',
                  enabled: !_isAnyLoading(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) { return 'El nombre de usuario no puede estar vacío.'; }
                    if (value.trim().length < 4) { return 'Debe tener al menos 4 caracteres.'; }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildInputField(
                  context,
                  controller: _emailController,
                  labelText: 'Email',
                  enabled: false,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  onPressed: _isAnyLoading() ? null : _handleUpdateProfile, 
                  child: _isLoadingUpdate
                      ? _buildSmallSpinner()
                      : Text(
                          'Guardar Cambios',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
          
          // --- Divisor y Formulario de Contraseña ---
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(context, controller: _contrasenaActualController, labelText: 'Contraseña actual', enabled: !_isAnyLoading(), isPassword: true, validator: (value) { if (value == null || value.isEmpty) { return 'La contraseña actual es obligatoria.'; } return null; }),
                const SizedBox(height: 16.0),
                _buildInputField(context, controller: _nuevaContrasenaController, labelText: 'Nueva contraseña', enabled: !_isAnyLoading(), isPassword: true, validator: (value) { if (value == null || value.isEmpty) { return 'La nueva contraseña es obligatoria.'; } if (value.length < 8) { return 'Debe tener al menos 8 caracteres.'; } return null; }),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  onPressed: _isAnyLoading() ? null : _handleChangePassword,
                  child: _isLoadingPasswordChange
                      ? _buildSmallSpinner()
                      : Text(
                          'Cambiar Contraseña',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                ),
              ],
            ),
          ),
          
          // --- Botón de Panel de Moderación (RF03) ---
          if (_perfil?.rol == 'ROLE_MODERADOR') ...[
            const SizedBox(height: 32.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: _isAnyLoading() ? null : _goToModeracionPanel,
              child: const Text(
                'Panel de Moderación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          
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
                : Text(
                    'Cerrar Sesión',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Helpers de UI (Definidos UNA VEZ) ---

  bool _isAnyLoading() {
    return _isLoadingUpdate || _isLoadingPasswordChange || _isLoadingLogout || _isUploadingFoto;
  }

  Widget _buildSmallSpinner() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }

  // --- ¡MÉTODO CORREGIDO! ---
  // (Vuelve a incluir la lógica de 'fillColor' y 'disabledBorder')
  Widget _buildInputField(
    BuildContext context,
    {
      required TextEditingController controller,
      required String labelText,
      bool enabled = true,
      bool isPassword = false,
      String? Function(String?)? validator,
    }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: isPassword,
      validator: validator,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        filled: true,
        
        // --- ¡LÓGICA RESTAURADA! ---
        // Si no está habilitado, usa un color de fondo diferente
        fillColor: enabled 
            ? Theme.of(context).colorScheme.surface 
            : Theme.of(context).scaffoldBackgroundColor,
            
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        
        // --- ¡LÓGICA RESTAURADA! ---
        // Mantenemos un borde visible cuando está deshabilitado
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.surface),
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