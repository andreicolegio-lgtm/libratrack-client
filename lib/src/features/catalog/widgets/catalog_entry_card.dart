// Archivo: lib/src/features/catalog/widgets/catalog_entry_card.dart
// (¡CORREGIDO!)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/core/widgets/maybe_marquee.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/estado_personal.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/features/elemento/elemento_detail_screen.dart';
import 'dart:math'; // Para 'max'
import 'package:libratrack_client/src/core/utils/api_exceptions.dart'; // <-- ¡NUEVA IMPORTACIÓN!

/// --- ¡GRAN REFACTOR (Sprint 2 / V2 - Fase 3 REVISIÓN)! ---
class CatalogEntryCard extends StatefulWidget {
  final CatalogoEntrada entrada;
  final VoidCallback onUpdate;

  const CatalogEntryCard({
    super.key,
    required this.entrada,
    required this.onUpdate,
  });

  @override
  State<CatalogEntryCard> createState() => _CatalogEntryCardState();
}

class _CatalogEntryCardState extends State<CatalogEntryCard> {
  // --- ¡CORREGIDO (Error 1)! ---
  // Se elimina la instancia local y se declara 'late final'
  late final CatalogService _catalogService;
  // final CatalogService _catalogService = CatalogService();
  // ---

  // --- ¡NUEVO! Controladores para Libros (Petición e) ---
  final TextEditingController _capituloController = TextEditingController();
  final TextEditingController _paginaController = TextEditingController();

  late CatalogoEntrada _entrada;
  bool _isLoading = false;

  // ¡NUEVO! Lista de episodios por temporada (ej. [10, 8, 12])
  List<int> _episodiosPorTemporada = [];

  @override
  void initState() {
    super.initState();
    // --- ¡CORREGIDO (Error 1)! ---
    // Obtenemos el servicio desde Provider ANTES de usarlo.
    _catalogService = context.read<CatalogService>();
    // ---
    _actualizarEstadoEntrada(widget.entrada);
  }

