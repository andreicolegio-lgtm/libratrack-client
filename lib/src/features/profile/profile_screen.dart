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

  bool _isLoadingUpdate = false;
  bool _isLoadingPasswordChange = false;
  bool _isLoadingLogout = false;
  bool _isUploadingFoto = false;

  late PerfilUsuario _perfil;

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _originalUsername = '';
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _contrasenaActualController =
      TextEditingController();
  final TextEditingController _nuevaContrasenaController =
      TextEditingController();

  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;

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
  }

  Future<void> _handlePickAndUploadFoto() async {
    if (_isAnyLoading()) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    setState(() {
      _isUploadingFoto = true;
    });

    try {
      final dynamic data = await _apiClient.upload('uploads', image);
      final String fotoUrl = data['url'];

      final PerfilUsuario perfilActualizado =
          await _userService.updateFotoPerfil(fotoUrl);

      if (!mounted) {
        return;
      }
      setState(() {
        _perfil = perfilActualizado;
        _isUploadingFoto = false;

        _authService.updateLocalProfileData(perfilActualizado);
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarProfilePhotoUpdated,
          isError: false);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploadingFoto = false;
      });
      if (e is UnauthorizedException) {
        _authService.logout();
      } else {
        SnackBarHelper.showTopSnackBar(
            context, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploadingFoto = false;
      });
      SnackBarHelper.showTopSnackBar(
          context, l10n.errorImageUpload(e.toString()),
          isError: true);
    }
  }

  Future<void> _handleUpdateProfile() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    final String nuevoUsername = _nombreController.text.trim();

    if (nuevoUsername == _originalUsername) {
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarProfileNoChanges,
          isError: false, isNeutral: true);
      return;
    }
    setState(() {
      _isLoadingUpdate = true;
    });

    try {
      final PerfilUsuario perfilActualizado =
          await _userService.updateUsername(nuevoUsername);

      if (!mounted) {
        return;
      }
      setState(() {
        _perfil = perfilActualizado;
        _nombreController.text = perfilActualizado.username;
        _originalUsername = perfilActualizado.username;
        _isLoadingUpdate = false;

        _authService.updateLocalProfileData(perfilActualizado);
      });
      SnackBarHelper.showTopSnackBar(
          context, l10n.snackbarProfileUsernameUpdated,
          isError: false);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingUpdate = false;
      });
      if (e is UnauthorizedException) {
        _authService.logout();
      } else {
        SnackBarHelper.showTopSnackBar(
            context, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingUpdate = false;
      });
      SnackBarHelper.showTopSnackBar(context, l10n.errorUpdating(e.toString()),
          isError: true);
    }
  }

  Future<void> _handleChangePassword() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_passwordFormKey.currentState!.validate()) {
      debugPrint(
          '[ProfileScreen._handleChangePassword] Form validation failed');

      // Focus the first invalid field
      if (_contrasenaActualController.text.isEmpty ||
          !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}')
              .hasMatch(_contrasenaActualController.text)) {
        FocusScope.of(context)
            .requestFocus(FocusScope.of(context).focusedChild);
      } else if (_nuevaContrasenaController.text.isEmpty ||
          !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}')
              .hasMatch(_nuevaContrasenaController.text)) {
        FocusScope.of(context)
            .requestFocus(FocusScope.of(context).focusedChild);
      }

      setState(() {});
      return;
    }
    setState(() {
      _isLoadingPasswordChange = true;
    });
    final FocusScopeNode focusScope = FocusScope.of(context);

    final String actual = _contrasenaActualController.text;
    final String nueva = _nuevaContrasenaController.text;
    debugPrint(
        '[ProfileScreen._handleChangePassword] Attempting to change password');
    debugPrint(
        '[ProfileScreen._handleChangePassword] Current password: $actual');
    debugPrint('[ProfileScreen._handleChangePassword] New password: $nueva');
    try {
      await _userService.updatePassword(actual, nueva);

      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPasswordChange = false;
        _contrasenaActualController.clear();
        _nuevaContrasenaController.clear();
      });
      focusScope.unfocus();
      SnackBarHelper.showTopSnackBar(
          context, l10n.snackbarProfilePasswordUpdated,
          isError: false);
      debugPrint(
          '[ProfileScreen._handleChangePassword] Password changed successfully');
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPasswordChange = false;
      });
      if (e is UnauthorizedException) {
        _authService.logout();
      } else {
        SnackBarHelper.showTopSnackBar(
            context, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
      debugPrint(
          '[ProfileScreen._handleChangePassword] ApiException: ${e.message}');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPasswordChange = false;
      });
      SnackBarHelper.showTopSnackBar(context, l10n.errorUpdating(e.toString()),
          isError: true);
      debugPrint(
          '[ProfileScreen._handleChangePassword] Unexpected error: ${e.toString()}');
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoadingLogout = true;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      await _authService.logout();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingLogout = false;
      });
      SnackBarHelper.showTopSnackBar(
          context, ErrorTranslator.translate(context, e.message),
          isError: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingLogout = false;
      });
      SnackBarHelper.showTopSnackBar(
          context, l10n.errorUnexpected(e.toString()),
          isError: true);
    }
  }

  void _goToModeracionPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const ModeracionPanelScreen(),
      ),
    );
  }

  void _goToAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const AdminPanelScreen(),
      ),
    );
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const SettingsScreen(),
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(l10n.appTitle, style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Stack(
              children: <Widget>[
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: _isUploadingFoto
                      ? const CircularProgressIndicator()
                      : (_perfil.fotoPerfilUrl != null)
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _perfil.fotoPerfilUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder:
                                    (BuildContext context, String url) =>
                                        const CircularProgressIndicator(),
                                errorWidget: (BuildContext context, String url,
                                        Object error) =>
                                    const Icon(Icons.person, size: 60),
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
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
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
          Text(l10n.profileUserData,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _nombreController,
                  labelText: l10n.registerUsernameLabel,
                  enabled: !_isAnyLoading(),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.validationUsernameRequired;
                    }
                    if (value.trim().length < 4) {
                      return l10n.validationUsernameLength450;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _emailController,
                  labelText: l10n.loginEmailLabel,
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
                          l10n.profileSaveButton,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),
          Text(
            l10n.profileChangePassword,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _contrasenaActualController,
                  labelText: l10n.profileCurrentPassword,
                  isPassword: _isCurrentPasswordObscured,
                  prefixIcon: const Icon(Icons.lock_open),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordObscured =
                            !_isCurrentPasswordObscured;
                      });
                    },
                  ),
                  validator: (String? value) {
                    debugPrint(
                        '[ProfileScreen._buildInputField] Validating current password: $value');

                    // Validate current password strength
                    final regex = RegExp(
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}');
                    if (value == null || value.isEmpty) {
                      debugPrint(
                          '[ProfileScreen._buildInputField] Validation failed: Current password is empty');
                      return l10n.validationPasswordCurrentRequired;
                    }
                    if (!regex.hasMatch(value)) {
                      debugPrint(
                          '[ProfileScreen._buildInputField] Validation failed: Current password does not meet complexity requirements');
                      return l10n.validationPasswordComplexity;
                    }

                    debugPrint(
                        '[ProfileScreen._buildInputField] Current password validation passed');
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _nuevaContrasenaController,
                  labelText: l10n.profileNewPassword,
                  isPassword: _isNewPasswordObscured,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(l10n.passwordRulesTitle),
                                content: Text(l10n.passwordRulesContent),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(l10n.dialogCloseButton),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isNewPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordObscured = !_isNewPasswordObscured;
                          });
                        },
                      ),
                    ],
                  ),
                  validator: (String? value) {
                    debugPrint(
                        '[ProfileScreen._buildInputField] Validating new password: $value');

                    // Validate new password strength
                    final regex = RegExp(
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}');
                    if (value == null || value.isEmpty) {
                      debugPrint(
                          '[ProfileScreen._buildInputField] Validation failed: New password is empty');
                      return l10n.validationPasswordNewRequired;
                    }
                    if (!regex.hasMatch(value)) {
                      debugPrint(
                          '[ProfileScreen._buildInputField] Validation failed: New password does not meet complexity requirements');
                      return l10n.validationPasswordComplexity;
                    }

                    // Check if new password matches current password
                    if (value == _contrasenaActualController.text) {
                      debugPrint(
                          '[ProfileScreen._buildInputField] Validation failed: Password is unchanged');
                      return l10n.validationPasswordUnchanged;
                    }

                    debugPrint(
                        '[ProfileScreen._buildInputField] New password validation passed');
                    return null;
                  },
                ),
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
                          l10n.profileChangePassword,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                ),
              ],
            ),
          ),
          if (_perfil.esModerador) ...<Widget>[
            const SizedBox(height: 32.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: _isAnyLoading() ? null : _goToModeracionPanel,
              child: Text(
                l10n.profileModPanelButton,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          if (_perfil.esAdministrador) ...<Widget>[
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: _isAnyLoading() ? null : _goToAdminPanel,
              child: Text(
                l10n.profileAdminPanelButton,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 16.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            onPressed: _isAnyLoading() ? null : _handleLogout,
            child: _isLoadingLogout
                ? _buildSmallSpinner()
                : Text(
                    l10n.profileLogoutButton,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  bool _isAnyLoading() {
    return _isLoadingUpdate ||
        _isLoadingPasswordChange ||
        _isLoadingLogout ||
        _isUploadingFoto;
  }

  Widget _buildSmallSpinner() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    bool isPassword = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
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
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
