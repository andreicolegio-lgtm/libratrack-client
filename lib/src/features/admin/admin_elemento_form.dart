import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class AdminElementoFormScreen extends StatefulWidget {
  final Elemento? elemento;

  const AdminElementoFormScreen({super.key, this.elemento});

  bool get isEditMode {
    return elemento != null;
  }

  @override
  State<AdminElementoFormScreen> createState() =>
      _AdminElementoFormScreenState();
}

class _AdminElementoFormScreenState extends State<AdminElementoFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final AdminService _adminService;
  late final ApiClient _apiClient;
  late final ElementoService _elementoService;

  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isUploading = false;

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

  String? _tipoSeleccionado;
  List<Tipo> _tipos = [];

  late Future<List<ElementoRelacion>> _elementosFuture;
  List<ElementoRelacion> _allElementos = <ElementoRelacion>[];
  final Set<int> _selectedSecuelaIds = <int>{};

  XFile? _pickedImage;
  String? _uploadedImageUrl;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();

    _adminService = context.read<AdminService>();
    _apiClient = context.read<ApiClient>();
    _elementoService = context.read<ElementoService>();

    if (widget.isEditMode) {
      final Elemento e = widget.elemento!;
      _tituloController.text = e.titulo;
      _descripcionController.text = e.descripcion;
      _generosController.text = e.generos.join(', ');
      _episodiosPorTemporadaController.text = e.episodiosPorTemporada ?? '';
      _totalUnidadesController.text = e.totalUnidades?.toString() ?? '';
      _totalCapitulosLibroController.text =
          e.totalCapitulosLibro?.toString() ?? '';
      _totalPaginasLibroController.text = e.totalPaginasLibro?.toString() ?? '';
      _tipoSeleccionado = e.tipo.toLowerCase();
      _uploadedImageUrl = e.urlImagen;

      _selectedSecuelaIds.addAll(e.secuelas.map((ElementoRelacion s) => s.id));
    }

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      _elementosFuture = _elementoService.getSimpleElementoList();
      _elementosFuture.then((List<ElementoRelacion> lista) {
        if (mounted) {
          setState(() {
            _allElementos = lista;
          });
        }
      });
      _isDataLoaded = true;
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
    _scrollController.dispose();
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

  Future<void> _handleGuardar() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null) {
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarImageUploadRequired,
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final NavigatorState navContext = Navigator.of(context);

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'tipoNombre': _tipoSeleccionado,
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
        'secuelaIds': _selectedSecuelaIds.toList(),
      };
      body.removeWhere((String key, value) => value == null);

      if (widget.isEditMode) {
        await _adminService.updateElemento(widget.elemento!.id, body);
      } else {
        await _adminService.crearElementoOficial(body);
      }

      if (!mounted) {
        return;
      }

      final String successMessage = widget.isEditMode
          ? l10n.snackbarAdminElementUpdated
          : l10n.snackbarAdminElementCreated;

      SnackBarHelper.showTopSnackBar(context, successMessage, isError: false);
      navContext.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          context,
          l10n.errorSaving(e.toString()),
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
    final String tituloPantalla =
        widget.isEditMode ? l10n.adminFormEditTitle : l10n.adminFormCreateTitle;
    final String botonGuardar = widget.isEditMode
        ? l10n.adminFormEditButton
        : l10n.adminFormCreateButton;

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
            children: <Widget>[
              _buildImageUploader(l10n),
              const SizedBox(height: 24),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _tituloController,
                labelText: l10n.adminFormTitleLabel,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _descripcionController,
                labelText: l10n.adminFormDescLabel,
                maxLines: 4,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationDescRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTipoField(context, l10n),
              const SizedBox(height: 16),
              _buildGenerosField(l10n),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              Text(l10n.adminFormProgressTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (_tipoSeleccionado == 'serie')
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _episodiosPorTemporadaController,
                  labelText: l10n.proposalFormSeriesEpisodesLabel,
                  hintText: l10n.proposalFormSeriesEpisodesHint,
                ),
              if (_tipoSeleccionado == 'libro') ...<Widget>[
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalCapitulosLibroController,
                  labelText: l10n.proposalFormBookChaptersLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalPaginasLibroController,
                  labelText: l10n.proposalFormBookPagesLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ],
              if (_tipoSeleccionado == 'anime' || _tipoSeleccionado == 'manga')
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalUnidadesController,
                  labelText: _tipoSeleccionado == 'anime'
                      ? l10n.proposalFormAnimeEpisodesLabel
                      : l10n.proposalFormMangaChaptersLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              if (_tipoSeleccionado == 'película' ||
                  _tipoSeleccionado == 'videojuego')
                Text(
                  l10n.proposalFormNoProgress(_tipoSeleccionado ?? ''),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              _buildSecuelasSelector(l10n),
              const SizedBox(height: 32.0),
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
      content = CachedNetworkImage(
        imageUrl: _uploadedImageUrl!,
        fit: BoxFit.cover,
        placeholder: (BuildContext c, String u) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (BuildContext c, String u, Object e) =>
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[600]),
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.image_search, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(l10n.adminFormImageTitle,
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

  Widget _buildTipoField(BuildContext context, AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _tipoSeleccionado,
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
        labelText: l10n.adminFormTypeLabel,
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

  Widget _buildSecuelasSelector(AppLocalizations l10n) {
    return FutureBuilder<List<ElementoRelacion>>(
      future: _elementosFuture,
      builder: (BuildContext context,
          AsyncSnapshot<List<ElementoRelacion>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _allElementos.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.adminFormSequelsTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }
        if (snapshot.hasError) {
          return Text(l10n.errorLoadingElements(snapshot.error.toString()));
        }

        final List<ElementoRelacion> elementosDisponibles =
            _allElementos.where((ElementoRelacion el) {
          if (widget.elemento == null) {
            return true;
          }
          return el.id != widget.elemento!.id;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.adminFormSequelsTitle,
                style: Theme.of(context).textTheme.titleLarge),
            Text(l10n.adminFormSequelsSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[400])),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: ListView(
                  controller: _scrollController,
                  children: elementosDisponibles.map((ElementoRelacion el) {
                    final bool isSelected = _selectedSecuelaIds.contains(el.id);
                    return CheckboxListTile(
                      title: Text(el.titulo),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        if (selected == null) {
                          return;
                        }
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
}
