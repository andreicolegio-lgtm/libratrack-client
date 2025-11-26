import 'package:flutter/material.dart';
import '../utils/content_translator.dart';
import '../../model/tipo.dart';

class GenreSelectorWidget extends StatefulWidget {
  /// Tipos seleccionados actualmente (para filtrar géneros sugeridos).
  final List<Tipo> selectedTypes;

  /// Lista inicial de nombres de géneros seleccionados.
  final List<String> initialGenres;

  /// Callback cuando cambia la selección.
  final Function(List<String>) onChanged;

  const GenreSelectorWidget({
    required this.selectedTypes,
    required this.initialGenres,
    required this.onChanged,
    super.key,
  });

  @override
  State<GenreSelectorWidget> createState() => _GenreSelectorWidgetState();
}

class _GenreSelectorWidgetState extends State<GenreSelectorWidget> {
  // Conjunto de todos los géneros seleccionados actualmente (Oficiales + Custom)
  late Set<String> _selectedGenres;

  // Conjunto para rastrear cuáles son custom (añadidos manualmente)
  late Set<String> _customGenres;

  @override
  void initState() {
    super.initState();
    final availableGenres = _computeAvailableGenres();

    // Inicializar selección con lo que venga del padre, limpiando vacíos
    _selectedGenres = widget.initialGenres.where((g) => g.isNotEmpty).toSet();

    // Detectar cuáles de los iniciales son custom (no están en la lista oficial del tipo)
    _customGenres = _selectedGenres.difference(availableGenres);
  }

  @override
  void didUpdateWidget(covariant GenreSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambian los tipos seleccionados, podríamos querer limpiar géneros inválidos,
    // pero por ahora mantenemos la selección del usuario por si acaso.
  }

  /// Calcula los géneros válidos basándose en los Tipos seleccionados.
  Set<String> _computeAvailableGenres() {
    return widget.selectedTypes
        .expand((tipo) => tipo.validGenres.map((g) => g.nombre))
        .toSet();
  }

  void _toggleGenre(String genre, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedGenres.add(genre);
      } else {
        _selectedGenres.remove(genre);
      }
    });
    widget.onChanged(_selectedGenres.toList());
  }

  void _addCustomGenre(String genre) {
    setState(() {
      _selectedGenres.add(genre);
      _customGenres.add(genre);
    });
    widget.onChanged(_selectedGenres.toList());
  }

  void _removeCustomGenre(String genre) {
    setState(() {
      _selectedGenres.remove(genre);
      _customGenres.remove(genre);
    });
    widget.onChanged(_selectedGenres.toList());
  }

  @override
  Widget build(BuildContext context) {
    final availableGenres = _computeAvailableGenres();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableGenres.isNotEmpty) ...[
          const Text('Sugeridos por Tipo:',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: availableGenres.map((genre) {
              final isSelected = _selectedGenres.contains(genre);
              return FilterChip(
                label: Text(ContentTranslator.translateGenre(context, genre)),
                selected: isSelected,
                onSelected: (v) => _toggleGenre(genre, v),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Seleccionados / Custom:',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Chips de selección actual (para ver qué tengo seleccionado de un vistazo)
            ..._selectedGenres.map((genre) {
              // Si es custom, lo mostramos diferente y permitimos borrar
              if (_customGenres.contains(genre) ||
                  !availableGenres.contains(genre)) {
                return InputChip(
                  label: Text(genre),
                  onDeleted: () => _removeCustomGenre(genre),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: TextStyle(color: Colors.orange.shade900),
                  deleteIconColor: Colors.orange.shade900,
                );
              }
              return const SizedBox
                  .shrink(); // Los oficiales ya se ven arriba marcados
            }),

            // Botón Añadir
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Otro'),
              onPressed: () async {
                final newGenre = await _showAddGenreDialog(context);
                if (newGenre != null && newGenre.trim().isNotEmpty) {
                  _addCustomGenre(newGenre.trim());
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<String?> _showAddGenreDialog(BuildContext context) async {
    String? newGenre;
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Añadir Género'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nombre del género'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (val) => newGenre = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, newGenre),
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }
}
