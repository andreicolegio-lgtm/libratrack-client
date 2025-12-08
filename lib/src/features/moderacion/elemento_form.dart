import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/api_client.dart';
import '../../core/services/admin_service.dart';
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/services/elemento_service.dart';
import '../../model/elemento_relacion.dart';
import '../../core/utils/error_translator.dart';
import '../../core/services/tipo_service.dart';
import '../../model/tipo.dart';
import '../../core/widgets/genre_selector_widget.dart';
import '../../core/widgets/content_type_progress_forms.dart';

class ElementoFormScreen extends StatefulWidget {
  final Elemento? elemento;

  const ElementoFormScreen({super.key, this.elemento});

  bool get isEditMode => elemento != null;

  @override
  State<ElementoFormScreen> createState() => _AdminElementoFormScreenState();
}

class _AdminElementoFormScreenState extends State<ElementoFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final AdminService _adminService;
  late final ApiClient _apiClient;
  late final ElementoService _elementoService;
  late final TipoService _tipoService;

  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDataLoaded = false;

  // Controladores
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _generosController = TextEditingController();
  final TextEditingController _episodiosPorTemporadaController =
      TextEditingController();
  final TextEditingController _totalUnidadesController =
      TextEditingController();
  final TextEditingController _totalCapitulosLibroController =
      TextEditingController();
  final TextEditingController _totalPaginasLibroController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _tipoSeleccionado;
  String?
      _estadoPublicacionSeleccionado; // Nueva variable para el estado de publicación
  List<Tipo> _tipos = [];

  // Relaciones (Secuelas/Precuelas)
  List<ElementoRelacion> _allElementos = [];
  final Set<int> _selectedSecuelaIds = {};

  // Imagen
  XFile? _pickedImage;
  String? _uploadedImageUrl;

  // New state variable for content status
  String _estadoContenido = 'OFICIAL';

  @override
  void initState() {
    super.initState();
    _adminService = context.read<AdminService>();
    _apiClient = context.read<ApiClient>();
    _elementoService = context.read<ElementoService>();
    _tipoService = context.read<TipoService>();

    _initForm();
  }

  Future<void> _initForm() async {
    // 1. Cargar datos iniciales si es edición
    if (widget.isEditMode) {
      final e = widget.elemento!;
      _tituloController.text = e.titulo;
      _descripcionController.text = e.descripcion;
      _generosController.text = e.generos.join(', ');
      _episodiosPorTemporadaController.text = e.episodiosPorTemporada ?? '';
      _totalUnidadesController.text = e.totalUnidades?.toString() ?? '';
      _totalCapitulosLibroController.text =
          e.totalCapitulosLibro?.toString() ?? '';
      _totalPaginasLibroController.text = e.totalPaginasLibro?.toString() ?? '';
      _durationController.text = e.duracion ?? '';
      _tipoSeleccionado = e.tipo;
      _uploadedImageUrl = e.urlImagen;
      _selectedSecuelaIds.addAll(e.secuelas.map((s) => s.id));
      _estadoPublicacionSeleccionado =
          e.estadoPublicacion; // Inicializar estado de publicación
    }

    // 2. Cargar Tipos y Lista de Elementos (para secuelas)
    try {
      final results = await Future.wait([
        _tipoService.fetchTipos('Error loading types'),
        _elementoService.getSimpleList(),
      ]);

      if (mounted) {
        setState(() {
          _tipos = results[0] as List<Tipo>;
          _allElementos = results[1] as List<ElementoRelacion>;

          // Validar que el tipo seleccionado exista
          if (_tipoSeleccionado != null &&
              !_tipos.any((t) => t.nombre == _tipoSeleccionado)) {
            _tipoSeleccionado = null;
          }
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando formulario: $e');
      // Podríamos mostrar un error aquí, pero el spinner se quedará cargando o la UI vacía
      if (mounted) {
        setState(() => _isDataLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _generosController.dispose();
    _episodiosPorTemporadaController.dispose();
    _totalUnidadesController.dispose();
    _totalCapitulosLibroController.dispose();
    _totalPaginasLibroController.dispose();
    _durationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Manejo de Imagen ---

  Future<void> _handlePickImage() async {
    final ImagePicker picker = ImagePicker();
    final l10n = AppLocalizations.of(context);

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
          // No borramos _uploadedImageUrl todavía para mantener la preview anterior si falla la subida
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(context, l10n.errorImagePick(e.toString()),
          isError: true);
    }
  }

  Future<void> _handleUploadImage() async {
    if (_pickedImage == null) {
      return;
    }

    setState(() => _isUploading = true);
    final l10n = AppLocalizations.of(context);
    try {
      // Usamos el ApiClient corregido
      final dynamic data = await _apiClient
          .upload('uploads', _pickedImage!)
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        setState(() {
          _uploadedImageUrl = data['url'];
          _pickedImage = null; // Limpiar local
        });
        SnackBarHelper.showTopSnackBar(context, l10n.snackbarImageUploadSuccess,
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // --- Guardado ---

  Future<void> _handleGuardar() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      SnackBarHelper.showTopSnackBar(
        context,
        l10n.adminFormErrorReviewFields,
        isError: true,
      );
      return;
    }

    // Subida automática si hay imagen pendiente
    if (_pickedImage != null) {
      await _handleUploadImage();
      // Si sigue habiendo imagen local (no se limpió), es que falló. Paramos.
      if (_pickedImage != null && _uploadedImageUrl == null) {
        return;
      }
    }

    setState(() => _isLoading = true);

    if (!mounted) {
      return; // Ensure the widget is still mounted
    }
    final navigator = Navigator.of(context);

    try {
      final Map<String, dynamic> body = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'tipoNombre': _tipoSeleccionado,
        'generosNombres': _generosController.text.trim(),
        'urlImagen': _uploadedImageUrl,
        'episodiosPorTemporada':
            _episodiosPorTemporadaController.text.trim().isEmpty
                ? null
                : _episodiosPorTemporadaController.text.trim(),
        'totalUnidades': int.tryParse(_totalUnidadesController.text),
        'totalCapitulosLibro':
            int.tryParse(_totalCapitulosLibroController.text),
        'totalPaginasLibro': int.tryParse(_totalPaginasLibroController.text),
        'duracion': _durationController.text.trim().isEmpty
            ? null
            : _durationController.text.trim(),
        'secuelaIds': _selectedSecuelaIds.toList(),
        'estadoPublicacion':
            _estadoPublicacionSeleccionado, // Añadir estado de publicación
        'estadoContenido': _estadoContenido, // Añadir estado de contenido
      };

      // Limpiar nulos
      body.removeWhere((key, value) => value == null);

      if (widget.isEditMode) {
        await _adminService.updateElemento(widget.elemento!.id, body);
      } else {
        await _adminService.crearElementoOficial(body);
      }

      if (!mounted) {
        return;
      }

      final String msg = widget.isEditMode
          ? l10n.adminFormUpdateSuccess
          : l10n.adminFormCreateSuccess;

      SnackBarHelper.showTopSnackBar(context, msg, isError: false);
      navigator.pop(true); // Retornar true para recargar lista
    } catch (e) {
      _handleError(e, AppLocalizations.of(context));
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
    String msg = l10n.errorUnexpected(e.toString());
    if (e is ApiException) {
      msg = ErrorTranslator.translate(context, e.message);
    }
    SnackBarHelper.showTopSnackBar(context, msg, isError: true);
  }

  String? _validateProgressData(AppLocalizations l10n) {
    // Si no hay tipo, no validamos progreso aún
    if (_tipoSeleccionado == null) {
      return null;
    }

    final type = _tipoSeleccionado;
    // Lógica personalizada según el tipo seleccionado
    if (type == 'Anime' && _totalUnidadesController.text.trim().isEmpty) {
      return l10n.validationEpisodesRequired;
    }
    if ((type == 'Manga' || type == 'Manhwa') &&
        _totalCapitulosLibroController.text.trim().isEmpty) {
      return l10n.validationChaptersRequired;
    }
    if (type == 'Book') {
      if (_totalPaginasLibroController.text.trim().isEmpty) {
        return l10n.validationPagesRequired;
      }
      // Capítulos en libros pueden ser opcionales, depende de la lógica
    }
    if (type == 'Series' &&
        _episodiosPorTemporadaController.text.trim().isEmpty) {
      return l10n.validationSeasonsRequired;
    }
    if (type == 'Movie' && _durationController.text.trim().isEmpty) {
      return l10n.validationDurationRequired;
    }

    return null; // Todo correcto
  }

  // --- UI ---

  // Método auxiliar para crear los "Fields" contenedores
  Widget _buildSectionField({
    required String label,
    required Widget child,
    String? errorText,
  }) {
    return InputDecorator(
      decoration: getCommonDecoration(label).copyWith(errorText: errorText),
      child: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: child,
      ),
    );
  }

  InputDecoration getCommonDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String title =
        widget.isEditMode ? l10n.adminFormEditTitle : l10n.adminFormCreateTitle;
    final String btnText = widget.isEditMode
        ? l10n.adminFormEditButton
        : l10n.adminFormCreateButton;

    if (!_isDataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      // Protege el contenido (especialmente el final del scroll) de la barra de navegación transparente
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Imagen
                _buildImageUploader(l10n),
                const SizedBox(height: 24),

                // Título
                _buildInputField(
                  controller: _tituloController,
                  label: l10n.adminFormTitleLabel,
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.validationTitleRequired
                      : null,
                ),
                const SizedBox(height: 24),

                // Descripción
                _buildInputField(
                  controller: _descripcionController,
                  label: l10n.adminFormDescLabel,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Tipo
                _buildTipoDropdown(l10n),
                const SizedBox(height: 24),

                // FIELD: GENRE
                FormField<String>(
                  validator: (_) {
                    return _generosController.text.isEmpty
                        ? l10n.validationGenresRequired
                        : null;
                  },
                  builder: (FormFieldState<String> state) {
                    return _buildSectionField(
                      label: l10n.labelGenre,
                      errorText: state.errorText,
                      child: _buildGenerosField(l10n),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // FIELD: PROGRESS DATA
                if (_tipoSeleccionado != 'Video Game') ...[
                  FormField<String>(
                    validator: (_) => _validateProgressData(l10n),
                    builder: (FormFieldState<String> state) {
                      return _buildSectionField(
                        label: l10n.labelProgressData,
                        errorText: state.errorText,
                        child: ContentTypeProgressForms(
                          selectedTypeKey: _tipoSeleccionado,
                          episodesController: _episodiosPorTemporadaController,
                          chaptersController: _totalCapitulosLibroController,
                          pagesController: _totalPaginasLibroController,
                          durationController: _durationController,
                          unitsController: _totalUnidadesController,
                          l10n: l10n,
                          hasError: state.hasError, // Nuevo parámetro
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // FIELD: SEQUELS
                _buildSectionField(
                  label: l10n.labelSequels,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.search),
                          label: Text(l10n.actionAddRelation),
                          onPressed: _openSearchDialog,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSecuelasChips(l10n),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // FIELD: ESTADO DE PUBLICACIÓN
                _buildAvailabilityDropdown(l10n),

                const SizedBox(height: 24),

                // FIELD: ESTADO DEL CONTENIDO
                _buildContentStateDropdown(l10n),

                const SizedBox(height: 32),

                // Botón Guardar
                FilledButton(
                  onPressed:
                      (_isLoading || _isUploading) ? null : _handleGuardar,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(btnText,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader(AppLocalizations l10n) {
    final theme = Theme.of(context);
    Widget content;
    bool hasImage = _pickedImage != null || _uploadedImageUrl != null;

    if (_pickedImage != null) {
      content = Image.file(File(_pickedImage!.path), fit: BoxFit.cover);
    } else if (_uploadedImageUrl != null) {
      content = CachedNetworkImage(
        imageUrl: _uploadedImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(l10n.adminFormImageTitle,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ],
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: (_isLoading || _isUploading) ? null : _handlePickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: content,
              ),
            ),
            // Botón para quitar la imagen
            if (hasImage && !_isLoading && !_isUploading)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _pickedImage = null;
                      _uploadedImageUrl = null;
                    });
                  },
                ),
              ),
          ],
        ),
        // Ocultar botón de subida si ya se subió (es decir, _pickedImage es null)
        if (_pickedImage != null && !_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FilledButton.icon(
              onPressed: _handleUploadImage,
              icon: const Icon(Icons.upload),
              label: Text(l10n.adminFormImageUpload),
            ),
          ),
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(l10n.adminFormImageUploading),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: getCommonDecoration(label),
    );
  }

  Widget _buildTipoDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _tipoSeleccionado,
      items: _tipos
          .map((t) => DropdownMenuItem(value: t.nombre, child: Text(t.nombre)))
          .toList(),
      onChanged: (v) => setState(() => _tipoSeleccionado = v),
      decoration: getCommonDecoration(l10n.adminFormTypeLabel),
      validator: (v) => v == null ? l10n.validationTypeRequired : null,
    );
  }

  Widget _buildGenerosField(AppLocalizations l10n) {
    // Encontramos el objeto Tipo seleccionado para pasar sus géneros válidos
    final selectedTypeObj = _tipos.firstWhere(
      (t) => t.nombre == _tipoSeleccionado,
      orElse: () => const Tipo(id: 0, nombre: '', validGenres: []),
    );

    return GenreSelectorWidget(
      selectedTypes: _tipoSeleccionado != null ? [selectedTypeObj] : [],
      initialGenres: _generosController.text
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((e) => e.trim())
          .toList(),
      onChanged: (genres) {
        setState(() {
          _generosController.text = genres.join(', ');
        });
      },
    );
  }

  Widget _buildSecuelasChips(AppLocalizations l10n) {
    final selectedObjects =
        _allElementos.where((e) => _selectedSecuelaIds.contains(e.id)).toList();

    if (selectedObjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
        child: Text(
          l10n.labelNoRelations,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color ??
                Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: selectedObjects.map((item) {
        return Chip(
          avatar: item.urlImagen != null
              ? CircleAvatar(backgroundImage: NetworkImage(item.urlImagen!))
              : null,
          label: Text(item.titulo),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedSecuelaIds.remove(item.id);
            });
          },
        );
      }).toList(),
    );
  }

  void _openSearchDialog() async {
    AppLocalizations.of(context);
    final Elemento? selected = await showSearch<Elemento?>(
      context: context,
      delegate: _ElementSearchDelegate(_elementoService),
    );

    if (selected != null && !_selectedSecuelaIds.contains(selected.id)) {
      // Evitar autoselección si es el mismo elemento que editamos
      if (widget.elemento != null && widget.elemento!.id == selected.id) {
        return;
      }
      setState(() {
        _selectedSecuelaIds.add(selected.id);
        // Añadimos a _allElementos temporalmente para poder mostrar el chip con título correcto
        // si no estaba ya en la lista precargada.
        if (!_allElementos.any((e) => e.id == selected.id)) {
          _allElementos.add(ElementoRelacion(
              id: selected.id,
              titulo: selected.titulo,
              urlImagen: selected.urlImagen));
        }
      });
    }
  }

  Widget _buildAvailabilityDropdown(AppLocalizations l10n) {
    // Definición de los estados exactos solicitados (Clave Backend -> Texto Visible)
    final Map<String, String> statusOptions = {
      'RELEASING': 'Releasing',
      'AVAILABLE': 'Available',
      'FINISHED': 'Finished',
      'ANNOUNCED': 'Announced',
      'CANCELLED': 'Cancelled',
      'PAUSED': 'Paused',
    };

    return DropdownButtonFormField<String>(
      initialValue: _estadoPublicacionSeleccionado,
      // Generamos la lista de items mapeando las opciones
      items: statusOptions.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (value) =>
          setState(() => _estadoPublicacionSeleccionado = value),
      validator: (value) =>
          value == null ? l10n.validationAvailabilityRequired : null,
      // Usamos getCommonDecoration para mantener el estilo idéntico al campo "Type"
      decoration: getCommonDecoration(l10n.labelAvailability),
    );
  }

  Widget _buildContentStateDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _estadoContenido,
      decoration: InputDecoration(
        labelText: l10n.labelContentStatus,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
            value: 'COMUNITARIO', child: Text(l10n.contentStatusCommunity)),
        DropdownMenuItem(
            value: 'OFICIAL', child: Text(l10n.contentStatusOfficial)),
      ],
      onChanged: (value) {
        setState(() {
          _estadoContenido = value!;
        });
      },
    );
  }
}

class _ElementSearchDelegate extends SearchDelegate<Elemento?> {
  final ElementoService _service;

  _ElementSearchDelegate(this._service);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (query.length < 2) {
      return Center(child: Text(l10n.searchHintShort));
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<PaginatedResponse<Elemento>>(
      future: _service.searchElementos(query: query, size: 10),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data?.content ?? [];
        if (items.isEmpty) {
          return Center(child: Text(l10n.searchNoResults));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: item.urlImagen != null
                  ? Image.network(item.urlImagen!, width: 40, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported),
              title: Text(item.titulo),
              subtitle: Text(item.tipo ?? ''),
              onTap: () => close(context, item),
            );
          },
        );
      },
    );
  }
}
