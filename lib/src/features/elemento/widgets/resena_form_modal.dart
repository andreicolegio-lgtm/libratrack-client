import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/resena_service.dart';
import '../../../model/resena.dart';
import '../../../core/utils/snackbar_helper.dart';
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);

    if (_valoracion == 0) {
      SnackBarHelper.showTopSnackBar(
          msgContext, 'Por favor, selecciona una valoración (1-5 estrellas).',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final NavigatorState navContext = Navigator.of(context);

    try {
      final Resena nuevaResena = await _resenaService.crearResena(
        elementoId: widget.elementoId,
        valoracion: _valoracion,
        textoResena:
            _textoController.text.isEmpty ? null : _textoController.text,
      );

      if (!mounted) return;

      SnackBarHelper.showTopSnackBar(msgContext, '¡Reseña publicada!',
          isError: false);
      navContext.pop(nuevaResena);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      SnackBarHelper.showTopSnackBar(
        msgContext,
        e.message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      SnackBarHelper.showTopSnackBar(
          msgContext, 'Error inesperado: ${e.toString()}',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
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
                'Escribir Reseña',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (int index) {
                    final int estrella = index + 1;
                    return IconButton(
                      icon: Icon(
                        _valoracion >= estrella
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _valoracion = estrella;
                        });
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24.0),
              _buildInputField(
                context,
                controller: _textoController,
                labelText: 'Reseña (opcional)',
                hintText: 'Escribe tu opinión...',
                maxLines: 5,
                validator: (String? value) {
                  if (value != null && value.length > 2000) {
                    return 'Máximo 2000 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isLoading ? null : _handleEnviarResena,
                child: _isLoading
                    ? _buildSmallSpinner()
                    : Text(
                        'Publicar Reseña',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey[600]),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
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
      ),
    );
  }

  Widget _buildSmallSpinner() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }
}
