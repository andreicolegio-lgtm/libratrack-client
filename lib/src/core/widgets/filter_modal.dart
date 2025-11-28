import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/tipo_service.dart';
import '../../model/tipo.dart';
import 'genre_selector_widget.dart';

class FilterModal extends StatefulWidget {
  final List<String> selectedTypes;
  final List<String> selectedGenres;
  final void Function(List<String> types, List<String> genres) onApply;

  const FilterModal({
    required this.selectedTypes,
    required this.selectedGenres,
    required this.onApply,
    super.key,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late List<String> _types;
  late List<String> _genres;
  late Future<List<Tipo>> _tiposFuture;

  @override
  void initState() {
    super.initState();
    _types = List.from(widget.selectedTypes);
    _genres = List.from(widget.selectedGenres);

    // Cargamos los tipos reales desde el servicio al iniciar
    // Si ya están en caché, esto será instantáneo.
    _tiposFuture =
        context.read<TipoService>().fetchTipos('Error cargando filtros');
  }

  void _resetFilters() {
    setState(() {
      _types.clear();
      _genres.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // Cabecera
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Restablecer'),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Contenido con FutureBuilder para esperar los datos de tipos
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

                  // Lista completa de objetos Tipo disponibles
                  final allTypeObjects = snapshot.data ?? [];

                  // Calculamos los OBJETOS Tipo seleccionados para pasarlos al hijo
                  // Esto permite que GenreSelector sepa qué géneros mostrar
                  final selectedTypeObjects = allTypeObjects
                      .where((t) => _types.contains(t.nombre))
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección Tipos
                        const Text('Tipos',
                            style: TextStyle(
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
                                  }
                                  // Al cambiar el tipo, limpiamos géneros que ya no apliquen?
                                  // Por ahora lo mantenemos simple y dejamos la selección previa.
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Sección Géneros (Conectada dinámicamente)
                        const Text('Géneros',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),

                        GenreSelectorWidget(
                          // AHORA SÍ: Pasamos los objetos reales para que calcule los géneros válidos
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

            // Botón Aplicar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: () {
                  widget.onApply(_types, _genres);
                  Navigator.pop(context);
                },
                child: const Text('Aplicar Filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
