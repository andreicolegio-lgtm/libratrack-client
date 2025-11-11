// lib/src/features/moderacion/propuesta_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:libratrack_client/src/core/services/moderacion_service.dart';
import 'package:libratrack_client/src/model/propuesta.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';

/// Pantalla para que un Moderador EDITE y APRUEBE una propuesta (Petición d).
class PropuestaEditScreen extends StatefulWidget {
  final Propuesta propuesta; // <-- Recibe la propuesta a editar

  const PropuestaEditScreen({super.key, required this.propuesta});

  @override
  State<PropuestaEditScreen> createState() => _PropuestaEditScreenState();
}

class _PropuestaEditScreenState extends State<PropuestaEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ModeracionService _moderacionService = ModeracionService();

  bool _isLoading = false;

  // Controladores para TODOS los campos
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _tipoController;
  late TextEditingController _generosController;
  
  late TextEditingController _episodiosPorTemporadaController;
  late TextEditingController _totalUnidadesController;
  late TextEditingController _totalCapitulosLibroController;
  late TextEditingController _totalPaginasLibroController;
  
  // Estado local para mostrar campos dinámicos
  String _tipoSeleccionado = "";

  @override
  void initState() {
    super.initState();
    
    // Rellenamos el formulario con los datos de la propuesta que recibimos
    final p = widget.propuesta;
    _tituloController = TextEditingController(text: p.tituloSugerido);
    _descripcionController = TextEditingController(text: p.descripcionSugerida ?? '');
    _tipoController = TextEditingController(text: p.tipoSugerido);
    _generosController = TextEditingController(text: p.generosSugeridos);
    
    _episodiosPorTemporadaController = TextEditingController(text: p.episodiosPorTemporada ?? '');
    _totalUnidadesController = TextEditingController(text: p.totalUnidades?.toString() ?? '');
    _totalCapitulosLibroController = TextEditingController(text: p.totalCapitulosLibro?.toString() ?? '');
    _totalPaginasLibroController = TextEditingController(text: p.totalPaginasLibro?.toString() ?? '');
    
    _tipoSeleccionado = p.tipoSugerido.toLowerCase();
    
    // Escuchamos los cambios en el campo "Tipo"
    _tipoController.addListener(_actualizarCamposDinamicos);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tipoController.removeListener(_actualizarCamposDinamicos);
    _tipoController.dispose();
    _generosController.dispose();
    _episodiosPorTemporadaController.dispose();
    _totalUnidadesController.dispose();
    _totalCapitulosLibroController.dispose();
    _totalPaginasLibroController.dispose();
    super.dispose();
  }
  
  /// Detecta el tipo y actualiza la UI
  void _actualizarCamposDinamicos() {
    setState(() {
      _tipoSeleccionado = _tipoController.text.trim().toLowerCase();
    });
  }

  /// Lógica para "Guardar y Aprobar" (RF15)
  Future<void> _handleAprobar() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    
    setState(() { _isLoading = true; });
    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context); 

    try {
      // 1. Creamos el "Body" (que coincide con PropuestaUpdateDTO.java)
      final Map<String, dynamic> body = {
        'tituloSugerido': _tituloController.text,
        'descripcionSugerida': _descripcionController.text,
        'tipoSugerido': _tipoController.text,
        'generosSugeridos': _generosController.text,
        
        'episodiosPorTemporada': _episodiosPorTemporadaController.text.isEmpty ? null : _episodiosPorTemporadaController.text,
        'totalUnidades': _totalUnidadesController.text.isEmpty ? null : int.tryParse(_totalUnidadesController.text),
        'totalCapitulosLibro': _totalCapitulosLibroController.text.isEmpty ? null : int.tryParse(_totalCapitulosLibroController.text),
        'totalPaginasLibro': _totalPaginasLibroController.text.isEmpty ? null : int.tryParse(_totalPaginasLibroController.text),
      };
      // Quitamos nulos para un JSON limpio
      body.removeWhere((key, value) => value == null);

      // 2. Llamamos al servicio de moderación
      await _moderacionService.aprobarPropuesta(widget.propuesta.id, body);

      if (!mounted) return;
      
      // 3. Cerramos la pantalla y devolvemos 'true'
      // Esto le dice a ModeracionPanelScreen que debe recargar.
      navContext.pop(true); 

    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        SnackBarHelper.showTopSnackBar(
          msgContext,
          'Error al aprobar: ${e.toString().replaceFirst("Exception: ", "")}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisar Propuesta', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Propuesto por: ${widget.propuesta.proponenteUsername}', 
                style: Theme.of(context).textTheme.bodyMedium
              ),
              const SizedBox(height: 24),
              
              // --- Campos Editables ---
              _buildInputField(
                context,
                controller: _tituloController,
                labelText: 'Título',
                validator: (value) => (value == null || value.isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                controller: _descripcionController,
                labelText: 'Descripción',
                maxLines: 4,
                validator: (value) => (value == null || value.isEmpty) ? 'La descripción es obligatoria' : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                controller: _tipoController,
                labelText: 'Tipo (Ej. Serie, Libro)',
                validator: (value) => (value == null || value.isEmpty) ? 'El tipo es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                controller: _generosController,
                labelText: 'Géneros (separados por coma)',
                validator: (value) => (value == null || value.isEmpty) ? 'Los géneros son obligatorios' : null,
              ),
              
              // --- Campos de Progreso (Petición c y d) ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              Text(
                'Datos de Progreso (¡Obligatorio!)', 
                style: Theme.of(context).textTheme.titleLarge
              ),
              const SizedBox(height: 16),
              
              // --- Lógica condicional ---
              
              // 1. Para Series
              if (_tipoSeleccionado == 'serie')
                _buildInputField(
                  context,
                  controller: _episodiosPorTemporadaController,
                  labelText: 'Episodios por Temporada',
                  hintText: 'Ej. 10,8,12 (para T1, T2, T3)',
                  validator: (value) => (value == null || value.isEmpty) ? 'Este campo es obligatorio para Series' : null,
                ),
                
              // 2. Para Libros
              if (_tipoSeleccionado == 'libro')
                ...[ 
                  _buildInputField(
                    context,
                    controller: _totalCapitulosLibroController,
                    labelText: 'Total Capítulos (Libro)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => (value == null || value.isEmpty) ? 'Este campo es obligatorio para Libros' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    context,
                    controller: _totalPaginasLibroController,
                    labelText: 'Total Páginas (Libro)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => (value == null || value.isEmpty) ? 'Este campo es obligatorio para Libros' : null,
                  ),
                ],
                
              // 3. Para Anime o Manga
              if (_tipoSeleccionado == 'anime' || _tipoSeleccionado == 'manga')
                _buildInputField(
                  context,
                  controller: _totalUnidadesController,
                  labelText: _tipoSeleccionado == 'anime' ? 'Total Episodios (Anime)' : 'Total Capítulos (Manga)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty) ? 'Este campo es obligatorio' : null,
                ),
                
              // 4. Para Película o Videojuego (No mostramos NADA)
              if (_tipoSeleccionado == 'película' || _tipoSeleccionado == 'videojuego')
                Text(
                  'El tipo "${_tipoController.text}" no requiere datos de progreso.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

              const SizedBox(height: 32.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600], // Botón de Aprobar
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isLoading ? null : _handleAprobar,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar y Aprobar',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Widget _buildInputField (el mismo de propuesta_form_screen))
  Widget _buildInputField(
    BuildContext context,
    {
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
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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