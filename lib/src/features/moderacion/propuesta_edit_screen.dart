// lib/src/features/moderacion/propuesta_edit_screen.dart
// (¡CORREGIDO!)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/services/moderacion_service.dart';
import 'package:libratrack_client/src/model/propuesta.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart'; // <-- ¡NUEVA IMPORTACIÓN!

/// Pantalla para que un Moderador EDITE y APRUEBE una propuesta (Petición d).
/// --- ¡ACTUALIZADO (Sprint 3)! ---
class PropuestaEditScreen extends StatefulWidget {
  final Propuesta propuesta;

  const PropuestaEditScreen({super.key, required this.propuesta});

  @override
  State<PropuestaEditScreen> createState() => _PropuestaEditScreenState();
}

class _PropuestaEditScreenState extends State<PropuestaEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // --- ¡CORREGIDO (Error 1)! ---
  // Se eliminan las instancias locales y se declaran 'late final'
  late final ModeracionService _moderacionService;
  late final ApiClient _apiClient;
  // ---

  bool _isLoading = false; // Para el botón de "Aprobar"
  bool _isUploading = false; // Para el botón de "Subir Imagen"

  // Controladores
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _tipoController;
  late TextEditingController _generosController;
  late TextEditingController _episodiosPorTemporadaController;
  late TextEditingController _totalUnidadesController;
  late TextEditingController _totalCapitulosLibroController;
  late TextEditingController _totalPaginasLibroController;

  String _tipoSeleccionado = "";

  // --- ¡NUEVO ESTADO PARA IMÁGENES! (Petición 6) ---
  // --- ¡CORREGIDO (Error 2)! ---
  // Se almacena el XFile original, no el File
  XFile? _pickedImage; 
  String? _uploadedImageUrl; // La URL de GCS devuelta por la API

  @override
  void initState() {
    super.initState();
    
    // --- ¡CORREGIDO (Error 1)! ---
    // Obtenemos los servicios desde Provider
    _moderacionService = context.read<ModeracionService>();
    _apiClient = context.read<ApiClient>();
    // ---

    final p = widget.propuesta;
    _tituloController = TextEditingController(text: p.tituloSugerido);
    _descripcionController =
        TextEditingController(text: p.descripcionSugerida ?? '');
    _tipoController = TextEditingController(text: p.tipoSugerido);
    _generosController = TextEditingController(text: p.generosSugeridos);
    _episodiosPorTemporadaController =
        TextEditingController(text: p.episodiosPorTemporada ?? '');
    _totalUnidadesController =
        TextEditingController(text: p.totalUnidades?.toString() ?? '');
    _totalCapitulosLibroController =
        TextEditingController(text: p.totalCapitulosLibro?.toString() ?? '');
    _totalPaginasLibroController =
        TextEditingController(text: p.totalPaginasLibro?.toString() ?? '');
    _tipoSeleccionado = p.tipoSugerido.toLowerCase();
    _tipoController.addListener(_actualizarCamposDinamicos);
  }

  @override
  void dispose() {
    // ... (limpiamos todos los controllers) ...
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

  void _actualizarCamposDinamicos() {
    setState(() {
      _tipoSeleccionado = _tipoController.text.trim().toLowerCase();
    });
  }

  /// --- ¡NUEVO MÉTODO! (Petición 6) ---
  /// Abre la galería para seleccionar una imagen
  Future<void> _handlePickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          // --- ¡CORREGIDO (Error 2)! ---
          _pickedImage = image; // Se guarda el XFile
          _uploadedImageUrl = null; // Reseteamos la URL si se elige una nueva
        });
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(ScaffoldMessenger.of(context),
          'Error al seleccionar imagen: $e',
          isError: true);
    }
  }

  /// --- ¡NUEVO MÉTODO! (Petición 6) ---
  /// Sube la imagen seleccionada al endpoint /api/uploads
  Future<void> _handleUploadImage() async {
    if (_pickedImage == null) return;

    setState(() {
      _isUploading = true;
    });
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // --- ¡CORREGIDO (Errores 2 y 3)! ---
      // 1. Se añade el endpoint 'uploads'
      // 2. Se pasa el XFile '_pickedImage'
      // 3. Se extrae la 'url' del Map devuelto
      final dynamic data = await _apiClient.upload('uploads', _pickedImage!);
      final String url = data['url'];
      // ---

      if (mounted) {
        setState(() {
          _uploadedImageUrl = url; // Guardamos la URL de GCS
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(msgContext, '¡Imagen subida!',
            isError: false);
      }
    // --- ¡MEJORADO! ---
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(msgContext, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, 'Error inesperado: $e', isError: true);
      }
    }
  }

  /// Lógica para "Guardar y Aprobar" (RF15)
  Future<void> _handleAprobar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validamos que se haya subido una imagen
    if (_uploadedImageUrl == null) {
      SnackBarHelper.showTopSnackBar(ScaffoldMessenger.of(context),
          'Por favor, sube una imagen de portada antes de aprobar.',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context);

    try {
      // 1. Creamos el "Body" (que coincide con PropuestaUpdateDTO.java)
      final Map<String, dynamic> body = {
        'tituloSugerido': _tituloController.text,
        'descripcionSugerida': _descripcionController.text,
        'tipoSugerido': _tipoController.text,
        'generosSugeridos': _generosController.text,

        // --- ¡NUEVO! Enviamos la URL de la imagen ---
        'urlImagen': _uploadedImageUrl,

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
      body.removeWhere((key, value) => value == null);

      // 2. Llamamos al servicio de moderación
      // --- ¡CORREGIDO (Error 4)! ---
      // Se pasa el ID como String
      await _moderacionService.aprobarPropuesta(widget.propuesta.id, body);
      // ---

      if (!mounted) return;

      // 3. Cerramos la pantalla y devolvemos 'true'
      navContext.pop(true);
      
    // --- ¡MEJORADO! ---
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          msgContext,
          'Error al aprobar: $e', // Usamos el mensaje limpio
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
          'Error inesperado: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisar Propuesta',
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
            children: [
              Text(
                  'Propuesto por: ${widget.propuesta.proponenteUsername}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),

              // --- ¡NUEVO WIDGET DE IMAGEN! (Petición 6) ---
              _buildImageUploader(),
              const SizedBox(height: 24),

              // --- Campos Editables ---
              _buildInputField(
                context,
                controller: _tituloController,
                labelText: 'Título',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              // ... (resto de campos: desc, tipo, generos)
              _buildInputField(
                context,
                controller: _descripcionController,
                labelText: 'Descripción',
                maxLines: 4,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'La descripción es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                controller: _tipoController,
                labelText: 'Tipo (Ej. Serie, Libro)',
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

              // --- Campos de Progreso (Petición c y d) ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              Text('Datos de Progreso (¡Obligatorio!)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // ... (Lógica condicional de campos de progreso sin cambios) ...
              if (_tipoSeleccionado == 'serie')
                _buildInputField(
                  context,
                  controller: _episodiosPorTemporadaController,
                  labelText: 'Episodios por Temporada',
                  hintText: 'Ej. 10,8,12 (para T1, T2, T3)',
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Este campo es obligatorio para Series'
                      : null,
                ),
              if (_tipoSeleccionado == 'libro') ...[
                _buildInputField(
                  context,
                  controller: _totalCapitulosLibroController,
                  labelText: 'Total Capítulos (Libro)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Este campo es obligatorio para Libros'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  controller: _totalPaginasLibroController,
                  labelText: 'Total Páginas (Libro)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Este campo es obligatorio para Libros'
                      : null,
                ),
              ],
              if (_tipoSeleccionado == 'anime' || _tipoSeleccionado == 'manga')
                _buildInputField(
                  context,
                  controller: _totalUnidadesController,
                  labelText: _tipoSeleccionado == 'anime'
                      ? 'Total Episodios (Anime)'
                      : 'Total Capítulos (Manga)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Este campo es obligatorio'
                      : null,
                ),
              if (_tipoSeleccionado == 'película' ||
                  _tipoSeleccionado == 'videojuego')
                Text(
                  'El tipo "${_tipoController.text}" no requiere datos de progreso.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

              const SizedBox(height: 32.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
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

  /// --- ¡NUEVO WIDGET! (Petición 6) ---
  /// Muestra el selector/visor de imagen
  Widget _buildImageUploader() {
    Widget content;
    if (_pickedImage != null) {
      // 1. Imagen seleccionada, lista para subir
      // --- ¡CORREGIDO (Error 2)! ---
      // Se usa File(_pickedImage!.path) para mostrar el XFile
      content = Image.file(File(_pickedImage!.path), fit: BoxFit.cover);
      // ---
    } else if (_uploadedImageUrl != null) {
      // 2. Imagen ya subida, mostrando la URL
      content = Image.network(_uploadedImageUrl!, fit: BoxFit.cover);
    } else {
      // 3. Placeholder por defecto
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('Sin portada', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Visor
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: content,
          ),
        ),
        const SizedBox(height: 16),

        // Botones
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón 1: Elegir de la Galería
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
              onPressed: _isLoading || _isUploading ? null : _handlePickImage,
            ),

            // Botón 2: Subir
            ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Subiendo...' : 'Subir'),
              onPressed: _pickedImage == null || _isUploading || _isLoading
                  ? null
                  : _handleUploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        )
      ],
    );
  }

  // ... (Widget _buildInputField (el mismo de propuesta_form_screen))
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