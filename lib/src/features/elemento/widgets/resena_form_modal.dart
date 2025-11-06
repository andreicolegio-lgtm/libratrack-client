// lib/src/features/elemento/widgets/resena_form_modal.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/resena_service.dart';
import 'package:libratrack_client/src/model/resena.dart';

/// Un 'Modal Bottom Sheet' para escribir una nueva reseña (RF12).
class ResenaFormModal extends StatefulWidget {
  final int elementoId;

  const ResenaFormModal({super.key, required this.elementoId});

  @override
  State<ResenaFormModal> createState() => _ResenaFormModalState();
}

class _ResenaFormModalState extends State<ResenaFormModal> {
  // --- Servicios y Estado ---
  final ResenaService _resenaService = ResenaService();
  bool _isLoading = false;

  // --- Formulario ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  int _valoracion = 0; 

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
    // Validar que se haya seleccionado una valoración
    if (_valoracion == 0) {
      // ESTE ES EL SNACKBAR QUE FALLABA
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una valoración (1-5 estrellas).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });
    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context);

    try {
      // ... (Lógica de llamada al servicio sin cambios) ...
      final Resena nuevaResena = await _resenaService.crearResena(
        elementoId: widget.elementoId,
        valoracion: _valoracion,
        textoResena: _textoController.text.isEmpty ? null : _textoController.text,
      );

      // ... (Lógica de éxito sin cambios) ...
      if (!mounted) return;
      msgContext.showSnackBar(
        const SnackBar(
          content: Text('¡Reseña publicada!'),
          backgroundColor: Colors.green,
        ),
      );
      navContext.pop(nuevaResena); 
    } catch (e) {
      // ... (Lógica de error sin cambios) ...
      if (!mounted) return;
      setState(() { _isLoading = false; });
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- REFACTORIZADO ---
  @override
  Widget build(BuildContext context) {
    // 1. Envolvemos el contenido en un 'Scaffold'
    // Esto proporciona un 'ScaffoldMessenger' local para el modal.
    return Scaffold(
      // 2. Le damos un color de fondo para que coincida con el tema del modal
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 3. El resto de tu UI (Padding y Form) va dentro del 'body'
      body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Sigue siendo compacto
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escribir Reseña',
                style: Theme.of(context).textTheme.headlineSmall,
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
                        _valoracion >= estrella ? Icons.star : Icons.star_border,
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
              TextFormField(
                controller: _textoController,
                decoration: _buildInputDecoration(
                  labelText: 'Reseña (opcional)',
                  hintText: 'Escribe tu opinión...',
                ),
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
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: _isLoading ? null : _handleEnviarResena,
                child: _isLoading
                    ? _buildSmallSpinner()
                    : const Text(
                        'Publicar Reseña',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers de UI (sin cambios) ---
  InputDecoration _buildInputDecoration({required String labelText, String? hintText}) {
    // ... (código sin cambios)
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600]),
      labelStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
    );
  }
  
  Widget _buildSmallSpinner() {
    // ... (código sin cambios)
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }
}