  // Actualiza todo si la entrada (de la pantalla principal) cambia
  @override
  void didUpdateWidget(covariant CatalogEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entrada != oldWidget.entrada) {
      _actualizarEstadoEntrada(widget.entrada);
    }
  }

  /// ¡NUEVO! Helper centralizado para actualizar el estado local
  void _actualizarEstadoEntrada(CatalogoEntrada nuevaEntrada) {
    _entrada = nuevaEntrada;

    // Parseamos la data de progreso de la Serie
    _episodiosPorTemporada =
        _parseEpisodiosPorTemporada(_entrada.elementoEpisodiosPorTemporada);

    // Rellenamos los TextFields de Libro
    _capituloController.text = (_entrada.capituloActual ?? 0).toString();
    _paginaController.text = (_entrada.paginaActual ?? 0).toString();
  }

  @override
  void dispose() {
    _capituloController.dispose();
    _paginaController.dispose();
    super.dispose();
  }

  // --- Lógica de Actualización de Estado (Petición f) ---
  Future<void> _handleUpdateEstado(String nuevoEstado) async {
    // (Petición f) Si el estado no ha cambiado, no hacemos nada.
    if (nuevoEstado == _entrada.estadoPersonal) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // --- ¡CORREGIDO (Error 2)! ---
      // Se llama al nuevo método 'updateEstado' y se pasa el ID como String.
      await _catalogService.updateEstado(
        _entrada.elementoId,
        nuevoEstado,
      );
      // ---

      if (mounted) {
        widget.onUpdate(); // Recarga toda la lista para mover la tarjeta
        // No necesitamos actualizar el estado local,
        // ya que onUpdate() reconstruirá el widget con la nueva entrada.
        SnackBarHelper.showTopSnackBar(msgContext, 'Estado actualizado.',
            isError: false);
      }
    // --- ¡MEJORADO! ---
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, 'Error al actualizar: $e', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: ${e.toString()}', isError: true);
      }
    }
  }

  // --- Lógica de Actualización de Progreso (Petición g) ---
  Future<void> _handleUpdateProgreso({
    int? temporada,
    int? unidad,
    int? capitulo,
    int? pagina,
    bool esGuardadoManual = false, // Para saber si viene de un botón "Guardar"
  }) async {
    // Evitamos llamadas si ya estamos cargando
    if (_isLoading) return;

    // (Petición f) Si es un guardado manual y no hay cambios, no hacemos nada
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
    final msgContext = ScaffoldMessenger.of(context);

    String? estadoFinal; // Empezamos en null
    bool autoTerminado = false;
    final tipo = _entrada.elementoTipoNombre.toLowerCase();

    // --- LÓGICA DE AUTO-TERMINADO (Petición g) ---
    final totalEpsAnime = _entrada.elementoTotalUnidades ?? 0;
    final totalPagLibro = _entrada.elementoTotalPaginasLibro ?? 0;
    final totalTemps = _episodiosPorTemporada.length;

    if (tipo == 'serie' && temporada != null && unidad != null && totalTemps > 0) {
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
        _entrada.estadoPersonal != EstadoPersonal.TERMINADO.apiValue) {
      estadoFinal = EstadoPersonal.TERMINADO.apiValue;
    }
    // --- Fin Petición (g) ---

    try {
      // --- ¡CORREGIDO (Error 3)! ---
      // Se llama al nuevo método 'updateProgreso' y se crea el body.
      final Map<String, dynamic> body = {
        'estadoPersonal': estadoFinal, // Envía "TERMINADO" si se autocompletó
        'temporadaActual': temporada,
        'unidadActual': unidad,
        'capituloActual': capitulo,
        'paginaActual': pagina,
      };
      // Eliminamos valores nulos para no enviar datos innecesarios
      body.removeWhere((key, value) => value == null);
      
      await _catalogService.updateProgreso(
        _entrada.elementoId,
        body,
      );
      // ---

      if (mounted) {
        // Si el estado cambió, recargamos toda la lista para mover la tarjeta
        if (estadoFinal != null) {
          widget.onUpdate();
        } else {
          // Si no, solo actualizamos esta tarjeta.
          // Hacemos una recarga simple para obtener la entrada actualizada.
          // (Una V3 podría optimizar esto actualizando localmente)
          widget.onUpdate(); // Simplificado a solo llamar a onUpdate
        }
        // Solo mostramos SnackBar en guardado manual
        if (esGuardadoManual) {
          SnackBarHelper.showTopSnackBar(
              msgContext, 'Progreso guardado.', isError: false);
        }
      }
    // --- ¡MEJORADO! ---
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
            msgContext, 'Error al actualizar: $e', isError: true);
      }
    } catch (e) {
       if (mounted) {
        setState(() { _isLoading = false; });
        SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: ${e.toString()}', isError: true);
      }
    }
  }

  /// Calcula el valor de la barra de progreso
  double get _progresoValue {
    if (_entrada.estadoPersonal == EstadoPersonal.TERMINADO.apiValue) return 1.0;

    final tipo = _entrada.elementoTipoNombre.toLowerCase();

    try {
      if (tipo == 'serie') {
        if (_episodiosPorTemporada.isEmpty) return 0.0;
        final totalEps =
            _episodiosPorTemporada.fold<int>(0, (prev, e) => prev + e);
        if (totalEps == 0) return 0.0;

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
        if (pagTotal <= 0) return 0.0;
        return ((_entrada.paginaActual ?? 0) / pagTotal).clamp(0.0, 1.0);
      } else {
        // Anime, Manga
        int uniTotal = _entrada.elementoTotalUnidades ?? 0;
        if (uniTotal <= 0) return 0.0;
        return ((_entrada.unidadActual ?? 0) / uniTotal).clamp(0.0, 1.0);
      }
    } catch (e) {
      return 0.0;
    }
  }

  /// Helper para parsear el string "10,8,12" a [10, 8, 12]
  List<int> _parseEpisodiosPorTemporada(String? data) {
    if (data == null || data.isEmpty) return [];
    try {
      return data.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditable = !_isLoading;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color fadedIconColor = onSurfaceColor.withAlpha(0x80);

    // Ocultamos la UI de progreso si no es necesaria (Películas, Videojuegos)
    final tipo = _entrada.elementoTipoNombre.toLowerCase();
    final bool mostrarProgresoUI =
        tipo == 'serie' || tipo == 'libro' || tipo == 'anime' || tipo == 'manga';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: isEditable
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ElementoDetailScreen(elementoId: _entrada.elementoId),
                  ),
                ).then((_) => widget.onUpdate());
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageContainer(fadedIconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MaybeMarquee(
                      text: _entrada.elementoTitulo,
                      style: Theme.of(context).textTheme.titleMedium ??
                          const TextStyle(),
                    ),
                    if (mostrarProgresoUI) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _progresoValue,
                        backgroundColor: Colors.grey[700],
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      // --- ¡INTERFAZ DE PROGRESO REEMPLAZADA! (Petición e) ---
                      _buildProgresoUI(context, isEditable),
                    ] else ...[
                      const SizedBox(height: 16), // Espacio reservado
                    ],

                    // Dropdown de Estado
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: _buildEstadoDropdown(context, isEditable),
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildImageContainer(Color fadedIconColor) {
    // ... (sin cambios)
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
                placeholder: (context, url) =>
                    Center(child: Icon(Icons.downloading, color: fadedIconColor)),
                errorWidget: (context, url, error) =>
                    Icon(Icons.broken_image, color: fadedIconColor),
              )
            : Icon(Icons.image, size: 40, color: fadedIconColor),
      ),
    );
  }

  /// --- ¡WIDGET REFACTORIZADO! (Petición b, d, e) ---
  /// Construye la UI de progreso correcta según el tipo de elemento
  Widget _buildProgresoUI(BuildContext context, bool isEditable) {
    final tipo = _entrada.elementoTipoNombre.toLowerCase();

    if (tipo == 'serie') {
      return _buildProgresoSerie(context, isEditable);
    }
    if (tipo == 'libro') {
      return _buildProgresoLibro(context, isEditable);
    }
    if (tipo == 'anime' || tipo == 'manga') {
      return _buildProgresoUnidad(context, isEditable, tipo);
    }

    // Películas, Videojuegos
    return const SizedBox(height: 36); // Espacio reservado
  }

  /// UI para Series (Temporada Y Episodio) - (Petición b)
  Widget _buildProgresoSerie(BuildContext context, bool isEditable) {
    final int tempActual = (_entrada.temporadaActual ?? 1)
        .clamp(1, max(1, _episodiosPorTemporada.length));
    final int epTotalTempActual = (tempActual - 1 < _episodiosPorTemporada.length)
        ? _episodiosPorTemporada[tempActual - 1]
        : 0;
    final int epActual =
        (_entrada.unidadActual ?? 0).clamp(0, max(0, epTotalTempActual));

    // Generamos las listas para los Dropdowns
    final List<int> temporadas =
        List.generate(_episodiosPorTemporada.length, (i) => i + 1);
    final List<int> episodios =
        List.generate(epTotalTempActual + 1, (i) => i); // +1 para incluir el 0

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dropdown Temporada
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: tempActual,
            items: temporadas
                .map((t) => DropdownMenuItem(value: t, child: Text('T$t')))
                .toList(),
            onChanged: isEditable
                ? (val) {
                    if (val == null || val == _entrada.temporadaActual) return;
                    // Al cambiar de temporada, reseteamos el episodio a 0
                    _handleUpdateProgreso(temporada: val, unidad: 0);
                  }
                : null,
            decoration: const InputDecoration.collapsed(hintText: ''),
            style: Theme.of(context).textTheme.bodyMedium,
            dropdownColor: Theme.of(context).colorScheme.surface,
          ),
        ),

        const SizedBox(width: 16),

        // Dropdown Episodio
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: epActual,
            items: episodios
                .map((e) => DropdownMenuItem(value: e, child: Text('Ep $e')))
                .toList(),
            onChanged: isEditable
                ? (val) {
                    if (val == null || val == _entrada.unidadActual) return;
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

  /// UI para Libros (Capítulo Y Página) - (Petición e)
  Widget _buildProgresoLibro(BuildContext context, bool isEditable) {
    return Row(
      children: [
        // Campo Capítulo
        Expanded(
          child: TextField(
            controller: _capituloController,
            enabled: isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Capítulo',
              hintText: 'Total: ${_entrada.elementoTotalCapitulosLibro ?? 0}',
              isDense: true,
            ),
            onSubmitted: (_) => _handleUpdateProgresoLibro(),
          ),
        ),
        const SizedBox(width: 16),
        // Campo Página
        Expanded(
          child: TextField(
            controller: _paginaController,
            enabled: isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Página',
              hintText: 'Total: ${_entrada.elementoTotalPaginasLibro ?? 0}',
              isDense: true,
            ),
            onSubmitted: (_) => _handleUpdateProgresoLibro(),
          ),
        ),
        // Botón Guardar
        if (isEditable)
          IconButton(
            icon: Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
            onPressed: _handleUpdateProgresoLibro,
            tooltip: 'Guardar Progreso',
          )
      ],
    );
  }

  /// UI para Anime/Manga (Solo Unidad) - (Petición e)
  Widget _buildProgresoUnidad(
      BuildContext context, bool isEditable, String tipo) {
    final uniActual = _entrada.unidadActual ?? 0;
    final uniTotal = _entrada.elementoTotalUnidades ?? 0;
    final label = (tipo == 'anime') ? 'Episodio' : 'Capítulo';

    return Row(
      children: [
        Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 20,
          color: isEditable && uniActual > 0 ? Colors.white : Colors.grey[700],
          onPressed: (isEditable && uniActual > 0)
              ? () => _handleUpdateProgreso(unidad: uniActual - 1)
              : null,
        ),
        Text('$uniActual / $uniTotal',
            style: Theme.of(context).textTheme.bodyLarge),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 20,
          color:
              isEditable && uniActual < uniTotal ? Colors.white : Colors.grey[700],
          onPressed: (isEditable && uniActual < uniTotal)
              ? () => _handleUpdateProgreso(unidad: uniActual + 1)
              : null,
        ),
        const Spacer(), // Ocupa espacio
        if (_isLoading)
          const SizedBox(
              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
      ],
    );
  }

  /// ¡NUEVO! Helper para guardar los TextFields de Libro
  void _handleUpdateProgresoLibro() {
    final int cap =
        int.tryParse(_capituloController.text) ?? _entrada.capituloActual ?? 0;
    final int pag =
        int.tryParse(_paginaController.text) ?? _entrada.paginaActual ?? 0;

    // (Petición f) Comprobar si hay cambios
    if (cap == _entrada.capituloActual && pag == _entrada.paginaActual) {
      FocusScope.of(context).unfocus();
      return;
    }

    _handleUpdateProgreso(capitulo: cap, pagina: pag, esGuardadoManual: true);
  }

  /// Dropdown simplificado de estado (RF06) - (Petición f)
  Widget _buildEstadoDropdown(BuildContext context, bool isEditable) {
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
                // Llama a la lógica que comprueba si hay cambios (Petición f)
                _handleUpdateEstado(newValue.apiValue);
              }
            }
          : null,
      items: EstadoPersonal.values.map((estado) {
        return DropdownMenuItem(
          value: estado,
          child: Text(estado.displayName,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white)),
        );
      }).toList(),
    );
  }
}