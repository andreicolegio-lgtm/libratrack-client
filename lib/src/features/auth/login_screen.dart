import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    setState(() {
      _isLoading = true;
    });

    final AuthService authService = context.read<AuthService>();
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);

    try {
      await authService.login(
        _emailController.text,
        _passwordController.text,
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, 'Error inesperado: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final AuthService authService = context.read<AuthService>();
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);

    try {
      await authService.signInWithGoogle(context);
    } on GoogleSignInCanceledException {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
            msgContext, 'Inicio de sesión cancelado.',
            isError: false, isNeutral: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
            msgContext, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
            msgContext, 'Error inesperado: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

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
                  Text(
                    l10n.appTitle,
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
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.loginEmailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
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
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.loginPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
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
                        : Text(l10n.loginButton),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(child: Divider(color: Colors.grey[700])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('O',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Text('G'),
                    label: const Text('Continuar con Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(l10n.loginRegisterPrompt.split('?')[0]),
                      TextButton(
                        onPressed: _isLoading ? null : _goToRegistration,
                        child:
                            Text(l10n.loginRegisterPrompt.split('?')[1].trim()),
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
