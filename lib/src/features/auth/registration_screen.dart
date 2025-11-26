import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/api_exceptions.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _showPasswordValidation = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Mostrar reglas de validación solo cuando el campo de contraseña tiene el foco
    _passwordFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showPasswordValidation = _passwordFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Cerrar teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final AuthService authService = context.read<AuthService>();
    final NavigatorState navContext = Navigator.of(context);

    try {
      await authService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.snackbarRegisterSuccess,
          isError: false,
        );
        // Volver al login (o dejar que AuthWrapper redirija si el stack se limpia)
        // Al hacer pop, volvemos a LoginScreen, y como AuthWrapper detecta
        // autenticación, cambiará a HomeScreen automáticamente.
        navContext.pop();
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
        setState(() => _isLoading = false);
      }
    }
  }

  /// Genera las reglas de validación visual para la contraseña
  List<MapEntry<String, bool>> _getValidationRules(
      String password, AppLocalizations l10n) {
    return [
      MapEntry(l10n.passwordRuleLength, password.length >= 8),
      MapEntry(l10n.passwordRuleUppercase, password.contains(RegExp(r'[A-Z]'))),
      MapEntry(l10n.passwordRuleLowercase, password.contains(RegExp(r'[a-z]'))),
      MapEntry(l10n.passwordRuleNumber, password.contains(RegExp(r'\d'))),
      MapEntry(
          l10n.passwordRuleSpecial, password.contains(RegExp(r'[@$!%*?&]'))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.registerTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 48.0),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: l10n.registerUsernameLabel,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: 16.0),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    decoration: InputDecoration(
                      labelText: l10n.loginPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
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
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    obscureText: _isPasswordObscured,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      // Reconstruir para actualizar validadores visuales
                      setState(() {});
                    },
                    onFieldSubmitted: (_) => _handleRegister(),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return l10n.validationPasswordRequired;
                      }
                      // Regex de complejidad del backend
                      if (!RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                          .hasMatch(value)) {
                        return l10n.validationPasswordComplexity;
                      }
                      return null;
                    },
                  ),

                  // Validadores visuales en tiempo real
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showPasswordValidation ? null : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _getValidationRules(_passwordController.text, l10n)
                                .map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  entry.value
                                      ? Icons.check_circle
                                      : Icons.cancel_outlined,
                                  color:
                                      entry.value ? Colors.green : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: entry.value
                                          ? Colors.green
                                          : Colors.grey,
                                      fontSize: 13,
                                      decoration: entry.value
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32.0),

                  // Botón Registrar
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
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            l10n.registerTitle,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16.0),

                  // Volver al Login
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: Text(
                      l10n.registerLoginPrompt,
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    ),
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
