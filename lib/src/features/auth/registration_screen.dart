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

  bool _isLoading = false;
  bool _isPasswordObscured = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _handleRegister() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final AuthService authService = context.read<AuthService>();
    final NavigatorState navContext = Navigator.of(context);
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);

    try {
      await authService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      SnackBarHelper.showTopSnackBar(
        msgContext,
        l10n.snackbarRegisterSuccess,
        isError: false,
      );

      // Navigate to the home screen after auto-login
      navContext.pushReplacementNamed('/home');
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });

      SnackBarHelper.showTopSnackBar(
        msgContext,
        ErrorTranslator.translate(context, e.message),
        isError: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });

      SnackBarHelper.showTopSnackBar(
        msgContext,
        l10n.errorUnexpected(e.toString()),
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: 48),
                ),
                const SizedBox(height: 64.0),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.registerUsernameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                    errorMaxLines:
                        2, // Allow error messages to wrap to the next line
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationUsernameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.loginEmailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    errorMaxLines:
                        2, // Allow error messages to wrap to the next line
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
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.loginPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
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
                      ],
                    ),
                    errorMaxLines:
                        2, // Allow error messages to wrap to the next line
                  ),
                  obscureText: _isPasswordObscured,
                  textInputAction: TextInputAction.done,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationPasswordRequired;
                    }
                    if (!RegExp(
                            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                        .hasMatch(value)) {
                      return l10n.validationPasswordComplexity;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.registerTitle,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    l10n.registerLoginPrompt,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
