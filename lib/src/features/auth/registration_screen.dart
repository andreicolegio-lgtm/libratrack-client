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

    try {
      await authService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        navContext.popUntil((route) => route.isFirst);
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.snackbarRegisterSuccess,
          isError: false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });

      SnackBarHelper.showTopSnackBar(
        context,
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
        context,
        l10n.errorUnexpected(e.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() {
          _showPasswordValidation = false;
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
                  onTap: () {
                    setState(() {
                      _showPasswordValidation = false;
                    });
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
                  onTap: () {
                    setState(() {
                      _showPasswordValidation = false;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
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
                    errorMaxLines:
                        2, // Allow error messages to wrap to the next line
                  ),
                  obscureText: _isPasswordObscured,
                  textInputAction: TextInputAction.done,
                  onTap: () {
                    setState(() {
                      _showPasswordValidation = true;
                    });
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
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
                // Real-time password validation feedback
                if (_showPasswordValidation)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          _getValidationRules(_passwordController.text, l10n)
                              .map((entry) {
                        return Row(
                          children: [
                            Icon(
                              entry.value ? Icons.check_circle : Icons.cancel,
                              color: entry.value ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: entry.value ? Colors.green : Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
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
