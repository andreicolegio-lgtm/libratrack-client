// lib/src/features/elemento/widgets/resena_form_modal.dart
// (¡CORREGIDO!)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/core/services/resena_service.dart';
import 'package:libratrack_client/src/model/resena.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart'; // <-- ¡NUEVA IMPORTACIÓN!

/// Un 'Modal Bottom Sheet' para escribir una nueva reseña (RF12).
class ResenaFormModal extends StatefulWidget {
  final int elementoId;

  const ResenaFormModal({super.key, required this.elementoId});

  @override
  State<ResenaFormModal> createState() => _ResenaFormModalState();
}

class _ResenaFormModalState extends State<ResenaFormModal> {
  // --- Servicios y Estado ---
  // --- ¡CORREGIDO (Error 1)! ---
  // Se elimina la instancia local y se declara 'late final'
  late final ResenaService _resenaService;
  // final ResenaService _resenaService = ResenaService();
  // ---
  bool _isLoading = false;

  // --- Formulario ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  int _valoracion = 0;

  // --- ¡NUEVO! ---
  @override
  void initState() {
    super.initState();
    // --- ¡CORREGIDO (Error 1)! ---
    // Obtenemos el servicio desde Provider
    _resenaService = context.read<ResenaService>();
    // ---
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  /// Lógica para enviar la reseña (RF12)
  Future<void> _handleEnviarResena() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final msgContext = ScaffoldMessenger.of(context); // Guardamos el context

    // Validar que se haya seleccionado una valoración
    if (_valoracion == 0) {
      // Usa el helper
      SnackBarHelper.showTopSnackBar(
          msgContext, 'Por favor, selecciona una valoración (1-5 estrellas).',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final navContext = Navigator.of(context);

    try {
      // 2. Llamar al servicio
      // --- ¡CORREGIDO (Error 2)! ---
      // Se pasa el ID como String
      final Resena nuevaResena = await _resenaService.crearResena(
        elementoId: widget.elementoId,
        valoracion: _valoracion,
        textoResena:
            _textoController.text.isEmpty ? null : _textoController.text,
      );
      // ---

      // 3. (ÉXITO) Devolver la nueva reseña
      if (!mounted) return;

      // Usa el helper
      SnackBarHelper.showTopSnackBar(msgContext, '¡Reseña publicada!',
          isError: false);
      navContext.pop(nuevaResena);
      
    // --- ¡MEJORADO! ---
    // Se captura la excepción específica
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      SnackBarHelper.showTopSnackBar(
        msgContext,
        e.message, // Usamos el mensaje limpio
        isError: true,
      );
    } catch (e) {
      // 4. (ERROR)
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Usa el helper
      SnackBarHelper.showTopSnackBar(
          msgContext, 'Error inesperado: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envolvemos en un Scaffold para que el SnackBar se muestre por encima del modal
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
            children: [
              Text(
                'Escribir Reseña',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),

              // --- Selector de Estrellas (Valoración) ---
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
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

              // --- Campo de Texto (Opcional) ---
              _buildInputField(
                context,
                controller: _textoController,
                labelText: 'Reseña (opcional)',
                hintText: 'Escribe tu opinión...',
                maxLines: 5,
                validator: (value) {
                  if (value != null && value.length > 2000) {
                    return 'Máximo 2000 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              // --- Botón de Enviar ---
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

  // --- Helpers de UI ---
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
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
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