// lib/src/features/profile/profile_screen.dart
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/core/services/user_service.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 
import 'package:libratrack_client/src/features/auth/login_screen.dart';
import 'package:libratrack_client/src/features/moderacion/moderacion_panel_screen.dart';
import 'package:libratrack_client/src/features/admin/admin_panel_screen.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart'; 
// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:libratrack_client/src/features/settings/settings_screen.dart';
// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:libratrack_client/src/core/l10n/app_localizations.dart';


/// --- ¡ACTUALIZADO (Sprint 8)! ---
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
  bool _isUploadingFoto = false; 
  
  PerfilUsuario? _perfil; // <-- Ahora contiene los roles

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
  
  Future<void> _handlePickAndUploadFoto() async {
    if (_isAnyLoading()) return;
    final msgContext = ScaffoldMessenger.of(context);
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return; 
    
    setState(() { _isUploadingFoto = true; });

    try {
      final File imageFile = File(image.path);
      final String fotoUrl = await _apiClient.upload(imageFile);
      final PerfilUsuario perfilActualizado = await _userService.updateFotoPerfil(fotoUrl);
      
      if (!mounted) return;
      setState(() {
        _perfil = perfilActualizado; 
        _isUploadingFoto = false;
      });
      SnackBarHelper.showTopSnackBar(msgContext, '¡Foto de perfil actualizada!', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isUploadingFoto = false; });
      SnackBarHelper.showTopSnackBar(msgContext, e.toString(), isError: true);
    }
  }

  Future<void> _handleUpdateProfile() async {
    if (!_profileFormKey.currentState!.validate()) { return; }
    final String nuevoUsername = _nombreController.text.trim();
    final msgContext = ScaffoldMessenger.of(context);

    if (nuevoUsername == _originalUsername) {
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        'No has realizado ningún cambio.', 
        isError: false
      );
      return;
    }
    setState(() { _isLoadingUpdate = true; });
    
    try {
      final PerfilUsuario perfilActualizado = await _userService.updateMiPerfil(nuevoUsername);
      if (!mounted) return;
      setState(() {
        _perfil = perfilActualizado; 
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

  // --- (Lógica de Navegación) ---
  
  void _goToModeracionPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModeracionPanelScreen(),
      ),
    );
  }

  void _goToAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminPanelScreen(), 
      ),
    );
  }

  // --- ¡MÉTODO MODIFICADO! (Petición 10) ---
  void _goToSettings() {
    // Ya no muestra un SnackBar, ahora navega
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

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
    // --- ¡NUEVO! Obtenemos las traducciones ---
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle, style: Theme.of(context).textTheme.titleLarge), // <-- TRADUCIDO
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings, // <-- Conectado
            tooltip: l10n.settingsTitle, // <-- TRADUCIDO
          ),
        ],
      ),
      body: _buildBody(context, l10n), // <-- Pasamos l10n al body
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) { // <-- Recibe l10n
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
          
          // --- Widget de Avatar (Sin cambios) ---
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: _isUploadingFoto
                      ? const CircularProgressIndicator()
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
                          : const Icon(Icons.person, size: 60),
                ),
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
          Text(l10n.profileUserData, style: Theme.of(context).textTheme.titleLarge), // <-- TRADUCIDO
          const SizedBox(height: 16.0),
          Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(
                  context,
                  controller: _nombreController,
                  labelText: l10n.registerUsernameLabel, // <-- TRADUCIDO
                  enabled: !_isAnyLoading(),
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
                          l10n.profileSaveButton, // <-- TRADUCIDO
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
            l10n.profileChangePassword, // <-- TRADUCIDO
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(context, controller: _contrasenaActualController, labelText: l10n.profileCurrentPassword, enabled: !_isAnyLoading(), isPassword: true, validator: (value) { if (value == null || value.isEmpty) { return l10n.loginPasswordRequired; } return null; }), // <-- TRADUCIDO
                const SizedBox(height: 16.0),
                _buildInputField(context, controller: _nuevaContrasenaController, labelText: l10n.profileNewPassword, enabled: !_isAnyLoading(), isPassword: true, validator: (value) { if (value == null || value.isEmpty) { return l10n.loginPasswordRequired; } if (value.length < 8) { return l10n.registerPasswordLength; } return null; }), // <-- TRADUCIDO
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
                          l10n.profileChangePassword, // <-- TRADUCIDO
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                ),
              ],
            ),
          ),
          
          // --- Lógica de Botones de Rol ---
          if (_perfil?.esModerador == true) ...[
            const SizedBox(height: 32.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: _isAnyLoading() ? null : _goToModeracionPanel,
              child: Text(
                l10n.profileModPanelButton, // <-- TRADUCIDO
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          
          if (_perfil?.esAdministrador == true) ...[
            const SizedBox(height: 16.0), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700], 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: _isAnyLoading() ? null : _goToAdminPanel,
              child: Text(
                l10n.profileAdminPanelButton, // <-- TRADUCIDO
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    l10n.profileLogoutButton, // <-- TRADUCIDO
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Helpers de UI (sin cambios) ---

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
        fillColor: enabled 
            ? Theme.of(context).colorScheme.surface 
            : Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
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