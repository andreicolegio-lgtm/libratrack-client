// Archivo: lib/src/features/admin/admin_elemento_form.dart
// (¡MODIFICADO POR GEMINI PARA AÑADIR RELACIONES!)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; 

import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/services/admin_service.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart'; 

// --- ¡NUEVAS IMPORTACIONES AÑADIDAS POR GEMINI! ---
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/model/elemento_relacion.dart';
// ---

/// Formulario para que un Admin/Mod CREE (Petición 15) o EDITE (Petición 8) un Elemento.
/// --- ¡ACTUALIZADO (Sprint 10 / Relaciones)! ---
class AdminElementoFormScreen extends StatefulWidget {
  // Si 'elemento' es null, estamos en modo CREAR.
  // Si 'elemento' no es null, estamos en modo EDITAR.
  final Elemento? elemento;

  const AdminElementoFormScreen({super.key, this.elemento});

  // Helper para saber si estamos en modo Edición
  bool get isEditMode => elemento != null;

  @override
  State<AdminElementoFormScreen> createState() => _AdminElementoFormScreenState();
}

class _AdminElementoFormScreenState extends State<AdminElementoFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Servicios
  late final AdminService _adminService;
  late final ApiClient _apiClient;
  // --- ¡NUEVO SERVICIO AÑADIDO POR GEMINI! ---
  late final ElementoService _elementoService;
  // ---

  bool _isLoading = false;
  bool _isUploading = false;

  // Controladores
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tipoController = TextEditingController();
  final _generosController = TextEditingController();
  final _episodiosPorTemporadaController = TextEditingController();
  final _totalUnidadesController = TextEditingController();
  final _totalCapitulosLibroController = TextEditingController();
  final _totalPaginasLibroController = TextEditingController();

  String _tipoSeleccionado = "";

  // --- ¡NUEVOS CAMPOS DE ESTADO PARA RELACIONES! (Añadidos por Gemini) ---
  late Future<List<ElementoRelacion>> _elementosFuture;
  List<ElementoRelacion> _allElementos = []; // Lista completa
  final Set<int> _selectedSecuelaIds = {}; // IDs de las secuelas seleccionadas
  // ---

  // Estado de Imágenes
  XFile? _pickedImage; 
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();

    // Obtenemos los servicios desde Provider.
    _adminService = context.read<AdminService>();
    _apiClient = context.read<ApiClient>();
    // --- ¡NUEVA LÍNEA AÑADIDA POR GEMINI! ---
    _elementoService = context.read<ElementoService>();
    // ---

    // Si estamos en modo Editar, rellenamos el formulario
    if (widget.isEditMode) {
      final e = widget.elemento!;
      _tituloController.text = e.titulo;
      _descripcionController.text = e.descripcion;
      _tipoController.text = e.tipo;
      _generosController.text = e.generos.join(', ');
      _episodiosPorTemporadaController.text = e.episodiosPorTemporada ?? '';
      _totalUnidadesController.text = e.totalUnidades?.toString() ?? '';
      _totalCapitulosLibroController.text = e.totalCapitulosLibro?.toString() ?? '';
      _totalPaginasLibroController.text = e.totalPaginasLibro?.toString() ?? '';
      _tipoSeleccionado = e.tipo.toLowerCase();
      _uploadedImageUrl = e.urlImagen; // <-- Cargamos la imagen existente

      // --- ¡NUEVA LÓGICA DE PRE-SELECCIÓN! (Añadida por Gemini) ---
      // Pre-seleccionar Secuelas (asume que 'elemento.dart' fue actualizado)
      _selectedSecuelaIds.addAll(e.secuelas.map((s) => s.id));
      // ---
    }

    // --- ¡NUEVA CARGA DE DATOS! (Añadida por Gemini) ---
    // Cargar la lista simple de todos los elementos para el selector
    _elementosFuture = _elementoService.getSimpleElementoList();
    _elementosFuture.then((lista) {
      if (mounted) {
        setState(() {
          _allElementos = lista;
        });
      }
    });
    // ---

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

  Future<void> _handlePickImage() async {
    // ... (Tu código de _handlePickImage no cambia) ...
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image; 
          _uploadedImageUrl = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(
        ScaffoldMessenger.of(context), 'Error al seleccionar imagen: $e',
        isError: true);
    }
  }

  Future<void> _handleUploadImage() async {
    // ... (Tu código de _handleUploadImage no cambia) ...
    if (_pickedImage == null) return;
    setState(() {
      _isUploading = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      final dynamic data = await _apiClient.upload('uploads', _pickedImage!);
      final String url = data['url'];

      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(msgContext, '¡Imagen subida!',
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(msgContext, e.toString(), isError: true);
      }
    }
  }

  /// Lógica para "Guardar" (Crear o Editar)
  Future<void> _handleGuardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validamos la imagen
    if (_uploadedImageUrl == null) {
      SnackBarHelper.showTopSnackBar(ScaffoldMessenger.of(context),
          'Por favor, sube una imagen de portada.',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context);

    try {
      // 1. Creamos el "Body" (coincide con ElementoFormDTO.java)
      final Map<String, dynamic> body = {
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'tipoNombre': _tipoController.text,
        'generosNombres': _generosController.text,
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
            
        // --- ¡NUEVO CAMPO EN EL MAPA! (Añadido por Gemini) ---
        "secuelaIds": _selectedSecuelaIds.toList(),
        // ---
      };
      body.removeWhere((key, value) => value == null);

      // 2. Decidimos si llamar a "Crear" o "Actualizar"
      if (widget.isEditMode) {
        // --- MODO EDICIÓN (Petición 8) ---
        await _adminService.updateElemento(widget.elemento!.id, body);
      } else {
        // --- MODO CREACIÓN (Petición 15) ---
        await _adminService.crearElementoOficial(body);
      }

      if (!mounted) return;

      final successMessage = widget.isEditMode
          ? '¡Elemento actualizado!'
          : '¡Elemento OFICIAL creado!';

      SnackBarHelper.showTopSnackBar(msgContext, successMessage, isError: false);
      navContext.pop(true); // Devolvemos 'true' para refrescar la pantalla anterior

    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          msgContext,
          'Error al guardar: $e', // Ya no necesitamos replaceFirst
          isError: true,
        );
      }
    } catch (e) {
      // Captura para cualquier otro error inesperado
       if (mounted) {
        setState(() { _isLoading = false; });
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
    final String tituloPantalla =
        widget.isEditMode ? 'Editar Elemento' : 'Crear Elemento Oficial';
    final String botonGuardar =
        widget.isEditMode ? 'Guardar Cambios' : 'Crear Elemento';

    return Scaffold(
      appBar: AppBar(
        title:
            Text(tituloPantalla, style: Theme.of(context).textTheme.titleLarge),
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
              Text('Datos de Progreso (Opcional)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // --- Lógica condicional ---
              // (Tu lógica de _tipoSeleccionado no cambia)
              if (_tipoSeleccionado == 'serie')
                _buildInputField(
                  context,
                  controller: _episodiosPorTemporadaController,
                  labelText: 'Episodios por Temporada',
                  hintText: 'Ej. 10,8,12 (para T1, T2, T3)',
                ),
              if (_tipoSeleccionado == 'libro')
                ...[
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
              if (_tipoSeleccionado == 'película' ||
                  _tipoSeleccionado == 'videojuego')
                Text(
                  'El tipo "${_tipoController.text}" no requiere datos de progreso.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              
              // --- ¡NUEVA SECCIÓN AÑADIDA POR GEMINI! ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              _buildSecuelasSelector(), // <-- Widget
              const SizedBox(height: 32.0),
              // ---

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isLoading || _isUploading ? null : _handleGuardar,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        botonGuardar,
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el selector/visor de imagen
  Widget _buildImageUploader() {
    // ... (Tu código de _buildImageUploader no cambia) ...
    Widget content;
    if (_pickedImage != null) {
      content = Image.file(File(_pickedImage!.path), fit: BoxFit.cover);
    } else if (_uploadedImageUrl != null) {
      content = CachedNetworkImage(
        imageUrl: _uploadedImageUrl!,
        fit: BoxFit.cover,
        placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
        errorWidget: (c, u, e) =>
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[600]),
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('Añadir portada', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
              onPressed: _isLoading || _isUploading ? null : _handlePickImage,
            ),
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

  // Widget _buildInputField (idéntico al de propuesta_form_screen)
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
    // ... (Tu código de _buildInputField no cambia) ...
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
        hintStyle:
            Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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

  // --- ¡NUEVO WIDGET AÑADIDO POR GEMINI! ---
  Widget _buildSecuelasSelector() {
    return FutureBuilder<List<ElementoRelacion>>(
      future: _elementosFuture,
      builder: (context, snapshot) {
        // Mostrar un loader simple mientras la lista de elementos carga
        if (snapshot.connectionState == ConnectionState.waiting && _allElementos.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Secuelas (Opcional)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }
        if (snapshot.hasError) {
          return Text('Error al cargar elementos: ${snapshot.error}');
        }

        // Usamos _allElementos (que se pobló en initState.then)
        // Filtramos el elemento actual (un elemento no puede ser secuela de sí mismo)
        final elementosDisponibles = _allElementos.where((el) {
          if (widget.elemento == null) return true; // "Crear"
          return el.id != widget.elemento!.id; // "Editar"
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Secuelas (Opcional)',
                style: Theme.of(context).textTheme.titleLarge),
            Text('Elementos que van DESPUÉS de este.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400])),
            const SizedBox(height: 16),
            Container(
              height: 300, // Altura fija para el contenedor scrollable
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  children: elementosDisponibles.map((ElementoRelacion el) {
                    final isSelected = _selectedSecuelaIds.contains(el.id);
                    return CheckboxListTile(
                      title: Text(el.titulo),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        if (selected == null) return;
                        setState(() {
                          if (selected) {
                            _selectedSecuelaIds.add(el.id);
                          } else {
                            _selectedSecuelaIds.remove(el.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // --- FIN DE WIDGET AÑADIDO ---
}