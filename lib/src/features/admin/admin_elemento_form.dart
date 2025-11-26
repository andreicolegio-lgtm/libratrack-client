import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/api_client.dart';
import '../../core/services/admin_service.dart';
import '../../model/elemento.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/services/elemento_service.dart';
import '../../model/elemento_relacion.dart';
import '../../core/utils/error_translator.dart';
import '../../core/services/tipo_service.dart';
import '../../model/tipo.dart';
import '../../core/widgets/genre_selector_widget.dart';
import '../../core/widgets/content_type_progress_forms.dart';

class AdminElementoFormScreen extends StatefulWidget {
  final Elemento? elemento;

  const AdminElementoFormScreen({super.key, this.elemento});

  bool get isEditMode => elemento != null;

  @override
  State<AdminElementoFormScreen> createState() =>
      _AdminElementoFormScreenState();
}

class _AdminElementoFormScreenState extends State<AdminElementoFormScreen> {
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
  List<Tipo> _tipos = [];

  // Relaciones (Secuelas/Precuelas)
  List<ElementoRelacion> _allElementos = [];
  final Set<int> _selectedSecuelaIds = {};

  // Imagen
  XFile? _pickedImage;
  String? _uploadedImageUrl;

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
      final dynamic data = await _apiClient.upload('uploads', _pickedImage!);
      final String url = data['url'];

      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _pickedImage = null; // Limpiar selección local ya que se subió
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(context, l10n.snackbarImageUploadSuccess,
            isError: false);
      }
    } catch (e) {
      _handleError(e, l10n);
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // --- Guardado ---

  Future<void> _handleGuardar() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null && _pickedImage == null) {
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarImageUploadRequired,
          isError: true);
      return;
    }

    // Si hay una imagen seleccionada pero no subida, avisar o subir automáticamente
    if (_pickedImage != null) {
      await _handleUploadImage();
      if (_uploadedImageUrl == null) {
        return; // Falló la subida
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
          ? l10n.snackbarAdminElementUpdated
          : l10n.snackbarAdminElementCreated;

      SnackBarHelper.showTopSnackBar(context, msg, isError: false);
      navigator.pop(true); // Retornar true para recargar lista
    } catch (e) {
      _handleError(e, l10n);
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

  // --- UI ---

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildImageUploader(l10n),
              const SizedBox(height: 24),
              _buildInputField(
                controller: _tituloController,
                label: l10n.adminFormTitleLabel,
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.validationTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _descripcionController,
                label: l10n.adminFormDescLabel,
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.validationDescRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTipoDropdown(l10n),
              const SizedBox(height: 16),
              _buildGenerosField(l10n),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider()),
              Text(l10n.adminFormProgressTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ContentTypeProgressForms(
                selectedTypeKey: _tipoSeleccionado,
                episodesController: _episodiosPorTemporadaController,
                chaptersController: _totalCapitulosLibroController,
                pagesController: _totalPaginasLibroController,
                durationController: _durationController,
                unitsController: _totalUnidadesController,
                l10n: l10n,
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider()),
              _buildSecuelasSelector(l10n),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: (_isLoading || _isUploading) ? null : _handleGuardar,
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
    );
  }

  Widget _buildImageUploader(AppLocalizations l10n) {
    final theme = Theme.of(context);
    Widget content;

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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
      ),
    );
  }

  Widget _buildTipoDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _tipoSeleccionado,
      items: _tipos
          .map((t) => DropdownMenuItem(value: t.nombre, child: Text(t.nombre)))
          .toList(),
      onChanged: (v) => setState(() => _tipoSeleccionado = v),
      decoration: InputDecoration(
        labelText: l10n.adminFormTypeLabel,
        border: const OutlineInputBorder(),
        filled: true,
      ),
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

  Widget _buildSecuelasSelector(AppLocalizations l10n) {
    // Filtrar para no mostrarse a sí mismo
    final candidates = widget.elemento == null
        ? _allElementos
        : _allElementos.where((e) => e.id != widget.elemento!.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.adminFormSequelsTitle,
            style: Theme.of(context).textTheme.titleMedium),
        Text(l10n.adminFormSequelsSubtitle,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withAlpha(100)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final item = candidates[index];
              final isSelected = _selectedSecuelaIds.contains(item.id);
              return CheckboxListTile(
                title: Text(item.titulo),
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSecuelaIds.add(item.id);
                    } else {
                      _selectedSecuelaIds.remove(item.id);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
