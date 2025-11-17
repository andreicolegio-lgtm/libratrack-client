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

    _capituloController.text = (_entrada.capituloActual ?? 0).toString();
    _paginaController.text = (_entrada.paginaActual ?? 0).toString();
  }

  @override
  void dispose() {
    _capituloController.dispose();
    _paginaController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateEstado(String nuevoEstado) async {
    if (nuevoEstado == _entrada.estadoPersonal) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    try {
      await _catalogService.updateEstado(
        _entrada.elementoId,
        nuevoEstado,
      );

      if (mounted) {
        widget.onUpdate();
        SnackBarHelper.showTopSnackBar(
            msgContext, l10n.snackbarCatalogStatusUpdated,
            isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, l10n.errorUpdating(e.toString()),
            isError: true);
      }
    }
  }

  Future<void> _handleUpdateProgreso({
    int? temporada,
    int? unidad,
    int? capitulo,
    int? pagina,
    bool esGuardadoManual = false,
  }) async {
    if (_isLoading) {
      return;
    }

    if (esGuardadoManual) {
      FocusScope.of(context).unfocus();
      if (capitulo == _entrada.capituloActual &&
          pagina == _entrada.paginaActual) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    String? estadoFinal;
    bool autoTerminado = false;
    final String tipo = _entrada.elementoTipoNombre.toLowerCase();

    final int totalEpsAnime = _entrada.elementoTotalUnidades ?? 0;
    final int totalPagLibro = _entrada.elementoTotalPaginasLibro ?? 0;
    final int totalTemps = _episodiosPorTemporada.length;

    if (tipo == 'serie' &&
        temporada != null &&
        unidad != null &&
        totalTemps > 0) {
      if (temporada == totalTemps &&
          unidad == _episodiosPorTemporada[totalTemps - 1]) {
        autoTerminado = true;
      }
    } else if (tipo == 'libro' && pagina != null && totalPagLibro > 0) {
      if (pagina == totalPagLibro) {
        autoTerminado = true;
      }
    } else if ((tipo == 'anime' || tipo == 'manga') &&
        unidad != null &&
        totalEpsAnime > 0) {
      if (unidad == totalEpsAnime) {
        autoTerminado = true;
      }
    }

    if (autoTerminado &&
        _entrada.estadoPersonal != EstadoPersonal.terminado.apiValue) {
      estadoFinal = EstadoPersonal.terminado.apiValue;
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'estadoPersonal': estadoFinal,
        'temporadaActual': temporada,
        'unidadActual': unidad,
        'capituloActual': capitulo,
        'paginaActual': pagina,
      };
      body.removeWhere((String key, value) => value == null);

      await _catalogService.updateProgreso(
        _entrada.elementoId,
        body,
      );

      if (mounted) {
        if (estadoFinal != null) {
          widget.onUpdate();
        } else {
          widget.onUpdate();
        }
        if (esGuardadoManual) {
          SnackBarHelper.showTopSnackBar(
              msgContext, l10n.snackbarCatalogProgressSaved,
              isError: false);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, ErrorTranslator.translate(context, e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, l10n.errorUpdating(e.toString()),
            isError: true);
      }
    }
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
            .clamp(1, _episodiosPorTemporada.length);

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildImageContainer(fadedIconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MaybeMarquee(
                      text: _entrada.elementoTitulo,
                      style: Theme.of(context).textTheme.titleMedium ??
                          const TextStyle(),
                    ),
                    if (mostrarProgresoUI) ...<Widget>[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _progresoValue,
                        backgroundColor: Colors.grey[700],
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      _buildProgresoUI(context, isEditable, l10n),
                    ] else ...<Widget>[
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: _buildEstadoDropdown(context, isEditable, l10n),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer(Color fadedIconColor) {
    final String? imageUrl = _entrada.elementoUrlImagen;
    final bool isValidUrl = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: isValidUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Center(
                    child: Icon(Icons.downloading, color: fadedIconColor)),
                errorWidget: (BuildContext context, String url, Object error) =>
                    Icon(Icons.broken_image, color: fadedIconColor),
              )
            : Icon(Icons.image, size: 40, color: fadedIconColor),
      ),
    );
  }

  Widget _buildProgresoUI(
      BuildContext context, bool isEditable, AppLocalizations l10n) {
    final String tipo = _entrada.elementoTipoNombre.toLowerCase();

    if (tipo == 'serie') {
      return _buildProgresoSerie(context, isEditable, l10n);
    }
    if (tipo == 'libro') {
      return _buildProgresoLibro(context, isEditable, l10n);
    }
    if (tipo == 'anime' || tipo == 'manga') {
      return _buildProgresoUnidad(context, isEditable, l10n, tipo);
    }

    return const SizedBox(height: 36);
  }

  Widget _buildProgresoSerie(
      BuildContext context, bool isEditable, AppLocalizations l10n) {
    final int tempActual = (_entrada.temporadaActual ?? 1)
        .clamp(1, max(1, _episodiosPorTemporada.length));
    final int epTotalTempActual =
        (tempActual - 1 < _episodiosPorTemporada.length)
            ? _episodiosPorTemporada[tempActual - 1]
            : 0;
    final int epActual =
        (_entrada.unidadActual ?? 0).clamp(0, max(0, epTotalTempActual));

    final List<int> temporadas =
        List.generate(_episodiosPorTemporada.length, (int i) => i + 1);
    final List<int> episodios =
        List.generate(epTotalTempActual + 1, (int i) => i);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: tempActual,
            items: temporadas
                .map((int t) => DropdownMenuItem(
                    value: t, child: Text(l10n.catalogCardSeriesSeason(t))))
                .toList(),
            onChanged: isEditable
                ? (int? val) {
                    if (val == null || val == _entrada.temporadaActual) {
                      return;
                    }
                    _handleUpdateProgreso(temporada: val, unidad: 0);
                  }
                : null,
            decoration: const InputDecoration.collapsed(hintText: ''),
            style: Theme.of(context).textTheme.bodyMedium,
            dropdownColor: Theme.of(context).colorScheme.surface,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: epActual,
            items: episodios
                .map((int e) => DropdownMenuItem(
                    value: e, child: Text(l10n.catalogCardSeriesEpisode(e))))
                .toList(),
            onChanged: isEditable
                ? (int? val) {
                    if (val == null || val == _entrada.unidadActual) {
                      return;
                    }
                    _handleUpdateProgreso(temporada: tempActual, unidad: val);
                  }
                : null,
            decoration: const InputDecoration.collapsed(hintText: ''),
            style: Theme.of(context).textTheme.bodyMedium,
            dropdownColor: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildProgresoLibro(
      BuildContext context, bool isEditable, AppLocalizations l10n) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _capituloController,
            enabled: isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.catalogCardBookChapter,
              hintText: l10n.catalogCardBookChapterTotal(
                  _entrada.elementoTotalCapitulosLibro ?? 0),
              isDense: true,
            ),
            onSubmitted: (_) => _handleUpdateProgresoLibro(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _paginaController,
            enabled: isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.catalogCardBookPage,
              hintText: l10n.catalogCardBookPageTotal(
                  _entrada.elementoTotalPaginasLibro ?? 0),
              isDense: true,
            ),
            onSubmitted: (_) => _handleUpdateProgresoLibro(),
          ),
        ),
        if (isEditable)
          IconButton(
            icon:
                Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
            onPressed: _handleUpdateProgresoLibro,
            tooltip: l10n.catalogCardSaveChanges,
          )
      ],
    );
  }

  Widget _buildProgresoUnidad(BuildContext context, bool isEditable,
      AppLocalizations l10n, String tipo) {
    final int uniActual = _entrada.unidadActual ?? 0;
    final int uniTotal = _entrada.elementoTotalUnidades ?? 0;
    final String label = (tipo == 'anime')
        ? l10n.elementDetailAnimeEpisodes
        : l10n.elementDetailMangaChapters;

    return Row(
      children: <Widget>[
        Text(l10n.catalogCardUnitLabel(label),
            style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 20,
          color: isEditable && uniActual > 0 ? Colors.white : Colors.grey[700],
          onPressed: (isEditable && uniActual > 0)
              ? () => _handleUpdateProgreso(unidad: uniActual - 1)
              : null,
        ),
        Text(l10n.catalogCardUnitProgress(uniActual, uniTotal),
            style: Theme.of(context).textTheme.bodyLarge),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 20,
          color: isEditable && uniActual < uniTotal
              ? Colors.white
              : Colors.grey[700],
          onPressed: (isEditable && uniActual < uniTotal)
              ? () => _handleUpdateProgreso(unidad: uniActual + 1)
              : null,
        ),
        const Spacer(),
        if (_isLoading)
          const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
      ],
    );
  }

  void _handleUpdateProgresoLibro() {
    final int cap =
        int.tryParse(_capituloController.text) ?? _entrada.capituloActual ?? 0;
    final int pag =
        int.tryParse(_paginaController.text) ?? _entrada.paginaActual ?? 0;

    if (cap == _entrada.capituloActual && pag == _entrada.paginaActual) {
      FocusScope.of(context).unfocus();
      return;
    }

    _handleUpdateProgreso(capitulo: cap, pagina: pag, esGuardadoManual: true);
  }

  Widget _buildEstadoDropdown(
      BuildContext context, bool isEditable, AppLocalizations l10n) {
    return DropdownButton<EstadoPersonal>(
      value: EstadoPersonal.fromString(_entrada.estadoPersonal),
      icon: Icon(Icons.arrow_drop_down,
          color: Theme.of(context).colorScheme.primary),
      underline: const SizedBox(),
      style: Theme.of(context).textTheme.titleMedium,
      dropdownColor: Theme.of(context).colorScheme.surface,
      onChanged: isEditable
          ? (EstadoPersonal? newValue) {
              if (newValue != null) {
                _handleUpdateEstado(newValue.apiValue);
              }
            }
          : null,
      items: EstadoPersonal.values.map((EstadoPersonal estado) {
        return DropdownMenuItem(
          value: estado,
          child: Text(estado.displayName(context),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white)),
        );
      }).toList(),
    );
  }
}
