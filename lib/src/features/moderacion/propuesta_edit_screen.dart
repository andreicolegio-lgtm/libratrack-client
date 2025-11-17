import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/api_client.dart';
import '../../core/services/moderacion_service.dart';
import '../../model/propuesta.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/utils/api_exceptions.dart';

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
  late TextEditingController _tipoController;
  late TextEditingController _generosController;
  late TextEditingController _episodiosPorTemporadaController;
  late TextEditingController _totalUnidadesController;
  late TextEditingController _totalCapitulosLibroController;
  late TextEditingController _totalPaginasLibroController;

  String _tipoSeleccionado = '';

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
      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(
          ScaffoldMessenger.of(context), 'Error al seleccionar imagen: $e',
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
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);

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
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: $e',
            isError: true);
      }
    }
  }

  Future<void> _handleAprobar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null) {
      SnackBarHelper.showTopSnackBar(ScaffoldMessenger.of(context),
          'Por favor, sube una imagen de portada antes de aprobar.',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);
    final NavigatorState navContext = Navigator.of(context);

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'tituloSugerido': _tituloController.text,
        'descripcionSugerida': _descripcionController.text,
        'tipoSugerido': _tipoController.text,
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
          msgContext,
          'Error al aprobar: $e',
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
            children: <Widget>[
              Text('Propuesto por: ${widget.propuesta.proponenteUsername}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              _buildImageUploader(),
              const SizedBox(height: 24),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _tituloController,
                labelText: 'Título',
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _descripcionController,
                labelText: 'Descripción',
                maxLines: 4,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationDescRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _tipoController,
                labelText: 'Tipo (Ej. Serie, Libro)',
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationTypeRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _generosController,
                labelText: 'Géneros (separados por coma)',
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationGenresRequired
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              Text('Datos de Progreso (¡Obligatorio!)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (_tipoSeleccionado == 'serie')
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _episodiosPorTemporadaController,
                  labelText: 'Episodios por Temporada',
                  hintText: 'Ej. 10,8,12 (para T1, T2, T3)',
                  validator: (String? value) => (value == null || value.isEmpty)
                      ? 'Este campo es obligatorio para Series'
                      : null,
                ),
              if (_tipoSeleccionado == 'libro') ...<Widget>[
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalCapitulosLibroController,
                  labelText: 'Total Capítulos (Libro)',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (String? value) => (value == null || value.isEmpty)
                      ? 'Este campo es obligatorio para Libros'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalPaginasLibroController,
                  labelText: 'Total Páginas (Libro)',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (String? value) => (value == null || value.isEmpty)
                      ? 'Este campo es obligatorio para Libros'
                      : null,
                ),
              ],
              if (_tipoSeleccionado == 'anime' || _tipoSeleccionado == 'manga')
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalUnidadesController,
                  labelText: _tipoSeleccionado == 'anime'
                      ? 'Total Episodios (Anime)'
                      : 'Total Capítulos (Manga)',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (String? value) => (value == null || value.isEmpty)
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

  Widget _buildImageUploader() {
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
          Text('Sin portada', style: Theme.of(context).textTheme.bodyMedium),
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
}
