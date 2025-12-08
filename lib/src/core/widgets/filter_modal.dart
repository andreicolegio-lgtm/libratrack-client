import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/tipo_service.dart';
import '../../model/tipo.dart';
import '../l10n/app_localizations.dart';
import 'genre_selector_widget.dart';

class FilterModal extends StatefulWidget {
  final List<String> selectedTypes;
  final List<String> selectedGenres;
  final void Function(List<String> types, List<String> genres) onApply;

  // Parámetros de ordenamiento
  final String currentSortMode; // 'DATE' o 'ALPHA'
  final bool isAscending;
  final Function(String mode, bool ascending) onSortChanged;

  const FilterModal({
    required this.selectedTypes,
    required this.selectedGenres,
    required this.onApply,
    required this.currentSortMode,
    required this.isAscending,
    required this.onSortChanged,
    super.key,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  bool _isInitialized = false; // Para cargar datos solo una vez
  late List<String> _types;
  late List<String> _genres;
  late Future<List<Tipo>> _tiposFuture;

  late String _localSortMode;
  late bool _localAscending;

  @override
  void initState() {
    super.initState();
    _types = List.from(widget.selectedTypes);
    _genres = List.from(widget.selectedGenres);
    _localSortMode = widget.currentSortMode;
    _localAscending = widget.isAscending;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final l10n = AppLocalizations.of(context);
      _tiposFuture =
          context.read<TipoService>().fetchTipos(l10n.errorLoadingFilters);
      _isInitialized = true;
    }
  }

  void _resetFilters() {
    setState(() {
      _types.clear();
      _genres.clear();
      _localSortMode = 'DATE'; // Default sorting mode
      _localAscending = false; // Default sorting order
    });
    // IMPORTANTE: Notificar al padre que el orden ha vuelto al default (DATE, Descendente)
    widget.onSortChanged('DATE', false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(top: 16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera Fija
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.modalFiltersTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text(l10n.actionReset),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Contenido Scrollable (Incluye Orden, Tipos y Géneros)
            Expanded(
              child: FutureBuilder<List<Tipo>>(
                future: _tiposFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allTypeObjects = snapshot.data ?? [];
                  final selectedTypeObjects = allTypeObjects
                      .where((t) => _types.contains(t.nombre))
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Sección de Ordenar (Dentro del Scroll)
                        Text(
                          l10n.filterSortBy,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Chip Recientes (DATE)
                            _buildSortChip(
                              label: l10n.sortRecent, // "Recientes"
                              mode: 'DATE',
                              defaultIcon: Icons.history,
                            ),
                            const SizedBox(width: 8),
                            // Chip Alfabéticamente (ALPHA)
                            _buildSortChip(
                              label: l10n.sortAlpha, // "Alfabéticamente"
                              mode: 'ALPHA',
                              defaultIcon: Icons.sort_by_alpha,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 2. Sección Tipos
                        Text(l10n.filterTypes,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allTypeObjects.map((tipoObj) {
                            final isSelected = _types.contains(tipoObj.nombre);
                            return FilterChip(
                              label: Text(tipoObj.nombre),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _types.add(tipoObj.nombre);
                                  } else {
                                    _types.remove(tipoObj.nombre);

                                    // LÓGICA DE LIMPIEZA:
                                    // 1. Calcular qué tipos quedan seleccionados.
                                    final remainingTypeObjects = allTypeObjects
                                        .where((t) => _types.contains(t.nombre))
                                        .toList();

                                    // 2. Obtener la lista de todos los géneros válidos para esos tipos restantes.
                                    final validGenres = remainingTypeObjects
                                        .expand((t) =>
                                            t.validGenres.map((g) => g.nombre))
                                        .toSet();

                                    // 3. Eliminar de _genres cualquier género que ya no sea válido.
                                    _genres.removeWhere(
                                        (g) => !validGenres.contains(g));
                                  }
                                });
                              }, // Close onSelected
                            ); // Close FilterChip
                          }).toList(), // Close map
                        ), // Close Wrap
                        const SizedBox(height: 24),

                        // 3. Sección Géneros
                        Text(l10n.filterGenres,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        GenreSelectorWidget(
                          selectedTypes: selectedTypeObjects,
                          initialGenres: _genres,
                          onChanged: (newGenres) {
                            setState(() {
                              _genres = newGenres;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Botón Aplicar Fijo
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: () {
                  widget.onApply(_types, _genres);
                  Navigator.pop(context);
                },
                child: Text(l10n.actionApplyFilters),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required String mode,
    required IconData defaultIcon,
  }) {
    final bool isSelected = _localSortMode == mode;

    // Icono dinámico: Flecha si está seleccionado, Icono por defecto si no
    IconData icon;
    if (isSelected) {
      icon = _localAscending ? Icons.arrow_upward : Icons.arrow_downward;
    } else {
      icon = defaultIcon;
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      showCheckmark: false, // No mostrar el tick
      onSelected: (_) {
        setState(() {
          if (_localSortMode == mode) {
            _localAscending = !_localAscending;
          } else {
            _localSortMode = mode;
            _localAscending =
                mode == 'DATE' ? false : true; // Valores por defecto
          }
        });

        widget.onSortChanged(_localSortMode, _localAscending);
      },
    );
  }
}
