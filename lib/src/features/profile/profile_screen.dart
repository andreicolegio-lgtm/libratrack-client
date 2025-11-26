import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/utils/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../model/perfil_usuario.dart';
import '../moderacion/moderacion_panel_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../settings/settings_screen.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/api_exceptions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  late final UserService _userService;
  late final ApiClient _apiClient;
  final ImagePicker _picker = ImagePicker();

  // Estado de UI
  bool _isLoadingUpdate = false;
  bool _isLoadingPasswordChange = false;
  bool _isLoadingLogout = false;
  bool _isUploadingFoto = false;

  late PerfilUsuario _perfil;

  // Formularios y Controladores
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _contrasenaActualController =
      TextEditingController();
  final TextEditingController _nuevaContrasenaController =
      TextEditingController();
  final FocusNode _newPasswordFocusNode = FocusNode();

  bool _showPasswordValidation = false;
  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;

  // Nombre original para detectar cambios
  late String _originalUsername;

  @override
  void initState() {
    super.initState();
    _authService = context.read<AuthService>();
    _userService = context.read<UserService>();
    _apiClient = context.read<ApiClient>();

    // Cargar datos iniciales
    _perfil = _authService.perfilUsuario!;
    _nombreController.text = _perfil.username;
    _emailController.text = _perfil.email;
    _originalUsername = _perfil.username;

    // Listeners para validación visual dinámica
    _newPasswordFocusNode.addListener(() {
      if (mounted) {
        setState(
            () => _showPasswordValidation = _newPasswordFocusNode.hasFocus);
      }
    });

    _nuevaContrasenaController.addListener(() {
      if (_showPasswordValidation && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    _newPasswordFocusNode.dispose();
    super.dispose();
  }

  bool get _isAnyLoading =>
      _isLoadingUpdate ||
      _isLoadingPasswordChange ||
      _isLoadingLogout ||
      _isUploadingFoto;

  // --- Lógica de Negocio ---

  Future<void> _handlePickAndUploadFoto() async {
    if (_isAnyLoading) {
      return;
    }
    final l10n = AppLocalizations.of(context);

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }

      setState(() => _isUploadingFoto = true);

      // 1. Subir imagen
      final dynamic uploadData = await _apiClient.upload('uploads', image);
      final String fotoUrl = uploadData['url'];

      // 2. Actualizar perfil con la nueva URL
      final PerfilUsuario perfilActualizado =
          await _userService.updateFotoPerfil(fotoUrl);

      if (!mounted) {
        return;
      }

      setState(() {
        _perfil = perfilActualizado;
        _authService.updateLocalProfileData(
            perfilActualizado); // Sincronizar estado global
        _isUploadingFoto = false;
      });

      SnackBarHelper.showTopSnackBar(context, l10n.snackbarProfilePhotoUpdated,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
      setState(() => _isUploadingFoto = false);
    }
  }

  Future<void> _handleUpdateProfile() async {
    final l10n = AppLocalizations.of(context);
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    final String nuevoUsername = _nombreController.text.trim();
    if (nuevoUsername == _originalUsername) {
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarProfileNoChanges,
          isError: false, isNeutral: true);
      return;
    }

    setState(() => _isLoadingUpdate = true);

    try {
      final PerfilUsuario perfilActualizado =
          await _userService.updateUsername(nuevoUsername);

      if (!mounted) {
        return;
      }

      setState(() {
        _perfil = perfilActualizado;
        _originalUsername = perfilActualizado.username;
        _authService.updateLocalProfileData(perfilActualizado);
        _isLoadingUpdate = false;
      });

      SnackBarHelper.showTopSnackBar(
          context, l10n.snackbarProfileUsernameUpdated,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
      setState(() => _isLoadingUpdate = false);
    }
  }

  Future<void> _handleChangePassword() async {
    final l10n = AppLocalizations.of(context);
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoadingPasswordChange = true);
    FocusScope.of(context).unfocus(); // Ocultar teclado

    try {
      await _userService.updatePassword(
        _contrasenaActualController.text,
        _nuevaContrasenaController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPasswordChange = false;
        _contrasenaActualController.clear();
        _nuevaContrasenaController.clear();
        // Ocultar validación visual tras éxito
        _showPasswordValidation = false;
      });

      SnackBarHelper.showTopSnackBar(
          context, l10n.snackbarProfilePasswordUpdated,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
      setState(() => _isLoadingPasswordChange = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoadingLogout = true);
    final l10n = AppLocalizations.of(context);

    try {
      await _authService.logout();
    } catch (e) {
      _handleError(e, l10n);
      setState(() => _isLoadingLogout = false);
    }
  }

  void _handleError(Object e, AppLocalizations l10n) {
    if (!mounted) {
      return;
    }

    if (e is ApiException) {
      if (e is UnauthorizedException) {
        _authService.logout(); // Token inválido, salir a login
      } else {
        SnackBarHelper.showTopSnackBar(
            context, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } else {
      SnackBarHelper.showTopSnackBar(
          context, l10n.errorUnexpected(e.toString()),
          isError: true);
    }
  }

  // --- Construcción de UI ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bottomNavProfile),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildAvatarSection(context),
          const SizedBox(height: 32),

          // Sección: Datos de Usuario
          Text(l10n.profileUserData,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _profileFormKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nombreController,
                  label: l10n.registerUsernameLabel,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.validationUsernameRequired;
                    }
                    if (value.trim().length < 4) {
                      return l10n.validationUsernameLength450;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: l10n.loginEmailLabel,
                  icon: Icons.email_outlined,
                  enabled: false, // Email es de solo lectura
                ),
                const SizedBox(height: 24),
                _buildButton(
                  text: l10n.profileSaveButton,
                  isLoading: _isLoadingUpdate,
                  onPressed: _handleUpdateProfile,
                ),
              ],
            ),
          ),

          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),

          // Sección: Cambio de Contraseña
          Text(l10n.profileChangePassword,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _contrasenaActualController,
                  label: l10n.profileCurrentPassword,
                  icon: Icons.lock_open,
                  isPassword: true,
                  isObscured: _isCurrentPasswordObscured,
                  onToggleVisibility: () => setState(() =>
                      _isCurrentPasswordObscured = !_isCurrentPasswordObscured),
                  validator: (value) => (value == null || value.isEmpty)
                      ? l10n.validationPasswordCurrentRequired
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nuevaContrasenaController,
                  focusNode: _newPasswordFocusNode,
                  label: l10n.profileNewPassword,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isObscured: _isNewPasswordObscured,
                  onToggleVisibility: () => setState(
                      () => _isNewPasswordObscured = !_isNewPasswordObscured),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationPasswordNewRequired;
                    }
                    if (value == _contrasenaActualController.text) {
                      return l10n.validationPasswordUnchanged;
                    }
                    // Validación de complejidad (coincide con backend)
                    if (!RegExp(
                            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                        .hasMatch(value)) {
                      return l10n.validationPasswordComplexity;
                    }
                    return null;
                  },
                ),
                // Reglas visuales dinámicas
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showPasswordValidation ? null : 0,
                  child: _buildPasswordRules(l10n),
                ),
                const SizedBox(height: 24),
                _buildButton(
                  text: l10n.profileChangePassword,
                  isLoading: _isLoadingPasswordChange,
                  onPressed: _handleChangePassword,
                  isSecondary: true, // Estilo secundario para diferenciar
                ),
              ],
            ),
          ),

          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),

          // Sección: Roles Administrativos
          if (_perfil.esModerador)
            _buildRoleButton(
              text: l10n.profileModPanelButton,
              color: Colors.amber.shade800,
              icon: Icons.security,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ModeracionPanelScreen())),
            ),
          if (_perfil.esAdministrador)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _buildRoleButton(
                text: l10n.profileAdminPanelButton,
                color: Colors.deepPurple,
                icon: Icons.admin_panel_settings,
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminPanelScreen())),
              ),
            ),

          const SizedBox(height: 32),

          // Botón Logout
          _buildButton(
            text: l10n.profileLogoutButton,
            isLoading: _isLoadingLogout,
            onPressed: _handleLogout,
            color: Colors.red.shade700,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: _perfil.fotoPerfilUrl != null
                ? CachedNetworkImageProvider(_perfil.fotoPerfilUrl!)
                : null,
            child: _isUploadingFoto
                ? const CircularProgressIndicator()
                : (_perfil.fotoPerfilUrl == null
                    ? Icon(Icons.person,
                        size: 60, color: colorScheme.onSurfaceVariant)
                    : null),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: colorScheme.primary,
              child: InkWell(
                onTap: _isAnyLoading ? null : _handlePickAndUploadFoto,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: isPassword && isObscured,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon:
                    Icon(isObscured ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor:
            enabled ? null : Theme.of(context).disabledColor.withAlpha(20),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? color,
    bool isSecondary = false,
  }) {
    final theme = Theme.of(context);
    final style = ElevatedButton.styleFrom(
      backgroundColor: color ??
          (isSecondary ? theme.colorScheme.surface : theme.colorScheme.primary),
      foregroundColor: color != null
          ? Colors.white
          : (isSecondary
              ? theme.colorScheme.primary
              : theme.colorScheme.onPrimary),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: isSecondary ? BorderSide(color: theme.colorScheme.primary) : null,
      elevation: isSecondary ? 0 : 2,
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: style,
        onPressed: _isAnyLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: style.foregroundColor?.resolve({})))
            : Text(text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRoleButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isAnyLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPasswordRules(AppLocalizations l10n) {
    final pass = _nuevaContrasenaController.text;
    final rules = [
      MapEntry(l10n.passwordRuleLength, pass.length >= 8),
      MapEntry(l10n.passwordRuleUppercase, pass.contains(RegExp(r'[A-Z]'))),
      MapEntry(l10n.passwordRuleLowercase, pass.contains(RegExp(r'[a-z]'))),
      MapEntry(l10n.passwordRuleNumber, pass.contains(RegExp(r'\d'))),
      MapEntry(l10n.passwordRuleSpecial, pass.contains(RegExp(r'[@$!%*?&]'))),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, left: 8.0),
      child: Column(
        children: rules.map((rule) {
          final met = rule.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                Icon(met ? Icons.check_circle : Icons.circle_outlined,
                    size: 16, color: met ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(rule.key,
                    style: TextStyle(
                      color: met ? Colors.green : Colors.grey,
                      fontSize: 12,
                      decoration: met ? TextDecoration.lineThrough : null,
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
