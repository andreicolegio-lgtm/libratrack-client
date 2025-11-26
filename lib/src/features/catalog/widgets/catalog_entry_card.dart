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

  const CatalogEntryCard({
    required this.entrada,
    required Null Function() onUpdate,
    super.key,
  });

  @override
  State<CatalogEntryCard> createState() => _CatalogEntryCardState();
}

class _CatalogEntryCardState extends State<CatalogEntryCard> {
  late final CatalogService _catalogService;

  // Controladores para inputs de progreso
  final _temporadaController = TextEditingController();
  final _unidadController = TextEditingController();
  final _capituloController = TextEditingController();
  final _paginaController = TextEditingController();

  bool _isLoading = false;
  List<int> _episodiosPorTemporada = [];

  @override
  void initState() {
    super.initState();
    _catalogService = context.read<CatalogService>();
    _initValues();
  }

  @override
  void didUpdateWidget(covariant CatalogEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entrada != oldWidget.entrada) {
      _initValues();
    }
  }

  void _initValues() {
    // Parsear configuración de episodios (Ej: "12,24,12")
    _episodiosPorTemporada =
        _parseEpisodiosStr(widget.entrada.elementoEpisodiosPorTemporada);

    // Inicializar controladores con valores actuales
    _temporadaController.text =
        (widget.entrada.temporadaActual ?? 1).toString();
    _unidadController.text = (widget.entrada.unidadActual ?? 0).toString();
    _capituloController.text = (widget.entrada.capituloActual ?? 0).toString();
    _paginaController.text = (widget.entrada.paginaActual ?? 0).toString();
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

  @override
  void dispose() {
    _temporadaController.dispose();
    _unidadController.dispose();
    _capituloController.dispose();
    _paginaController.dispose();
    super.dispose();
  }

  // --- Lógica de Negocio ---

  Future<void> _updateEstado(EstadoPersonal nuevoEstado) async {
    if (nuevoEstado.apiValue == widget.entrada.estadoPersonal) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Si marca como terminado, auto-completar progreso al máximo
      if (nuevoEstado == EstadoPersonal.terminado) {
        await _autoCompleteProgress();
      }

      // Actualizar estado en backend
      await _catalogService.updateEntrada(
        widget.entrada.elementoId,
        {'estadoPersonal': nuevoEstado.apiValue},
      );
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _autoCompleteProgress() async {
    final type = widget.entrada.elementoTipoNombre;
    final updates = <String, dynamic>{};

    if (type == 'Book') {
      updates['paginaActual'] = widget.entrada.elementoTotalPaginasLibro ?? 0;
    } else if (['Manga', 'Manhwa'].contains(type)) {
      updates['capituloActual'] =
          widget.entrada.elementoTotalCapitulosLibro ?? 0;
    } else if (type == 'Anime') {
      updates['unidadActual'] = widget.entrada.elementoTotalUnidades ?? 0;
    } else if (type == 'Series' && _episodiosPorTemporada.isNotEmpty) {
      updates['temporadaActual'] = _episodiosPorTemporada.length;
      updates['unidadActual'] = _episodiosPorTemporada.last;
    }

    if (updates.isNotEmpty) {
      await _catalogService.updateEntrada(widget.entrada.elementoId, updates);
    }
  }

  Future<void> _saveProgress() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final type = widget.entrada.elementoTipoNombre;
    final updates = <String, dynamic>{};

    // Recoger y validar valores según tipo
    if (type == 'Book') {
      _addValidInt(updates, 'paginaActual', _paginaController.text,
          max: widget.entrada.elementoTotalPaginasLibro);
    } else if (['Manga', 'Manhwa'].contains(type)) {
      _addValidInt(updates, 'capituloActual', _capituloController.text,
          max: widget.entrada.elementoTotalCapitulosLibro);
    } else if (type == 'Anime') {
      _addValidInt(updates, 'unidadActual', _unidadController.text,
          max: widget.entrada.elementoTotalUnidades);
    } else if (type == 'Series') {
      _addValidInt(updates, 'temporadaActual', _temporadaController.text,
          max: _episodiosPorTemporada.length);

      // Calcular max episodios para la temporada seleccionada
      int currentSeason = int.tryParse(_temporadaController.text) ?? 1;
      int? maxEps;
      if (currentSeason > 0 && currentSeason <= _episodiosPorTemporada.length) {
        maxEps = _episodiosPorTemporada[currentSeason - 1];
      }
      _addValidInt(updates, 'unidadActual', _unidadController.text,
          max: maxEps);
    }

    // Auto-detectar si se completó
    _checkCompletionLogic(updates, type);

    try {
      await _catalogService.updateEntrada(widget.entrada.elementoId, updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Progreso guardado'),
              duration: Duration(milliseconds: 800)),
        );
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addValidInt(Map<String, dynamic> map, String key, String value,
      {int? max}) {
    int? val = int.tryParse(value);
    if (val != null) {
      if (max != null && max > 0) {
        val = val.clamp(0, max); // Limitar al máximo real
      }
      map[key] = val;
    }
  }

  void _checkCompletionLogic(Map<String, dynamic> updates, String type) {
    // Lógica simple: si llegamos al total, preguntar o marcar como terminado?
    // Por ahora, solo actualizamos si el usuario lo hace manualmente o mediante el menú de estado
    // para no ser intrusivos.
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

  // --- Construcción de UI ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ElementoDetailScreen(
                      elementoId: widget.entrada.elementoId)));
        },
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de Portada
                SizedBox(
                  width: 100,
                  height: 140,
                  child: widget.entrada.elementoUrlImagen != null
                      ? CachedNetworkImage(
                          imageUrl: widget.entrada.elementoUrlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: theme.colorScheme.surfaceContainerHighest),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                        ),
                ),

                // Info Principal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MaybeMarquee(
                          text: widget.entrada.elementoTitulo,
                          style: theme.textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.entrada.elementoTipoNombre,
                          style: theme.textTheme.bodySmall!
                              .copyWith(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 12),

                        // Barra de Progreso Visual
                        _buildProgressBar(theme),

                        const SizedBox(height: 12),

                        // Inputs de Progreso
                        _buildProgressInputs(l10n),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Barra de Acciones Inferior
            Container(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Selector de Estado
                  DropdownButton<EstadoPersonal>(
                    value: EstadoPersonal.fromString(
                        widget.entrada.estadoPersonal),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.w500),
                    onChanged: _isLoading ? null : (v) => _updateEstado(v!),
                    items: EstadoPersonal.values.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: e.color),
                            const SizedBox(width: 8),
                            Text(e.displayName(context)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  // Botón Favorito
                  IconButton(
                    icon: Icon(
                      widget.entrada.esFavorito
                          ? Icons.star
                          : Icons.star_border,
                      color: widget.entrada.esFavorito
                          ? Colors.amber
                          : Colors.grey,
                    ),
                    onPressed: () => _catalogService
                        .toggleFavorite(widget.entrada.elementoId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    double progress = 0.0;
    String text = '';

    final t = widget.entrada;

    if (t.elementoTipoNombre == 'Anime') {
      final total = t.elementoTotalUnidades ?? 0;
      final current = t.unidadActual ?? 0;
      if (total > 0) {
        progress = current / total;
      }
      text = "$current / ${total > 0 ? total : '?'} Eps";
    } else if (t.elementoTipoNombre == 'Book') {
      final total = t.elementoTotalPaginasLibro ?? 0;
      final current = t.paginaActual ?? 0;
      if (total > 0) {
        progress = current / total;
      }
      text = "$current / ${total > 0 ? total : '?'} Pág";
    } else {
      // Lógica genérica para otros tipos
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: theme.textTheme.labelSmall),
            Text('${(progress * 100).toInt()}%',
                style: theme.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildProgressInputs(AppLocalizations l10n) {
    final type = widget.entrada.elementoTipoNombre;

    if (_isLoading) {
      return const Center(child: LinearProgressIndicator());
    }

    if (type == 'Series') {
      return Row(
        children: [
          _inputField(_temporadaController, 'Temp', width: 50),
          const SizedBox(width: 8),
          _inputField(_unidadController, 'Cap', width: 50),
          const Spacer(),
          _saveButton(),
        ],
      );
    } else if (type == 'Book') {
      return Row(
        children: [
          _inputField(_paginaController, 'Página'),
          const Spacer(),
          _saveButton(),
        ],
      );
    } else if (['Manga', 'Manhwa'].contains(type)) {
      return Row(
        children: [
          _inputField(_capituloController, 'Capítulo'),
          const Spacer(),
          _saveButton(),
        ],
      );
    } else if (type == 'Anime') {
      return Row(
        children: [
          _inputField(_unidadController, 'Episodio'),
          const Spacer(),
          _saveButton(),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _inputField(TextEditingController ctrl, String label,
      {double width = 80}) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return IconButton.filledTonal(
      icon: const Icon(Icons.check, size: 18),
      onPressed: _saveProgress,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}
