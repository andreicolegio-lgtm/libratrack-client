import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/catalog_service.dart';
import '../../../model/catalogo_entrada.dart';
import '../../../model/estado_personal.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/api_exceptions.dart';
import '../../../core/utils/error_translator.dart';
import '../../elemento/elemento_detail_screen.dart';
import '../../../core/widgets/maybe_marquee.dart';

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

  // Controladores
  final _temporadaController = TextEditingController();
  final _unidadController = TextEditingController();
  final _capituloController = TextEditingController();
  final _paginaController = TextEditingController();
  final _duracionController = TextEditingController();

  bool _isLoading = false;
  List<int> _episodiosPorTemporada = [];

  Map<String, dynamic> _initialValues = {};

  @override
  void initState() {
    super.initState();
    _catalogService = context.read<CatalogService>();
    _initValues();

    // Store initial values for progress-related fields
    _initialValues = {
      'capituloActual': widget.entrada.capituloActual,
      'paginaActual': widget.entrada.paginaActual,
      'unidadActual': widget.entrada.unidadActual,
      'temporadaActual': widget.entrada.temporadaActual,
      'duracionActual': widget.entrada.unidadActual, // For movies
    };
  }

  @override
  void didUpdateWidget(covariant CatalogEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entrada != oldWidget.entrada) {
      _initValues();
    }
  }

  void _initValues() {
    _episodiosPorTemporada =
        _parseEpisodiosStr(widget.entrada.elementoEpisodiosPorTemporada);

    // Valores por defecto seguros
    _temporadaController.text =
        (widget.entrada.temporadaActual ?? 1).toString();
    _unidadController.text = (widget.entrada.unidadActual ?? 0).toString();
    _capituloController.text = (widget.entrada.capituloActual ?? 0).toString();
    _paginaController.text = (widget.entrada.paginaActual ?? 0).toString();

    if (widget.entrada.elementoTipoNombre == 'Movie') {
      int minutosVistos = widget.entrada.unidadActual ?? 0;
      _duracionController.text = _formatToTimeInput(minutosVistos);
    }
  }

  List<int> _parseEpisodiosStr(String? str) {
    if (str == null || str.isEmpty) {
      return [];
    }
    try {
      return str.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    } catch (_) {
      return [];
    }
  }

  // Calcula el progreso global de una serie sumando temporadas anteriores
  double _calculateSeriesProgress() {
    if (_episodiosPorTemporada.isEmpty) {
      return 0.0;
    }

    int currentSeason = widget.entrada.temporadaActual ?? 1;
    int currentEp = widget.entrada.unidadActual ?? 0;

    // 1. Sumar episodios de temporadas ANTERIORES completas
    int totalEpisodesWatched = 0;
    for (int i = 0; i < currentSeason - 1; i++) {
      if (i < _episodiosPorTemporada.length) {
        totalEpisodesWatched += _episodiosPorTemporada[i];
      }
    }

    // 2. Sumar episodios vistos de la temporada ACTUAL
    totalEpisodesWatched += currentEp;

    // 3. Calcular total absoluto de la serie
    int totalSeriesEpisodes =
        _episodiosPorTemporada.fold(0, (sum, val) => sum + val);

    if (totalSeriesEpisodes == 0) {
      return 0.0;
    }

    return totalEpisodesWatched / totalSeriesEpisodes;
  }

  // Calcula el progreso de libro usando el MAYOR avance entre caps y págs
  double _calculateBookProgress() {
    final t = widget.entrada;
    double progressPages = 0.0;
    double progressChapters = 0.0;

    // Porcentaje por Páginas
    if ((t.elementoTotalPaginasLibro ?? 0) > 0) {
      progressPages = (t.paginaActual ?? 0) / t.elementoTotalPaginasLibro!;
    }

    // Porcentaje por Capítulos
    if ((t.elementoTotalCapitulosLibro ?? 0) > 0) {
      progressChapters =
          (t.capituloActual ?? 0) / t.elementoTotalCapitulosLibro!;
    }

    // Devolvemos el que sea mayor (el más avanzado determina el visual)
    return progressPages > progressChapters ? progressPages : progressChapters;
  }

  String _formatMinutosToVerbose(int totalMinutos) {
    final l10n = AppLocalizations.of(context);
    if (totalMinutos <= 0) {
      return '0 ${l10n.unitMin}';
    }
    final h = totalMinutos ~/ 60;
    final m = totalMinutos % 60;
    if (h > 0) {
      return '$h ${l10n.unitHr} ${m > 0 ? "$m ${l10n.unitMin}" : ""}';
    } else {
      return '$m ${l10n.unitMin}';
    }
  }

  String _formatToTimeInput(int totalMinutos) {
    if (totalMinutos <= 0) {
      return '0:00';
    }
    final h = totalMinutos ~/ 60;
    final m = totalMinutos % 60;
    // Devuelve "1:30" o "0:45"
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  int _parseHHmmToMinutos(String value) {
    if (!value.contains(':')) {
      return int.tryParse(value) ?? 0;
    }
    final parts = value.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60) + m;
  }

  @override
  void dispose() {
    _temporadaController.dispose();
    _unidadController.dispose();
    _capituloController.dispose();
    _paginaController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  // --- Lógica de Actualización ---

  Future<void> _updateEstado(EstadoPersonal nuevoEstado) async {
    // Si es el mismo estado, no hacemos nada
    if (nuevoEstado.apiValue == widget.entrada.estadoPersonal) {
      return;
    }

    final EstadoPersonal estadoAnterior =
        EstadoPersonal.fromString(widget.entrada.estadoPersonal);

    setState(() => _isLoading = true);
    try {
      final updates = <String, dynamic>{'estadoPersonal': nuevoEstado.apiValue};

      // PUNTO 7: Si salimos de 'Terminado' a otro estado (ej. En Progreso), reseteamos progreso?
      // Normalmente se prefiere resetear a 0 o preguntar, aquí lo reseteamos a 0 según tu petición.
      if (estadoAnterior == EstadoPersonal.terminado &&
          nuevoEstado != EstadoPersonal.terminado) {
        updates['temporadaActual'] = 1;
        updates['unidadActual'] = 0;
        updates['capituloActual'] = 0;
        updates['paginaActual'] = 0;
      }

      // PUNTO 3 (Previo): Si marcamos como terminado, llenamos barra.
      else if (nuevoEstado == EstadoPersonal.terminado) {
        _fillProgressToMax(updates);
      }

      await _catalogService.updateEntrada(widget.entrada.elementoId, updates);
      widget.onUpdate();
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fillProgressToMax(Map<String, dynamic> updates) {
    final t = widget.entrada;
    final type = t.elementoTipoNombre;

    if (type == 'Book') {
      if ((t.elementoTotalPaginasLibro ?? 0) > 0) {
        updates['paginaActual'] = t.elementoTotalPaginasLibro;
      }
      if ((t.elementoTotalCapitulosLibro ?? 0) > 0) {
        updates['capituloActual'] = t.elementoTotalCapitulosLibro;
      }
    } else if (type == 'Anime') {
      if ((t.elementoTotalUnidades ?? 0) > 0) {
        updates['unidadActual'] = t.elementoTotalUnidades;
      }
    } else if (type == 'Series') {
      if (_episodiosPorTemporada.isNotEmpty) {
        updates['temporadaActual'] = _episodiosPorTemporada.length;
        updates['unidadActual'] = _episodiosPorTemporada.last;
      }
    } else if (type == 'Movie') {
      int totalMin = _parseDuracionElemento(t.elementoDuracion);
      if (totalMin > 0) {
        updates['unidadActual'] = totalMin;
      }
    } else if (['Manga', 'Manhwa'].contains(type)) {
      if ((t.elementoTotalCapitulosLibro ?? 0) > 0) {
        updates['capituloActual'] = t.elementoTotalCapitulosLibro;
      }
    }
  }

  int _parseDuracionElemento(String? dur) {
    if (dur == null) {
      return 0;
    }
    final digits = dur.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return 0;
    }
    return int.tryParse(digits) ?? 0;
  }

  bool _hasChanges() {
    final type = widget.entrada.elementoTipoNombre;

    // Helper para comparar int vs string numérico
    bool isDifferent(String key, TextEditingController ctrl,
        {int defaultValue = 0}) {
      final int initial = _initialValues[key] as int? ?? defaultValue;
      final int current = int.tryParse(ctrl.text) ?? defaultValue;
      return initial != current;
    }

    if (type == 'Movie') {
      // Lógica especial para tiempo (HH:mm vs minutos totales)
      final int initialMin = _initialValues['duracionActual'] as int? ?? 0;
      final int currentMin = _parseHHmmToMinutos(_duracionController.text);
      return initialMin != currentMin;
    }

    // Lógica estándar para otros tipos
    bool changed = false;
    if (['Series'].contains(type)) {
      if (isDifferent('temporadaActual', _temporadaController,
          defaultValue: 1)) {
        changed = true;
      }
      if (isDifferent('unidadActual', _unidadController)) {
        changed = true;
      }
    } else if (type == 'Book') {
      if (isDifferent('capituloActual', _capituloController)) {
        changed = true;
      }
      if (isDifferent('paginaActual', _paginaController)) {
        changed = true;
      }
    } else if (type == 'Anime') {
      if (isDifferent('unidadActual', _unidadController)) {
        changed = true;
      }
    } else if (['Manga', 'Manhwa'].contains(type)) {
      if (isDifferent('capituloActual', _capituloController)) {
        changed = true;
      }
    }

    return changed;
  }

  Future<void> _saveProgress() async {
    final l10n = AppLocalizations.of(context);
    if (!_hasChanges()) {
      SnackBarHelper.showTopSnackBar(context, l10n.catalogProgressNoChanges,
          isError: false, isNeutral: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final type = widget.entrada.elementoTipoNombre;
    final updates = <String, dynamic>{};

    if (type == 'Book') {
      _addValidInt(updates, 'paginaActual', _paginaController.text,
          max: widget.entrada.elementoTotalPaginasLibro);
      _addValidInt(updates, 'capituloActual', _capituloController.text,
          max: widget.entrada.elementoTotalCapitulosLibro);
    } else if (type == 'Series') {
      int newSeason = int.tryParse(_temporadaController.text) ?? 1;
      int oldSeason = widget.entrada.temporadaActual ?? 1;
      if (newSeason != oldSeason) {
        updates['unidadActual'] = 1; // Reset episodio al cambiar temporada
        _unidadController.text = '1';
      } else {
        int maxEps = _getMaxEpsForSeason(newSeason);
        _addValidInt(updates, 'unidadActual', _unidadController.text,
            max: maxEps > 0 ? maxEps : null);
      }
      if (_episodiosPorTemporada.isNotEmpty) {
        newSeason = newSeason.clamp(1, _episodiosPorTemporada.length);
      }
      updates['temporadaActual'] = newSeason;
    } else if (type == 'Movie') {
      int minutos = _parseHHmmToMinutos(_duracionController.text);
      int totalDuracion =
          _parseDuracionElemento(widget.entrada.elementoDuracion);
      if (totalDuracion > 0) {
        minutos = minutos.clamp(0, totalDuracion);
      }
      updates['unidadActual'] = minutos;
    } else if (type == 'Anime') {
      _addValidInt(updates, 'unidadActual', _unidadController.text,
          max: widget.entrada.elementoTotalUnidades);
    } else if (['Manga', 'Manhwa'].contains(type)) {
      _addValidInt(updates, 'capituloActual', _capituloController.text,
          max: widget.entrada.elementoTotalCapitulosLibro);
    }

    // PUNTO 2: Auto-detectar completado y cambiar estado
    if (_checkIfCompleted(updates, type)) {
      updates['estadoPersonal'] = EstadoPersonal.terminado.apiValue;
    }

    try {
      await _catalogService.updateEntrada(widget.entrada.elementoId, updates);
      widget.onUpdate();
      if (mounted) {
        // Feedback visual rápido
        SnackBarHelper.showTopSnackBar(context, l10n.catalogProgressSaved,
            isError: false);
      }

      // Update _initialValues after a successful save
      _initialValues = {
        'capituloActual': updates['capituloActual'] ?? _capituloController.text,
        'paginaActual': updates['paginaActual'] ?? _paginaController.text,
        'unidadActual': updates['unidadActual'] ?? _unidadController.text,
        'temporadaActual':
            updates['temporadaActual'] ?? _temporadaController.text,
        'duracionActual': updates['unidadActual'] ?? _duracionController.text,
      };
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Lógica simple para detectar si llegó al final
  bool _checkIfCompleted(Map<String, dynamic> updates, String type) {
    if (type == 'Book') {
      int pag = updates['paginaActual'] ?? widget.entrada.paginaActual ?? 0;
      int total = widget.entrada.elementoTotalPaginasLibro ?? 0;
      return total > 0 && pag >= total;
    } else if (type == 'Anime') {
      int ep = updates['unidadActual'] ?? widget.entrada.unidadActual ?? 0;
      int total = widget.entrada.elementoTotalUnidades ?? 0;
      return total > 0 && ep >= total;
    }
    // Se puede expandir para otros tipos
    return false;
  }

  void _addValidInt(Map<String, dynamic> map, String key, String value,
      {int? max}) {
    int? val = int.tryParse(value);
    if (val != null) {
      if (max != null && max > 0) {
        val = val.clamp(0, max);
      }
      map[key] = val;
    }
  }

  int _getMaxEpsForSeason(int season) {
    if (season > 0 && season <= _episodiosPorTemporada.length) {
      return _episodiosPorTemporada[season - 1];
    }
    return 0;
  }

  void _showNotesDialog() {
    final l10n = AppLocalizations.of(context);
    // 1. Capturamos el valor original
    final String originalNotes = widget.entrada.notas ?? '';
    final controller = TextEditingController(text: originalNotes);

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(l10n.dialogNotesTitle),
              content: TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                    hintText: l10n.dialogNotesHint,
                    border: const OutlineInputBorder()),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.actionCancel)),
                FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // 2. Comparamos. Si es igual, no hacemos nada.
                      if (controller.text.trim() == originalNotes.trim()) {
                        return;
                      }

                      await _saveNotes(controller.text);
                    },
                    child: Text(l10n.actionSave)),
              ],
            ));
  }

  Future<void> _saveNotes(String notas) async {
    try {
      // Se envía solo el campo notas
      await _catalogService
          .updateEntrada(widget.entrada.elementoId, {'notas': notas});
      widget.onUpdate();
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(Object e) {
    if (!mounted) {
      return;
    }
    String msg = e.toString();
    if (e is ApiException) {
      msg = ErrorTranslator.translate(context, e.message);
    }
    SnackBarHelper.showTopSnackBar(context, msg, isError: true);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Altura dinámica para mejorar accesibilidad
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ElementoDetailScreen(elementoId: widget.entrada.elementoId),
                settings: const RouteSettings(name: 'ElementoDetailScreen'),
              ));
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Adjusted to stretch
            children: [
              // PUNTO 6: Imagen con Aspect Ratio 2:3 para no estirarse
              // Usamos BoxFit.cover para llenar el contenedor, pero el AspectRatio previene distorsión rara
              SizedBox(
                width: 130,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: widget.entrada.elementoUrlImagen != null
                      ? CachedNetworkImage(
                          imageUrl: widget.entrada.elementoUrlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: theme.colorScheme.surfaceContainerHighest),
                          errorWidget: (_, __, ___) => Container(
                              color: Colors.grey,
                              child: const Icon(Icons.broken_image)),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image)),
                ),
              ),

              // Contenido Derecho
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Info Superior
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MaybeMarquee(
                            text: widget.entrada.elementoTitulo,
                            style: theme.textTheme.titleMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          // Tipo y Géneros (Marquee)
                          SizedBox(
                            height: 20,
                            child: MaybeMarquee(
                              text:
                                  "${widget.entrada.elementoTipoNombre} • ${widget.entrada.elementoGeneros ?? '...'}",
                              style: theme.textTheme.bodySmall!
                                  .copyWith(color: theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Barra de Progreso e Inputs
                          // PUNTO 1: Si es Videojuego, no mostramos nada aquí
                          if (widget.entrada.elementoTipoNombre !=
                              'Video Game') ...[
                            _buildProgressBar(theme),
                            const SizedBox(height: 12),
                            _buildProgressInputs(theme),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 12), // Garantiza espacio mínimo (Problema 1)
                    const Spacer(), // Empuja la barra al fondo (Problema 2)

                    // Barra de Acciones Inferior
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: EstadoPersonal.fromString(
                                  widget.entrada.estadoPersonal)
                              .color
                              .withAlpha(38), // 15% opacity
                          // Opcional: Borde superior del mismo color
                          border: Border(
                              top: BorderSide(
                                  color: EstadoPersonal.fromString(
                                          widget.entrada.estadoPersonal)
                                      .color
                                      .withAlpha(77))), // 30% opacity
                        ),
                        child: Row(
                          children: [
                            // Estado Dropdown
                            DropdownButton<EstadoPersonal>(
                              value: EstadoPersonal.fromString(
                                  widget.entrada.estadoPersonal),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              style: theme.textTheme.bodySmall!
                                  .copyWith(fontWeight: FontWeight.w600),
                              onChanged:
                                  _isLoading ? null : (v) => _updateEstado(v!),
                              items: EstadoPersonal.values
                                  .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(children: [
                                        Icon(Icons.circle,
                                            size: 8, color: e.color),
                                        const SizedBox(width: 6),
                                        Text(e.displayName(context)),
                                      ])))
                                  .toList(),
                            ),
                            const Spacer(),

                            // PUNTO 4: Icono Notas más intuitivo (edit_note)
                            IconButton(
                              icon: Icon(
                                widget.entrada.notas != null &&
                                        widget.entrada.notas!.isNotEmpty
                                    ? Icons.description
                                    : Icons.edit_note,
                                size: 22,
                                color: widget.entrada.notas != null &&
                                        widget.entrada.notas!.isNotEmpty
                                    ? theme.colorScheme.primary
                                    : Colors.grey[700],
                              ),
                              onPressed: _showNotesDialog,
                              tooltip: l10n.tooltipNotes,
                            ),

                            // Botón Favorito
                            IconButton(
                              icon: Icon(
                                  widget.entrada.esFavorito
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 24,
                                  color: widget.entrada.esFavorito
                                      ? Colors.amber
                                      : Colors.grey),
                              onPressed: () async {
                                await _catalogService
                                    .toggleFavorite(widget.entrada.elementoId);
                                widget.onUpdate();
                              },
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildProgressBar(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    double progress = 0.0;
    String text = '';
    final t = widget.entrada;
    final type = t.elementoTipoNombre;

    // --- LÓGICA LIBRO ---
    // Formato: Cap 53/54 • 900/1000 Pág
    if (type == 'Book') {
      progress =
          _calculateBookProgress(); // Mantiene la lógica híbrida que te gustaba

      final currP = t.paginaActual ?? 0;
      final totalP = t.elementoTotalPaginasLibro ?? 0;
      final currC = t.capituloActual ?? 0;
      final totalC = t.elementoTotalCapitulosLibro ?? 0;

      // Construimos el string exacto que pediste
      String txtCap = "${l10n.unitCap} $currC/${totalC > 0 ? totalC : '?'}";
      String txtPag = "$currP/${totalP > 0 ? totalP : '?'} ${l10n.unitPage}";

      text = '$txtCap • $txtPag';
    }

    // --- LÓGICA SERIES ---
    // Formato: S 3/5 • 20/29 Eps
    else if (type == 'Series') {
      progress = _calculateSeriesProgress(); // Mantiene el cálculo global

      int season = t.temporadaActual ?? 1;
      int ep = t.unidadActual ?? 0;
      int maxEpsCurrent = _getMaxEpsForSeason(season);
      int totalSeasons = _episodiosPorTemporada.length;

      // Construimos el string exacto que pediste
      String txtSeason =
          "${l10n.unitSeason} $season/${totalSeasons > 0 ? totalSeasons : '?'}";
      String txtEp =
          "$ep/${maxEpsCurrent > 0 ? maxEpsCurrent : '?'} ${l10n.unitEp}";

      text = '$txtSeason • $txtEp';
    }
    // --- OTROS TIPOS (Sin cambios en formato, pero mantenemos lógica) ---
    else if (type == 'Movie') {
      int minVistos = t.unidadActual ?? 0;
      int totalMin = _parseDuracionElemento(t.elementoDuracion);

      String vistosStr = _formatMinutosToVerbose(minVistos);
      String totalStr = _formatMinutosToVerbose(totalMin);
      text = '$vistosStr / $totalStr';
      if (totalMin > 0) {
        progress = minVistos / totalMin;
      }
    } else if (type == 'Anime') {
      final total = t.elementoTotalUnidades ?? 0;
      final current = t.unidadActual ?? 0;
      text = "$current${total > 0 ? '/$total' : ''} ${l10n.unitEp}";
      if (total > 0) {
        progress = current / total;
      }
    } else if (['Manga', 'Manhwa'].contains(type)) {
      final total = t.elementoTotalCapitulosLibro ?? 0;
      final current = t.capituloActual ?? 0;
      text = "$current${total > 0 ? '/$total' : ''} ${l10n.unitCap}";
      if (total > 0) {
        progress = current / total;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text,
                style: theme.textTheme.labelSmall!
                    .copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
            if (progress > 0)
              Text('${(progress * 100).toInt()}%',
                  style: theme.textTheme.labelSmall!.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildProgressInputs(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final type = widget.entrada.elementoTipoNombre;

    if (_isLoading) {
      return const SizedBox(
          height: 40,
          child: Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))));
    }

    Widget inputs;

    if (type == 'Series') {
      inputs = Row(children: [
        _labeledInput(_temporadaController, l10n.inputTemp),
        const SizedBox(width: 8),
        _labeledInput(_unidadController, l10n.inputEpisodes),
      ]);
    } else if (type == 'Book') {
      inputs = Row(children: [
        _labeledInput(_capituloController, l10n.inputChapter),
        const SizedBox(width: 8),
        _labeledInput(_paginaController, l10n.inputPage),
      ]);
    } else if (type == 'Movie') {
      inputs = Row(children: [
        _labeledInput(_duracionController, l10n.inputTime, isTime: true),
      ]);
    } else if (type == 'Anime') {
      inputs = Row(children: [
        _labeledInput(_unidadController, l10n.inputEpisode),
      ]);
    } else if (['Manga', 'Manhwa'].contains(type)) {
      inputs = Row(children: [
        _labeledInput(_capituloController, l10n.inputChapter),
      ]);
    } else {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        inputs, // Los campos se quedan a la izquierda (compactos)

        // CAMBIO: Usamos Spacer() para empujar el botón al extremo derecho
        const Spacer(),

        SizedBox(
          height: 40,
          width: 40,
          child: IconButton.filledTonal(
            onPressed: _saveProgress,
            icon: const Icon(Icons.check),
            tooltip: l10n.tooltipSaveProgress,
          ),
        )
      ],
    );
  }

  /// Calcula el ancho que ocupa un texto con un estilo y tamaño de fuente específicos.
  double _measureLabelWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        // Usamos el mismo estilo que tiene tu input decoration (fontSize 13 aprox)
        style: const TextStyle(fontSize: 13),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Devolvemos el ancho del texto + un margen de seguridad (24px)
    // para los bordes del input y el padding interno.
    // También aseguramos un ancho mínimo de 50px para que no quede ridículamente pequeño.
    double width = textPainter.width + 24.0;
    return width < 50.0 ? 50.0 : width;
  }

  Widget _labeledInput(TextEditingController ctrl, String label,
      {bool isTime = false}) {
    // 1. Calculamos el ancho basándonos en la etiqueta
    double calculatedWidth = _measureLabelWidth(label);

    // 2. Si es de tiempo (HH:mm), aseguramos espacio suficiente para los números
    // aunque la etiqueta "Time" sea corta.
    if (isTime && calculatedWidth < 80) {
      calculatedWidth = 80;
    }

    return SizedBox(
      width: calculatedWidth,
      height: 40,
      child: TextField(
        controller: ctrl,
        keyboardType: isTime ? TextInputType.datetime : TextInputType.number,
        inputFormatters: isTime
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))]
            : [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          // Reducimos el padding horizontal para que quepa bien en anchos ajustados
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}
