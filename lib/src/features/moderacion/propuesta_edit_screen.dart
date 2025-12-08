import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/api_client.dart';
import '../../core/services/moderacion_service.dart';
import '../../core/services/tipo_service.dart';
import '../../model/propuesta.dart';
import '../../model/tipo.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/widgets/genre_selector_widget.dart';
import '../../core/widgets/content_type_progress_forms.dart';

/// Pantalla para que un moderador revise, edite y apruebe una propuesta.
class PropuestaEditScreen extends StatefulWidget {
  final Propuesta propuesta;

  const PropuestaEditScreen({required this.propuesta, super.key});

  @override
  State<PropuestaEditScreen> createState() => _PropuestaEditScreenState();
}

class _PropuestaEditScreenState extends State<PropuestaEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final ModeracionService _moderacionService;
  late final ApiClient _apiClient;
  late final TipoService _tipoService;

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDataLoaded = false;

  // Controladores de Texto
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _generosController;

  // Controladores de Progreso
  late TextEditingController _episodiosPorTemporadaController;
  late TextEditingController _totalUnidadesController;
  late TextEditingController _totalCapitulosLibroController;
  late TextEditingController _totalPaginasLibroController;
  late TextEditingController _durationController;

  // Controlador de Comentarios (Nuevo)
  final TextEditingController _comentariosController = TextEditingController();

  // Estados Seleccionados
  String? _tipoSeleccionado;
  String? _estadoPublicacionSeleccionado;
  String _estadoContenido = 'COMUNITARIO'; // Valor por defecto solicitado

  List<Tipo> _tipos = [];

  // Gestión de Imagen
  XFile? _pickedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();

    _moderacionService = context.read<ModeracionService>();
    _apiClient = context.read<ApiClient>();
    _tipoService = context.read<TipoService>();

    _initControllers();
    _loadInitialData();
  }

  void _initControllers() {
    final Propuesta p = widget.propuesta;
    _tituloController = TextEditingController(text: p.tituloSugerido);
    _descripcionController =
        TextEditingController(text: p.descripcionSugerida ?? '');
    _generosController = TextEditingController(text: p.generosSugeridos);

    _episodiosPorTemporadaController =
        TextEditingController(text: p.episodiosPorTemporada ?? '');
    _totalUnidadesController =
        TextEditingController(text: p.totalUnidades?.toString() ?? '');
    _totalCapitulosLibroController =
        TextEditingController(text: p.totalCapitulosLibro?.toString() ?? '');
    _totalPaginasLibroController =
        TextEditingController(text: p.totalPaginasLibro?.toString() ?? '');
    _durationController = TextEditingController(text: p.duracion ?? '');

    _tipoSeleccionado = p.tipoSugerido;
    _uploadedImageUrl = p.urlImagen;

    // Valor por defecto para disponibilidad si no viene en la propuesta
    _estadoPublicacionSeleccionado = 'AVAILABLE';
  }

  Future<void> _loadInitialData() async {
    try {
      final tipos = await _tipoService.fetchTipos('Error loading types');

      if (mounted) {
        setState(() {
          _tipos = tipos;
          // Validar si el tipo sugerido existe en la lista oficial
          final existingType = _tipos.firstWhere(
            (t) =>
                t.nombre.toLowerCase() ==
                (_tipoSeleccionado?.toLowerCase() ?? ''),
            orElse: () => const Tipo(id: 0, nombre: '', validGenres: []),
          );

          if (existingType.id != 0) {
            _tipoSeleccionado = existingType.nombre;
          }
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error cargando tipos en edición: $e');
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
    _comentariosController.dispose();
    super.dispose();
  }

  // --- Lógica de Imagen ---

  Future<void> _handlePickImage() async {
    final ImagePicker picker = ImagePicker();
    final AppLocalizations l10n = AppLocalizations.of(context);

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
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
    final AppLocalizations l10n = AppLocalizations.of(context);

    try {
      final dynamic data = await _apiClient.upload('uploads', _pickedImage!);
      final String url = data['url'];

      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _pickedImage = null;
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

  // --- Lógica de Aprobación ---

  Future<void> _handleAprobar() async {
    final l10n = AppLocalizations.of(context);

    // 1. Validar formulario visualmente
    if (!_formKey.currentState!.validate()) {
      SnackBarHelper.showTopSnackBar(context, l10n.adminFormErrorReviewFields,
          isError: true);
      return;
    }

    // 2. Subir imagen si hay una nueva seleccionada
    if (_pickedImage != null) {
      await _handleUploadImage();
      // Si falló la subida (sigue habiendo imagen local pero no url remota), paramos.
      if (_pickedImage != null && _uploadedImageUrl == null) {
        return;
      }
    }

    setState(() => _isLoading = true);
    if (!mounted) {
      return;
    }
    final NavigatorState navContext = Navigator.of(context);

    try {
      // 3. Preparar datos limpios (Trim strings, parse ints safely)
      final Map<String, dynamic> body = {
        'tituloSugerido': _tituloController.text.trim(),
        'descripcionSugerida': _descripcionController.text.trim(),
        'tipoSugerido': _tipoSeleccionado,
        'generosSugeridos': _generosController.text.trim(),
        'urlImagen': _uploadedImageUrl,

        // Datos numéricos: Usamos trim() antes de parsear para evitar errores por espacios accidentales
        'episodiosPorTemporada':
            _episodiosPorTemporadaController.text.trim().isEmpty
                ? null
                : _episodiosPorTemporadaController.text.trim(),

        'totalUnidades': int.tryParse(_totalUnidadesController.text.trim()),
        'totalCapitulosLibro':
            int.tryParse(_totalCapitulosLibroController.text.trim()),
        'totalPaginasLibro':
            int.tryParse(_totalPaginasLibroController.text.trim()),

        'duracion': _durationController.text.trim().isEmpty
            ? null
            : _durationController.text.trim(),

        // Estados (Aseguramos que no sean nulos)
        'estadoPublicacion': _estadoPublicacionSeleccionado ?? 'AVAILABLE',
        'estadoContenido': _estadoContenido, // 'OFICIAL' o 'COMUNITARIO'
        'comentariosRevision': _comentariosController.text.trim(),
      };

      // 4. Limpieza de nulos: El backend podría quejarse si enviamos "key": null explícito
      body.removeWhere((key, value) => value == null || value == '');

      // Log para depuración (Verás esto en la consola de Flutter si falla)
      debugPrint('Enviando aprobación: $body');

      await _moderacionService.aprobarPropuesta(widget.propuesta.id, body);

      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarModProposalApproved,
          isError: false);
      navContext.pop(true); // Éxito
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

  // --- UI Helpers (Estilo ElementoForm) ---

  InputDecoration getCommonDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  Widget _buildSectionField({
    required String label,
    required Widget child,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                    color: hasError ? theme.colorScheme.error : Colors.grey),
              ),
              child: child,
            ),
            Positioned(
              left: 10,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: theme.scaffoldBackgroundColor,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    // CAMBIO: Usar el color del hint o onSurfaceVariant para coincidir con los Dropdowns
                    color: hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(errorText,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 12))),
      ],
    );
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_isDataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.modEditTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.modEditTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. Info del Proponente
                _buildProposerInfo(),
                const SizedBox(height: 24),

                // 2. Imagen
                _buildImageUploader(l10n),
                const SizedBox(height: 24),

                // 3. Título
                TextFormField(
                  controller: _tituloController,
                  decoration: getCommonDecoration(l10n.proposalFormTitleLabel),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.validationTitleRequired
                      : null,
                ),
                const SizedBox(height: 24),

                // 4. Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: getCommonDecoration(l10n.proposalFormDescLabel),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // 5. Tipo
                DropdownButtonFormField<String>(
                  initialValue: _tipoSeleccionado,
                  items: _tipos
                      .map((t) => DropdownMenuItem(
                          value: t.nombre, child: Text(t.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoSeleccionado = v),
                  decoration: getCommonDecoration(l10n.proposalFormTypeLabel),
                  validator: (v) =>
                      v == null ? l10n.validationTypeRequired : null,
                ),
                const SizedBox(height: 24),

                // 6. Género (Con estilo robusto)
                FormField<String>(
                  validator: (_) => _generosController.text.isEmpty
                      ? l10n.validationGenresRequired
                      : null,
                  builder: (state) => _buildSectionField(
                    label: l10n.labelGenre,
                    errorText: state.errorText,
                    child: _buildGenreSelector(),
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Progreso
                if (_tipoSeleccionado != 'Video Game') ...[
                  FormField<String>(
                    validator: (_) => _validateProgressData(),
                    builder: (state) => _buildSectionField(
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
                        hasError: state.hasError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 8. Disponibilidad
                DropdownButtonFormField<String>(
                  initialValue: _estadoPublicacionSeleccionado,
                  hint: Text(l10n.hintSelectAvailability),
                  items: [
                    DropdownMenuItem(
                        value: 'RELEASING', child: Text(l10n.statusReleasing)),
                    DropdownMenuItem(
                        value: 'FINISHED', child: Text(l10n.statusFinished)),
                    DropdownMenuItem(
                        value: 'ANNOUNCED', child: Text(l10n.statusAnnounced)),
                    DropdownMenuItem(
                        value: 'CANCELLED', child: Text(l10n.statusCancelled)),
                    DropdownMenuItem(
                        value: 'PAUSADO', child: Text(l10n.statusPaused)),
                    DropdownMenuItem(
                        value: 'AVAILABLE', child: Text(l10n.statusAvailable)),
                  ],
                  onChanged: (v) =>
                      setState(() => _estadoPublicacionSeleccionado = v),
                  validator: (v) => v == null ? l10n.validationRequired : null,
                  decoration: getCommonDecoration(l10n.labelAvailability),
                ),
                const SizedBox(height: 24),

                // 9. Estado (Oficial/Comunitario)
                DropdownButtonFormField<String>(
                  initialValue: _estadoContenido,
                  items: [
                    DropdownMenuItem(
                        value: 'OFICIAL',
                        child: Text(l10n.contentStatusOfficial)),
                    DropdownMenuItem(
                        value: 'COMUNITARIO',
                        child: Text(l10n.contentStatusCommunity)),
                  ],
                  onChanged: (v) => setState(() => _estadoContenido = v!),
                  decoration: getCommonDecoration(l10n.labelContentStatus),
                ),
                const SizedBox(height: 24),

                // 10. Comentarios de Revisión (Opcional)
                TextFormField(
                  controller: _comentariosController,
                  decoration: getCommonDecoration(l10n.modEditReviewComment),
                  maxLines: 3,
                ),

                const SizedBox(height: 32),

                // Botón Save and Approve
                FilledButton(
                  onPressed:
                      (_isLoading || _isUploading) ? null : _handleAprobar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l10n.actionSaveAndApprove,
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

  Widget _buildProposerInfo() {
    final l10n = AppLocalizations.of(context);
    final p = widget.propuesta;
    // 1. Verificar si soy admin
    final bool isAdmin =
        context.read<AuthService>().currentUser?.esAdministrador ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: l10n.labelProposedBy,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '${p.proponenteUsername} '),
                // 2. Mostrar email solo si es admin y el email existe
                if (isAdmin && p.proponenteEmail != null)
                  TextSpan(
                    text: '(${p.proponenteEmail})',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploader(AppLocalizations l10n) {
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
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(l10n.modEditImageTitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: content,
              ),
            ),
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

  Widget _buildGenreSelector() {
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
      onChanged: (genres) =>
          setState(() => _generosController.text = genres.join(', ')),
    );
  }

  String? _validateProgressData() {
    if (_tipoSeleccionado == null) {
      return null;
    }
    final l10n = AppLocalizations.of(context);
    final type = _tipoSeleccionado;
    if (type == 'Anime' && _totalUnidadesController.text.trim().isEmpty) {
      return l10n.validationRequired;
    }
    if ((type == 'Manga' || type == 'Manhwa') &&
        _totalCapitulosLibroController.text.trim().isEmpty) {
      return l10n.validationRequired;
    }
    if (type == 'Book' && _totalPaginasLibroController.text.trim().isEmpty) {
      return l10n.validationRequired;
    }
    if (type == 'Series' &&
        _episodiosPorTemporadaController.text.trim().isEmpty) {
      return l10n.validationRequired;
    }
    if (type == 'Movie' && _durationController.text.trim().isEmpty) {
      return l10n.validationRequired;
    }
    return null;
  }
}
