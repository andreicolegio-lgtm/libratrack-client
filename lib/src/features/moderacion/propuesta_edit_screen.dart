import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
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
/// Permite modificar todos los campos sugeridos por el usuario antes de crear el elemento final.
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

  String? _tipoSeleccionado;
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

    _tipoSeleccionado = p.tipoSugerido; // Intentamos mantener el sugerido
    _uploadedImageUrl = p.urlImagen;
  }

  Future<void> _loadInitialData() async {
    try {
      final tipos = await _tipoService.fetchTipos('Error loading types');

      if (mounted) {
        setState(() {
          _tipos = tipos;

          // Validar si el tipo sugerido existe en la lista oficial (case-insensitive)
          final existingType = _tipos.firstWhere(
            (t) =>
                t.nombre.toLowerCase() ==
                (_tipoSeleccionado?.toLowerCase() ?? ''),
            orElse: () => const Tipo(id: 0, nombre: '', validGenres: []),
          );

          if (existingType.id != 0) {
            _tipoSeleccionado = existingType.nombre; // Normalizar nombre
          } else {
            // Si no existe, dejamos el valor raw pero el dropdown podría mostrarlo vacío o error
            // Opcionalmente podríamos añadirlo a la lista localmente o forzar selección
          }

          _isDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error cargando tipos en edición: $e');
      if (mounted) {
        setState(() => _isDataLoaded =
            true); // Permitir continuar aunque falle carga de tipos
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
          // No borramos _uploadedImageUrl para mantener preview si falla subida
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
          _pickedImage = null; // Limpiar selección local
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validación opcional: Exigir imagen para aprobar
    /*
    if (_uploadedImageUrl == null) {
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarImageUploadRequiredApproval, isError: true);
      return;
    }
    */

    // Subir imagen pendiente si existe
    if (_pickedImage != null) {
      await _handleUploadImage();
      if (_uploadedImageUrl == null) {
        return; // Falló la subida
      }
    }

    setState(() => _isLoading = true);

    if (!mounted) {
      return;
    }
    final NavigatorState navContext = Navigator.of(context);

    try {
      // Construir payload limpio
      final Map<String, dynamic> body = <String, dynamic>{
        'tituloSugerido': _tituloController.text.trim(),
        'descripcionSugerida': _descripcionController.text.trim(),
        'tipoSugerido': _tipoSeleccionado,
        'generosSugeridos': _generosController.text.trim(),
        'urlImagen': _uploadedImageUrl,

        // Progreso
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
      };

      // Eliminar nulos
      body.removeWhere((String key, value) => value == null);

      await _moderacionService.aprobarPropuesta(widget.propuesta.id, body);

      if (!mounted) {
        return;
      }

      // Retornar 'true' indica éxito para actualizar la lista anterior
      navContext.pop(true);
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
        title: Text(l10n.modEditTitle,
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
              // Info del Proponente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.modPanelProposalFrom(
                            widget.propuesta.proponenteUsername),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildImageUploader(l10n),
              const SizedBox(height: 24),

              _buildInputField(
                l10n: l10n,
                controller: _tituloController,
                labelText: l10n.proposalFormTitleLabel,
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.validationTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                l10n: l10n,
                controller: _descripcionController,
                labelText: l10n.proposalFormDescLabel,
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
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider()),

              Text(l10n.modEditProgressTitle,
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

              const SizedBox(height: 32.0),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
                onPressed: (_isLoading || _isUploading) ? null : _handleAprobar,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(l10n.modEditSubmitButton,
                    style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader(AppLocalizations l10n) {
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
            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(l10n.modEditImageTitle,
              style: TextStyle(color: Colors.grey[600])),
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Theme.of(context).dividerColor),
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
              icon: const Icon(Icons.cloud_upload),
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
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTipoDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _tipoSeleccionado,
      hint: Text(l10n.proposalFormTypeLabel),
      items: _tipos.map((tipo) {
        return DropdownMenuItem(
          value: tipo.nombre,
          child: Text(tipo.nombre),
        );
      }).toList(),
      onChanged: (value) => setState(() => _tipoSeleccionado = value),
      decoration: InputDecoration(
        labelText: l10n.proposalFormTypeLabel,
        filled: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildGenerosField(AppLocalizations l10n) {
    final selectedTypeObj = _tipos.firstWhere(
        (t) => t.nombre == _tipoSeleccionado,
        orElse: () => const Tipo(id: 0, nombre: '', validGenres: []));

    return GenreSelectorWidget(
      selectedTypes: _tipoSeleccionado != null ? [selectedTypeObj] : [],
      initialGenres: _generosController.text
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((e) => e.trim())
          .toList(),
      onChanged: (updatedGenres) {
        setState(() {
          _generosController.text = updatedGenres.join(', ');
        });
      },
    );
  }
}
