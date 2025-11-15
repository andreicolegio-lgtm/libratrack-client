// lib/src/features/propuestas/propuesta_form_screen.dart
// (¡CORREGIDO!)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/core/services/propuesta_service.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart'; // <-- ¡NUEVA IMPORTACIÓN!

/// --- ¡ACTUALIZADO (Sprint 3 / Petición 12)! ---
class PropuestaFormScreen extends StatefulWidget {
  const PropuestaFormScreen({super.key});

  @override
  State<PropuestaFormScreen> createState() => _PropuestaFormScreenState();
}

class _PropuestaFormScreenState extends State<PropuestaFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // --- ¡CORREGIDO (Error 1)! ---
  // Se elimina la instancia local. Se obtendrá de Provider.
  // final PropuestaService _propuestaService = PropuestaService();
  // ---

  bool _isLoading = false;

  // Controladores para los campos
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tipoController = TextEditingController();
  final _generosController = TextEditingController();
  // final _imagenUrlController = TextEditingController(); // <-- ¡ELIMINADO!

  final _episodiosPorTemporadaController = TextEditingController();
  final _totalUnidadesController = TextEditingController();
  final _totalCapitulosLibroController = TextEditingController();
  final _totalPaginasLibroController = TextEditingController();

  String _tipoSeleccionado = "";

  @override
  void initState() {
    super.initState();
    _tipoController.addListener(_actualizarCamposDinamicos);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tipoController.removeListener(_actualizarCamposDinamicos);
    _tipoController.dispose();
    _generosController.dispose();
    // _imagenUrlController.dispose(); // <-- ¡ELIMINADO!
    _episodiosPorTemporadaController.dispose();
    _totalUnidadesController.dispose();
    _totalCapitulosLibroController.dispose();
    _totalPaginasLibroController.dispose();
    super.dispose();
  }

  void _actualizarCamposDinamicos() {
    setState(() {
      _tipoSeleccionado = _tipoController.text.trim().toLowerCase();
    });
  }

  Future<void> _submitPropuesta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context);
    
    // --- ¡CORREGIDO (Error 1)! ---
    // Obtenemos el servicio desde Provider
    final propuestaService = context.read<PropuestaService>();
    // ---

    try {
      // --- ¡CORREGIDO (Error 2)! ---
      // 1. Creamos el body Map que el servicio 'crearPropuesta' espera
      final Map<String, dynamic> body = {
        'tituloSugerido': _tituloController.text,
        'descripcionSugerida': _descripcionController.text,
        'tipoSugerido': _tipoController.text,
        'generosSugeridos': _generosController.text,
        'episodiosPorTemporada': _episodiosPorTemporadaController.text.isEmpty
            ? null
            : _episodiosPorTemporadaController.text,
        'totalUnidades': _totalUnidadesController.text.isEmpty
            ? null
            : int.tryParse(_totalUnidadesController.text),
        'totalCapitulosLibro': _totalCapitulosLibroController.text.isEmpty
            ? null
            : int.tryParse(_totalCapitulosLibroController.text),
        'totalPaginasLibro': _totalPaginasLibroController.text.isEmpty
            ? null
            : int.tryParse(_totalPaginasLibroController.text),
      };
      // Eliminamos campos opcionales nulos
      body.removeWhere((key, value) => value == null);

      // 2. Llamamos al método renombrado 'crearPropuesta' con el Map
      await propuestaService.crearPropuesta(body);
      // ---

      if (!mounted) return;

      SnackBarHelper.showTopSnackBar(
          msgContext, '¡Propuesta enviada con éxito! Gracias por tu contribución.',
          isError: false);

      navContext.pop();
      
    // --- ¡MEJORADO! ---
    // Capturamos la excepción específica de la API
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          msgContext,
          'Error al enviar la propuesta: $e', // Usamos el mensaje limpio
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          msgContext,
          'Error inesperado: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proponer Elemento',
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Campos Básicos ---
              _buildInputField(
                context,
                controller: _tituloController,
                labelText: 'Título Sugerido',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                controller: _descripcionController,
                labelText: 'Descripción Breve',
                maxLines: 4,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'La descripción es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                controller: _tipoController,
                labelText: 'Tipo (Ej. Serie, Libro, Anime)',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'El tipo es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                controller: _generosController,
                labelText: 'Géneros (separados por coma)',
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Los géneros son obligatorios'
                    : null,
              ),

              // --- CAMPO DE URL DE IMAGEN ELIMINADO (Petición 12) ---

              // --- Campos de Progreso Dinámicos ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              Text('Datos de Progreso (Opcional)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // 1. Para Series
              if (_tipoSeleccionado == 'serie')
                _buildInputField(
                  context,
                  controller: _episodiosPorTemporadaController,
                  labelText: 'Episodios por Temporada',
                  hintText: 'Ej. 10,8,12 (para T1, T2, T3)',
                ),

              // 2. Para Libros
              if (_tipoSeleccionado == 'libro') ...[
                _buildInputField(
                  context,
                  controller: _totalCapitulosLibroController,
                  labelText: 'Total Capítulos (Libro)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  controller: _totalPaginasLibroController,
                  labelText: 'Total Páginas (Libro)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],

              // 3. Para Anime o Manga
              if (_tipoSeleccionado == 'anime' || _tipoSeleccionado == 'manga')
                _buildInputField(
                  context,
                  controller: _totalUnidadesController,
                  labelText: _tipoSeleccionado == 'anime'
                      ? 'Total Episodios (Anime)'
                      : 'Total Capítulos (Manga)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

              // 4. Para Película o Videojuego
              if (_tipoSeleccionado != 'serie' &&
                  _tipoSeleccionado != 'libro' &&
                  _tipoSeleccionado != 'anime' &&
                  _tipoSeleccionado != 'manga' &&
                  _tipoSeleccionado.isNotEmpty)
                Text(
                  'El tipo "${_tipoController.text}" no requiere datos de progreso.',
                  style: Theme.of(context).textTheme.bodyMedium,
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
                onPressed: _isLoading ? null : _submitPropuesta,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
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

  // ... (Widget _buildInputField sin cambios)
  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
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
}