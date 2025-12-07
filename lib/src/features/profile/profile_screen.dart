import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Asegúrate de tener este import
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

  // Estado de Validación (UX Improvement)
  // Desactivado por defecto. Se activa solo tras el primer intento de guardar fallido.
  AutovalidateMode _passwordAutovalidateMode = AutovalidateMode.disabled;

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

  late String _originalUsername;

  @override
  void initState() {
    super.initState();
    _authService = context.read<AuthService>();
    _userService = context.read<UserService>();
    _apiClient = context.read<ApiClient>();

    _perfil = _authService.perfilUsuario!;
    _nombreController.text = _perfil.username;
    _emailController.text = _perfil.email;
    _originalUsername = _perfil.username;

    // Listeners para UX dinámica
    _newPasswordFocusNode.addListener(() {
      if (mounted) {
        setState(
            () => _showPasswordValidation = _newPasswordFocusNode.hasFocus);
      }
    });

    // Listener para "Limpiar errores" si el usuario borra todo
    void clearErrorsIfEmpty() {
      if (_contrasenaActualController.text.isEmpty &&
          _nuevaContrasenaController.text.isEmpty) {
        if (_passwordAutovalidateMode != AutovalidateMode.disabled) {
          setState(() {
            _passwordAutovalidateMode = AutovalidateMode.disabled;
            _passwordFormKey.currentState
                ?.reset(); // Elimina textos rojos visuales
          });
        }
      }
    }

    _contrasenaActualController.addListener(clearErrorsIfEmpty);
    _nuevaContrasenaController.addListener(clearErrorsIfEmpty);
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

      final dynamic uploadData = await _apiClient.upload('uploads', image);
      final String fotoUrl = uploadData['url'];

      final PerfilUsuario perfilActualizado =
          await _userService.updateFotoPerfil(fotoUrl);

      if (!mounted) {
        return;
      }

      setState(() {
        _perfil = perfilActualizado;
        _authService.updateLocalProfileData(perfilActualizado);
        _isUploadingFoto = false;
      });

      SnackBarHelper.showTopSnackBar(context, l10n.snackbarProfilePhotoUpdated,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
      if (mounted) {
        setState(() => _isUploadingFoto = false);
      }
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
      if (mounted) {
        setState(() => _isLoadingUpdate = false);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final l10n = AppLocalizations.of(context);

    // ACTIVAR VALIDACIÓN: Solo ahora mostramos errores si los hay
    setState(() {
      _passwordAutovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoadingPasswordChange = true);
    FocusScope.of(context).unfocus();

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
        _showPasswordValidation = false;
        _passwordAutovalidateMode =
            AutovalidateMode.disabled; // Resetear estado validación
      });

      SnackBarHelper.showTopSnackBar(
          context, l10n.snackbarProfilePasswordUpdated,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
      if (mounted) {
        setState(() => _isLoadingPasswordChange = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoadingLogout = true);
    final l10n = AppLocalizations.of(context);

    try {
      await _authService.logout();
    } catch (e) {
      _handleError(e, l10n);
      if (mounted) {
        setState(() => _isLoadingLogout = false);
      }
    }
  }

  void _handleError(Object e, AppLocalizations l10n) {
    if (!mounted) {
      return;
    }

    if (e is ApiException) {
      if (e is UnauthorizedException) {
        _authService.logout();
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

  // Muestra el menú inferior con opciones
  void _showImageOptions() {
    final l10n = AppLocalizations.of(context);
    final hasImage = _perfil.fotoPerfilUrl != null;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title:
                  Text(l10n.adminFormImageUpload), // "Subir imagen" o similar
              onTap: () {
                Navigator.pop(ctx);
                _handlePickAndUploadFoto();
              },
            ),
            if (hasImage) // Solo mostramos borrar si hay imagen
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar foto actual', // Añade esta key a tu l10n si prefieres
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleRemoveFoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  // Lógica para borrar la foto (enviar null al backend)
  Future<void> _handleRemoveFoto() async {
    if (_isAnyLoading) {
      return;
    }

    setState(() => _isUploadingFoto = true);
    // final l10n = AppLocalizations.of(context); // Descomenta si usas textos localizados en snackbar

    try {
      // Asumimos que tu UserService acepta null para borrar la foto.
      // Si no, tendrás que ajustar tu servicio para enviar json['fotoPerfilUrl'] = null
      final PerfilUsuario perfilActualizado =
          await _userService.updateFotoPerfil(null);

      if (!mounted) {
        return;
      }

      setState(() {
        _perfil = perfilActualizado;
        _authService.updateLocalProfileData(perfilActualizado);
        _isUploadingFoto = false;
      });

      SnackBarHelper.showTopSnackBar(context, 'Foto de perfil eliminada',
          isError: false);
    } catch (e) {
      // Manejo de error estándar
      if (mounted) {
        setState(() => _isUploadingFoto = false);
      }
      SnackBarHelper.showTopSnackBar(context, 'Error al eliminar foto',
          isError: true);
    }
  }

  // --- Construcción de UI ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      // Punto 2: SafeZone aplicada a toda la estructura principal
      body: SafeArea(
        child: Column(
          children: [
            // --- Cabecera Personalizada (Estilo Catálogo) ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/isotipo_libratrack.svg',
                        height: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'LibraTrack',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: l10n.settingsTitle,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Contenido Scrollable ---
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  _buildAvatarSection(context),
                  const SizedBox(height: 32),
                  Text(l10n.profileUserData, style: theme.textTheme.titleLarge),
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
                          enabled: false,
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
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider()),
                  Text(l10n.profileChangePassword,
                      style: theme.textTheme.titleLarge),
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
                              _isCurrentPasswordObscured =
                                  !_isCurrentPasswordObscured),
                          // Uso dinámico del AutovalidateMode
                          autovalidateMode: _passwordAutovalidateMode,
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
                          onToggleVisibility: () => setState(() =>
                              _isNewPasswordObscured = !_isNewPasswordObscured),
                          // Uso dinámico del AutovalidateMode
                          autovalidateMode: _passwordAutovalidateMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.validationPasswordNewRequired;
                            }
                            // Prioridad 1: Complejidad
                            if (!RegExp(
                                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                                .hasMatch(value)) {
                              return l10n.validationPasswordComplexity;
                            }
                            // Prioridad 2: Igualdad
                            if (value == _contrasenaActualController.text) {
                              return l10n.validationPasswordUnchanged;
                            }
                            return null;
                          },
                        ),
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
                          isSecondary: true,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider()),
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
                  _buildButton(
                    text: l10n.profileLogoutButton,
                    isLoading: _isLoadingLogout,
                    onPressed: _handleLogout,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = _perfil.fotoPerfilUrl != null;

    return Center(
      // Usamos un tamaño fijo para asegurar que el Stack se comporte bien
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          children: [
            // CAPA 1: La Imagen de Fondo (o Icono por defecto)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
                image: hasImage
                    ? DecorationImage(
                        image:
                            CachedNetworkImageProvider(_perfil.fotoPerfilUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasImage && !_isUploadingFoto
                  ? Center(
                      child: Icon(Icons.person,
                          size: 60, color: colorScheme.onSurfaceVariant))
                  : null,
            ),

            // CAPA 2: Spinner de Carga (si aplica)
            if (_isUploadingFoto)
              const Center(child: CircularProgressIndicator()),

            // CAPA 3: El Feedback Visual (InkWell SUPERPUESTO)
            // Esto es lo que garantiza que al pulsar se vea la "ola" sobre la imagen
            Positioned.fill(
              child: Material(
                color: Colors
                    .transparent, // Transparente para ver la imagen debajo
                shape: const CircleBorder(), // Forma circular estricta
                clipBehavior:
                    Clip.hardEdge, // Recorta el efecto visual al círculo
                child: InkWell(
                  onTap:
                      _isAnyLoading ? null : _showImageOptions, // Abre el menú
                  splashColor: colorScheme.primary
                      .withAlpha(50), // Color del efecto (opcional)
                ),
              ),
            ),

            // CAPA 4: El icono de cámara (Decorativo)
            // Usamos IgnorePointer para que el click lo capture el InkWell de la Capa 3
            Positioned(
              bottom: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    // Añadimos un borde blanco para separarlo visualmente de la foto
                    border: Border.all(color: colorScheme.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
    AutovalidateMode? autovalidateMode, // Parámetro añadido
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: isPassword && isObscured,
      validator: validator,
      // Usamos el modo que nos pasen (controlado por estado) o el default
      autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
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

  // ... (Resto de widgets auxiliares _buildButton, _buildRoleButton, _buildPasswordRules igual que antes) ...
  // Asegúrate de copiar los métodos helpers del archivo anterior si no están aquí,
  // aunque he incluido la lógica principal arriba.

  Widget _buildButton(
      {required String text,
      required VoidCallback onPressed,
      bool isLoading = false,
      Color? color,
      bool isSecondary = false}) {
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
                        strokeWidth: 2,
                        color: style.foregroundColor?.resolve({})))
                : Text(text,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold))));
  }

  Widget _buildRoleButton(
      {required String text,
      required Color color,
      required IconData icon,
      required VoidCallback onPressed}) {
    return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: _isAnyLoading ? null : onPressed,
            icon: Icon(icon),
            label: Text(text,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold))));
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
              child: Row(children: [
                Icon(met ? Icons.check_circle : Icons.circle_outlined,
                    size: 16, color: met ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(rule.key,
                    style: TextStyle(
                        color: met ? Colors.green : Colors.grey,
                        fontSize: 12,
                        decoration: met ? TextDecoration.lineThrough : null))
              ]));
        }).toList()));
  }
}
