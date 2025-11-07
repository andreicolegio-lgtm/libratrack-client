// lib/src/features/propuestas/propuesta_form_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/propuesta_service.dart';

/// Pantalla con el formulario para proponer un nuevo elemento (RF13).
class PropuestaFormScreen extends StatefulWidget {
  const PropuestaFormScreen({super.key});

  @override
  State<PropuestaFormScreen> createState() => _PropuestaFormScreenState();
}

class _PropuestaFormScreenState extends State<PropuestaFormScreen> {
  // --- Servicios y Estado ---
  final PropuestaService _propuestaService = PropuestaService();
  bool _isLoading = false;

  // --- Formulario ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tipoController = TextEditingController();
  final _generosController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tipoController.dispose();
    _generosController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  // --- SNACKBAR HELPER ---
  SnackBar _buildTopSnackBar(BuildContext context, String message, {required Color color}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating, 
      duration: const Duration(seconds: 4),
      margin: EdgeInsets.only( 
        bottom: MediaQuery.of(context).size.height - 100,
        right: 20,
        left: 20,
      ),
    );
  }

  /// Lógica para enviar la propuesta (RF13)
  Future<void> _handleProponer() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() { _isLoading = true; });

    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context);

    try {
      await _propuestaService.proponerElemento(
        titulo: _tituloController.text,
        descripcion: _descripcionController.text,
        tipo: _tipoController.text,
        generos: _generosController.text,
        imagenUrl: _imagenUrlController.text.isEmpty ? null : _imagenUrlController.text, 
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formKey.currentState?.reset();
        _tituloController.clear();
        _descripcionController.clear();
        _tipoController.clear();
        _generosController.clear();
        _imagenUrlController.clear();
      });

      // Usa el helper
      msgContext.showSnackBar(
        _buildTopSnackBar(context, '¡Propuesta enviada con éxito!', color: Colors.green),
      );
      
      navContext.pop();

    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      // Usa el helper
      msgContext.showSnackBar(
        _buildTopSnackBar(context, e.toString().replaceFirst("Exception: ", ""), color: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proponer Elemento', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Título Sugerido ---
              _buildInputField(
                context,
                controller: _tituloController,
                labelText: 'Título Sugerido',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) { return 'El título es obligatorio.'; }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // --- Descripción Sugerida ---
              _buildInputField(
                context,
                controller: _descripcionController,
                labelText: 'Descripción Sugerida',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) { return 'La descripción es obligatoria.'; }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              
              // --- Tipo Sugerido ---
              _buildInputField(
                context,
                controller: _tipoController,
                labelText: 'Tipo Sugerido (ej. Serie, Libro)',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) { return 'El tipo es obligatorio.'; }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              
              // --- Género Sugerido ---
              _buildInputField(
                context,
                controller: _generosController,
                labelText: 'Géneros Sugeridos',
                hintText: 'Separar con comas (,)', 
                validator: (value) {
                  if (value == null || value.trim().isEmpty) { return 'Se requiere al menos un género.'; }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // --- URL de Imagen (Mejora 2) ---
              _buildInputField(
                context,
                controller: _imagenUrlController,
                labelText: 'URL Imagen Portada (Opcional)',
                hintText: 'https://example.com/portada.jpg',
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.startsWith('http')) {
                    return 'Debe ser una URL válida (ej. empezar con http).';
                  }
                  return null;
                }
              ),

              const SizedBox(height: 32.0),
              
              // --- Botón Enviar Propuesta ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isLoading ? null : _handleProponer, 
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Enviar Propuesta',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para un diseño uniforme de TextField (basado en el tema central)
  Widget _buildInputField(
    BuildContext context,
    {
      required TextEditingController controller,
      required String labelText,
      String? hintText,
      int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
    }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
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
}