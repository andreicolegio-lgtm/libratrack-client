import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/resena_service.dart';
import '../../../model/resena.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/api_exceptions.dart';

class ResenaFormModal extends StatefulWidget {
  final int elementoId;

  const ResenaFormModal({required this.elementoId, super.key});

  @override
  State<ResenaFormModal> createState() => _ResenaFormModalState();
}

class _ResenaFormModalState extends State<ResenaFormModal> {
  late final ResenaService _resenaService;
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _textoController = TextEditingController();
  int _valoracion = 0;

  @override
  void initState() {
    super.initState();
    _resenaService = context.read<ResenaService>();
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _handleEnviarResena() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_valoracion == 0) {
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarReviewRatingRequired,
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);

    try {
      final Resena nuevaResena = await _resenaService.crearResena(
        elementoId: widget.elementoId,
        valoracion: _valoracion,
        textoResena:
            _textoController.text.isEmpty ? null : _textoController.text,
      );

      if (!mounted) {
        return;
      }

      SnackBarHelper.showTopSnackBar(context, l10n.snackbarReviewPublished,
          isError: false);
      navigator.pop(
          nuevaResena); // Devuelve la nueva reseña para actualizar la lista
    } catch (e) {
      _handleError(e, l10n);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(Object e, AppLocalizations l10n) {
    if (!mounted) {
      return;
    }

    if (e is ApiException) {
      SnackBarHelper.showTopSnackBar(
        context,
        ErrorTranslator.translate(context, e.message),
        isError: true,
      );
    } else {
      SnackBarHelper.showTopSnackBar(
        context,
        l10n.errorUnexpected(e.toString()),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.reviewModalTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),

            // Estrellas
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (int index) {
                  final int estrella = index + 1;
                  return IconButton(
                    icon: Icon(
                      _valoracion >= estrella ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _valoracion = estrella);
                          },
                  );
                }),
              ),
            ),
            const SizedBox(height: 24.0),

            // Texto
            TextFormField(
              controller: _textoController,
              maxLines: 5,
              enabled: !_isLoading,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: l10n.reviewModalReviewLabel,
                hintText: l10n.reviewModalReviewHint,
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withAlpha(77),
              ),
              validator: (value) {
                if (value != null && value.length > 2000) {
                  return l10n.validationReviewMax2000;
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),

            // Botón
            FilledButton(
              onPressed: _isLoading ? null : _handleEnviarResena,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(l10n.reviewModalSubmitButton),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
