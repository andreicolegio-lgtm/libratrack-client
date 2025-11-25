import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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

  bool _isLoading = false;
  bool _isUploading = false;

  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _generosController;
  late TextEditingController _episodiosPorTemporadaController;
  late TextEditingController _totalUnidadesController;
  late TextEditingController _totalCapitulosLibroController;
  late TextEditingController _totalPaginasLibroController;
  late TextEditingController _durationController;

  String? _tipoSeleccionado;
  List<Tipo> _tipos = [];

  XFile? _pickedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();

    _moderacionService = context.read<ModeracionService>();
    _apiClient = context.read<ApiClient>();

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
    _tipoSeleccionado = p.tipoSugerido.toLowerCase();
    _loadTipos();
  }

  Future<void> _loadTipos() async {
    final tipoService = context.read<TipoService>();
    try {
      final tipos = await tipoService.fetchTipos('Error loading types');
      setState(() {
        _tipos = tipos;
      });
    } catch (e) {
      // Handle error
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

  Future<void> _handlePickImage() async {
    final ImagePicker picker = ImagePicker();
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _uploadedImageUrl = null;
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

    setState(() {
      _isUploading = true;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      final dynamic data = await _apiClient.upload('uploads', _pickedImage!);
      final String url = data['url'];

      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(context, l10n.snackbarImageUploadSuccess,
            isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(
            context, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(
            context, l10n.errorImageUpload(e.toString()),
            isError: true);
      }
    }
  }

  Future<void> _handleAprobar() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null) {
      SnackBarHelper.showTopSnackBar(
          context, l10n.snackbarImageUploadRequiredApproval,
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final NavigatorState navContext = Navigator.of(context);

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'tituloSugerido': _tituloController.text,
        'descripcionSugerida': _descripcionController.text,
        'tipoSugerido': _tipoSeleccionado,
        'generosSugeridos': _generosController.text,
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
        'duracion':
            _durationController.text.isEmpty ? null : _durationController.text,
      };
      body.removeWhere((String key, value) => value == null);

      await _moderacionService.aprobarPropuesta(widget.propuesta.id, body);

      if (!mounted) {
        return;
      }

      navContext.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.errorApproving(e.toString()),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.errorUnexpected(e.toString()),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
              Text(
                  l10n.modPanelProposalFrom(
                      widget.propuesta.proponenteUsername),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              _buildImageUploader(l10n),
              const SizedBox(height: 24),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _tituloController,
                labelText: l10n.proposalFormTitleLabel,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _descripcionController,
                labelText: l10n.proposalFormDescLabel,
                maxLines: 4,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationDescRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTipoDropdown(l10n),
              const SizedBox(height: 16),
              _buildGenerosField(l10n),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
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
                l10n: AppLocalizations.of(context)!,
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
                    : Text(
                        l10n.modEditSubmitButton,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
      content = Image.network(_uploadedImageUrl!, fit: BoxFit.cover);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.image_search, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(l10n.modEditImageTitle,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
          children: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: Text(l10n.adminFormImageGallery),
              onPressed: _isLoading || _isUploading ? null : _handlePickImage,
            ),
            ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading
                  ? l10n.adminFormImageUploading
                  : l10n.adminFormImageUpload),
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

  Widget _buildInputField(
    BuildContext context, {
    required AppLocalizations l10n,
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
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
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

  Widget _buildTipoDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _tipoSeleccionado ?? '',
      items: _tipos.map((tipo) {
        return DropdownMenuItem(
          value: tipo.nombre,
          child: Text(tipo.nombre),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _tipoSeleccionado = value;
        });
      },
      decoration: InputDecoration(
        labelText: l10n.proposalFormTypeLabel,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
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

  Widget _buildGenerosField(AppLocalizations l10n) {
    return GenreSelectorWidget(
      selectedTypes: _tipoSeleccionado != null
          ? [_tipos.firstWhere((tipo) => tipo.nombre == _tipoSeleccionado)]
          : [],
      initialGenres:
          _generosController.text.split(',').map((e) => e.trim()).toList(),
      onChanged: (List<String> updatedGenres) {
        setState(() {
          _generosController.text = updatedGenres.join(', ');
        });
      },
    );
  }
}
