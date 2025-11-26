import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/auth_service.dart';
import 'registration_screen.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/utils/api_exceptions.dart';

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
  bool _isPasswordObscured = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Cerrar teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final AppLocalizations l10n = AppLocalizations.of(context);

    try {
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // La navegación a HomeScreen se maneja automáticamente por el AuthWrapper en main.dart
      // al detectar el cambio de estado en AuthService.
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
          context,
          ErrorTranslator.translate(context, e.message),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.errorUnexpected(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    final authService = context.read<AuthService>();
    final AppLocalizations l10n = AppLocalizations.of(context);

    try {
      await authService.signInWithGoogle();
      // El AuthWrapper redirigirá automáticamente.
    } on GoogleSignInCanceledException {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.snackbarLoginGoogleCancel,
          isError: false,
          isNeutral: true,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
          context,
          ErrorTranslator.translate(context, e.message),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.errorUnexpected(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _goToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const RegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).colorScheme.primary;

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
                children: <Widget>[
                  // Logo o Título
                  Icon(Icons.library_books, size: 64, color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 48),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.loginEmailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return l10n.validationEmailRequired;
                      }
                      if (!value.contains('@')) {
                        return l10n.validationEmailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.loginPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    obscureText: _isPasswordObscured,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return l10n.validationPasswordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón Login
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 2,
                    ),
                    onPressed:
                        (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            l10n.loginButton,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Separador
                  Row(
                    children: <Widget>[
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(l10n.loginOr,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón Google
                  OutlinedButton.icon(
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0))
                        : SvgPicture.asset(
                            'assets/images/google_logo.svg',
                            width: 24,
                            height: 24,
                          ),
                    label: Text(l10n.loginGoogle),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    onPressed: (_isLoading || _isGoogleLoading)
                        ? null
                        : _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 24.0),

                  // Ir a Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : _goToRegistration,
                        child: Text(
                          l10n.loginRegisterPrompt,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
