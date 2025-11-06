// lib/src/features/propuestas/propuesta_form_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/propuesta_service.dart';

/// Pantalla con el formulario para proponer un nuevo elemento (RF13).
///
/// Corresponde al Mockup 8.
/// Es un [StatefulWidget] para gestionar el estado del formulario y de carga.
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

  // ===================================================================
  // LÓGICA DE ENVÍO (RF13)
  // ===================================================================

  Future<void> _handleProponer() async {
    // 1. Validar todos los campos del formulario
    if (!_formKey.currentState!.validate()) {
      return; // Detener si la validación falla
    }

    // 2. Iniciar el estado de carga
    setState(() {
      _isLoading = true;
    });

    final msgContext = ScaffoldMessenger.of(context); // Buena práctica
    final navContext = Navigator.of(context);

    try {
      // 3. Llamar al servicio que creamos en 110-JJ
      await _propuestaService.proponerElemento(
        titulo: _tituloController.text,
        descripcion: _descripcionController.text,
        tipo: _tipoController.text,
        generos: _generosController.text,
      );

      // 4. (ÉXITO) Notificar al usuario y limpiar el formulario
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formKey.currentState?.reset(); // Limpia los errores de validación
        _tituloController.clear();
        _descripcionController.clear();
        _tipoController.clear();
        _generosController.clear();
      });

      msgContext.showSnackBar(
        const SnackBar(
          content: Text('¡Propuesta enviada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 5. Opcional: Volver a la pantalla anterior
      navContext.pop();

    } catch (e) {
      // 6. (ERROR) Mostrar error de la API (ej. "Bad Request")
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  // ===================================================================
  // LIMPIEZA
  // ===================================================================

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tipoController.dispose();
    _generosController.dispose();
    super.dispose();
  }

  // ===================================================================
  // INTERFAZ DE USUARIO (UI)
  // ===================================================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proponer un elemento'),
      ),
      body: Form(
        key: _formKey, // Asocia la clave al formulario
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Título Sugerido ---
              _buildInputField(
                controller: _tituloController,
                labelText: 'Título Sugerido',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // --- Descripción Sugerida ---
              _buildInputField(
                controller: _descripcionController,
                labelText: 'Descripción Sugerida',
                maxLines: 5, // Campo más grande para la descripción
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              
              // --- Tipo Sugerido ---
              _buildInputField(
                controller: _tipoController,
                labelText: 'Tipo Sugerido (ej. Serie, Libro, Película)',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El tipo es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              
              // --- Género Sugerido ---
              _buildInputField(
                controller: _generosController,
                labelText: 'Géneros Sugeridos',
                // Coincide con el Mockup 8
                hintText: 'Separar con comas (,)', 
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Se requiere al menos un género.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),
              
              // --- Botón Enviar Propuesta ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                // Deshabilita el botón mientras carga
                onPressed: _isLoading ? null : _handleProponer, 
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Enviar Propuesta',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para construir los campos de texto
  /// (Reutilizado de profile_screen.dart)
  Widget _buildInputField({
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
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