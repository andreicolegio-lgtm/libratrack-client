import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/maybe_marquee.dart';
import '../../../core/services/catalog_service.dart';
import '../../../model/catalogo_entrada.dart';
import '../../../model/estado_personal.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../elemento/elemento_detail_screen.dart';
import 'dart:math';
import '../../../core/utils/api_exceptions.dart';
import '../../../core/utils/error_translator.dart';

class CatalogEntryCard extends StatefulWidget {
  final CatalogoEntrada entrada;
  final VoidCallback onUpdate;

  const CatalogEntryCard({
    required this.entrada,
    required this.onUpdate,
    super.key,
  });

  @override
  State<CatalogEntryCard> createState() => _CatalogEntryCardState();
}

class _CatalogEntryCardState extends State<CatalogEntryCard> {
  late final CatalogService _catalogService;

  final TextEditingController _temporadaController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _capituloController = TextEditingController();
  final TextEditingController _paginaController = TextEditingController();

  late CatalogoEntrada _entrada;
  bool _isLoading = false;

  List<int> _episodiosPorTemporada = <int>[];

  @override
  void initState() {
    super.initState();
    _catalogService = context.read<CatalogService>();
    _actualizarEstadoEntrada(widget.entrada);
  }

  @override
  void didUpdateWidget(covariant CatalogEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entrada != oldWidget.entrada) {
      _actualizarEstadoEntrada(widget.entrada);
    }
  }

  void _actualizarEstadoEntrada(CatalogoEntrada nuevaEntrada) {
    _entrada = nuevaEntrada;

    _episodiosPorTemporada =
        _parseEpisodiosPorTemporada(_entrada.elementoEpisodiosPorTemporada);

    _temporadaController.text = (_entrada.temporadaActual ?? 1).toString();
    _unidadController.text = (_entrada.unidadActual ?? 0).toString();
    _capituloController.text = (_entrada.capituloActual ?? 0).toString();
    _paginaController.text = (_entrada.paginaActual ?? 0).toString();
  }

  @override
  void dispose() {
    _temporadaController.dispose();
    _unidadController.dispose();
    _capituloController.dispose();
    _paginaController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateEstado(EstadoPersonal nuevoEstado) async {
    if (nuevoEstado.apiValue == _entrada.estadoPersonal) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    try {
      await _catalogService.updateEstado(
        _entrada.elementoId,
        nuevoEstado.apiValue,
      );

      if (mounted) {
        widget.onUpdate();
        SnackBarHelper.showTopSnackBar(
            context, l10n.snackbarCatalogStatusUpdated,
            isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
            context, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
            context, l10n.errorUpdating(e.toString()),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSaveProgress() async {
    if (_isLoading) {
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final Map<String, dynamic> body = <String, dynamic>{};
    final String tipo = _entrada.elementoTipoNombre.toLowerCase();

    bool autoTerminado = false;
    final int totalUnidades = _entrada.elementoTotalUnidades ?? 0;
    final int totalPaginas = _entrada.elementoTotalPaginasLibro ?? 0;
    final int totalTemps = _episodiosPorTemporada.length;

    if (tipo == 'serie') {
      final int temp =
          (int.tryParse(_temporadaController.text) ?? 1).clamp(1, totalTemps);
      final int unid = (int.tryParse(_unidadController.text) ?? 0)
          .clamp(0, totalTemps > 0 ? _episodiosPorTemporada[temp - 1] : 0);
      body['temporadaActual'] = temp;
      body['unidadActual'] = unid;

      if (totalTemps > 0 &&
          temp == totalTemps &&
          unid == _episodiosPorTemporada[totalTemps - 1]) {
        autoTerminado = true;
      }
    } else if (tipo == 'libro') {
      final int cap = int.tryParse(_capituloController.text) ?? 0;
      final int pag =
          (int.tryParse(_paginaController.text) ?? 0).clamp(0, totalPaginas);
      body['capituloActual'] = cap;
      body['paginaActual'] = pag;

      if (totalPaginas > 0 && pag == totalPaginas) {
        autoTerminado = true;
      }
    } else if (tipo == 'anime' || tipo == 'manga') {
      final int unid =
          (int.tryParse(_unidadController.text) ?? 0).clamp(0, totalUnidades);
      body['unidadActual'] = unid;

      if (totalUnidades > 0 && unid == totalUnidades) {
        autoTerminado = true;
      }
    }

    if (autoTerminado &&
        _entrada.estadoPersonal != EstadoPersonal.terminado.apiValue) {
      body['estadoPersonal'] = EstadoPersonal.terminado.apiValue;
    } else if (_entrada.estadoPersonal == EstadoPersonal.pendiente.apiValue) {
      body['estadoPersonal'] = EstadoPersonal.enProgreso.apiValue;
    }

    try {
      await _catalogService.updateProgreso(
        _entrada.elementoId,
        body,
      );

      if (mounted) {
        widget.onUpdate();
        SnackBarHelper.showTopSnackBar(
            context, l10n.snackbarCatalogProgressSaved,
            isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
            context, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
            context, l10n.errorUpdating(e.toString()),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEstadoChange(EstadoPersonal nuevoEstado) async {
    if (nuevoEstado == EstadoPersonal.terminado) {
      final String tipo = _entrada.elementoTipoNombre.toLowerCase();
      if (tipo == 'serie' && _episodiosPorTemporada.isNotEmpty) {
        _temporadaController.text = _episodiosPorTemporada.length.toString();
        _unidadController.text = _episodiosPorTemporada.last.toString();
      } else if (tipo == 'libro') {
        _paginaController.text =
            (_entrada.elementoTotalPaginasLibro ?? 0).toString();
      } else if (tipo == 'anime' || tipo == 'manga') {
        _unidadController.text =
            (_entrada.elementoTotalUnidades ?? 0).toString();
      }
    }
    await _handleUpdateEstado(nuevoEstado);
  }

  double get _progresoValue {
    if (_entrada.estadoPersonal == EstadoPersonal.terminado.apiValue) {
      return 1.0;
    }

    final String tipo = _entrada.elementoTipoNombre.toLowerCase();

    try {
      if (tipo == 'serie') {
        if (_episodiosPorTemporada.isEmpty) {
          return 0.0;
        }
        final int totalEps =
            _episodiosPorTemporada.fold<int>(0, (int prev, int e) => prev + e);
        if (totalEps == 0) {
          return 0.0;
        }

        int currentEps = 0;
        int tempActual = (_entrada.temporadaActual ?? 1)
            .clamp(1, max(1, _episodiosPorTemporada.length));

        for (int i = 0; i < tempActual - 1; i++) {
          currentEps += _episodiosPorTemporada[i];
        }
        currentEps += (_entrada.unidadActual ?? 0);

        return (currentEps / totalEps).clamp(0.0, 1.0);
      } else if (tipo == 'libro') {
        int pagTotal = _entrada.elementoTotalPaginasLibro ?? 0;
        if (pagTotal <= 0) {
          return 0.0;
        }
        return ((_entrada.paginaActual ?? 0) / pagTotal).clamp(0.0, 1.0);
      } else {
        int uniTotal = _entrada.elementoTotalUnidades ?? 0;
        if (uniTotal <= 0) {
          return 0.0;
        }
        return ((_entrada.unidadActual ?? 0) / uniTotal).clamp(0.0, 1.0);
      }
    } catch (e) {
      return 0.0;
    }
  }

  List<int> _parseEpisodiosPorTemporada(String? data) {
    if (data == null || data.isEmpty) {
      return <int>[];
    }
    try {
      return data
          .split(',')
          .map((String e) => int.tryParse(e.trim()) ?? 0)
          .toList();
    } catch (e) {
      return <int>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditable = !_isLoading;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color fadedIconColor = onSurfaceColor.withAlpha(0x80);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final String tipo = _entrada.elementoTipoNombre.toLowerCase();
    final bool mostrarProgresoUI = tipo == 'serie' ||
        tipo == 'libro' ||
        tipo == 'anime' ||
        tipo == 'manga';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: isEditable
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        ElementoDetailScreen(elementoId: _entrada.elementoId),
                  ),
                ).then((_) => widget.onUpdate());
              }
            : null,
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildImageContainer(fadedIconColor),
                _buildInfo(context, Theme.of(context)),
              ],
            ),
            if (mostrarProgresoUI) _buildProgressSection(context, l10n, tipo),
            _buildActionButtons(context, l10n, isEditable),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer(Color fadedIconColor) {
    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest),
      child: (_entrada.elementoUrlImagen != null &&
              _entrada.elementoUrlImagen!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: _entrada.elementoUrlImagen!,
              fit: BoxFit.cover,
              placeholder: (BuildContext context, String url) =>
                  Icon(Icons.downloading, color: fadedIconColor),
              errorWidget: (BuildContext context, String url, Object error) =>
                  Icon(Icons.image_not_supported,
                      color: fadedIconColor, size: 40),
            )
          : Icon(Icons.image_not_supported, color: fadedIconColor, size: 40),
    );
  }

  Widget _buildInfo(BuildContext context, ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            MaybeMarquee(
              text: _entrada.elementoTitulo,
              style: theme.textTheme.titleMedium ?? const TextStyle(),
            ),
            const SizedBox(height: 8),
            Text(
              _entrada.elementoTipoNombre,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            _buildProgressBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    double progress = _progresoValue;
    String progressText = '';

    final String tipo = _entrada.elementoTipoNombre.toLowerCase();
    final int? totalPaginas = _entrada.elementoTotalPaginasLibro;
    final int? totalUnidades = _entrada.elementoTotalUnidades;
    final int pagActual = _entrada.paginaActual ?? 0;
    final int unidadActual = _entrada.unidadActual ?? 0;

    if (tipo == 'libro' && totalPaginas != null && totalPaginas > 0) {
      progressText = '$pagActual / $totalPaginas';
    } else if ((tipo == 'anime' || tipo == 'manga') &&
        totalUnidades != null &&
        totalUnidades > 0) {
      progressText = '$unidadActual / $totalUnidades';
    } else if (tipo == 'serie') {
      progressText =
          'T${_entrada.temporadaActual ?? 1} / E${_entrada.unidadActual ?? 0}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (progressText.isNotEmpty)
          Text(progressText, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withAlpha(77),
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildProgressSection(
      BuildContext context, AppLocalizations l10n, String tipo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: <Widget>[
          if (tipo == 'serie')
            Expanded(
              child: _buildTextField(
                  _temporadaController, l10n.catalogCardSeriesSeason(1),
                  enabled: !_isLoading),
            ),
          if (tipo == 'serie') const SizedBox(width: 16),
          if (tipo == 'serie' || tipo == 'anime' || tipo == 'manga')
            Expanded(
              child: _buildTextField(
                  _unidadController,
                  tipo == 'serie'
                      ? l10n.catalogCardSeriesEpisode(1)
                      : (tipo == 'anime'
                          ? l10n.elementDetailAnimeEpisodes
                          : l10n.elementDetailMangaChapters),
                  enabled: !_isLoading),
            ),
          if (tipo == 'libro')
            Expanded(
              child: _buildTextField(
                  _capituloController, l10n.catalogCardBookChapter,
                  enabled: !_isLoading),
            ),
          if (tipo == 'libro') const SizedBox(width: 16),
          if (tipo == 'libro')
            Expanded(
              child: _buildTextField(
                  _paginaController, l10n.catalogCardBookPage,
                  enabled: !_isLoading),
            ),
          const SizedBox(width: 16),
          _isLoading
              ? const SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator())
              : IconButton(
                  icon: Icon(Icons.save,
                      color: Theme.of(context).colorScheme.primary),
                  onPressed: _handleSaveProgress,
                ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AppLocalizations l10n, bool isEditable) {
    return Container(
      color:
          Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildStatusMenu(context, l10n, isEditable),
          IconButton(
            icon: Icon(
              widget.entrada.esFavorito ? Icons.star : Icons.star_border,
              color: widget.entrada.esFavorito ? Colors.yellow : Colors.grey,
            ),
            onPressed: () async {
              try {
                await _catalogService.toggleFavorite(widget.entrada.id);
                widget.onUpdate();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Error toggling favorite: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMenu(
      BuildContext context, AppLocalizations l10n, bool isEditable) {
    return PopupMenuButton<EstadoPersonal>(
      enabled: isEditable,
      onSelected: (EstadoPersonal nuevoEstado) async {
        await _handleEstadoChange(nuevoEstado);
      },
      itemBuilder: (BuildContext context) {
        return EstadoPersonal.values
            .map((EstadoPersonal e) => PopupMenuItem<EstadoPersonal>(
                  value: e,
                  child: Text(e.displayName(context)),
                ))
            .toList();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            Text(
              EstadoPersonal.fromString(_entrada.estadoPersonal)
                  .displayName(context),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
