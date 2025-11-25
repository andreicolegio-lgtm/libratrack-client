import 'package:flutter/material.dart';
import '../utils/content_translator.dart';
import '../../model/tipo.dart';

class GenreSelectorWidget extends StatefulWidget {
  final List<Tipo> selectedTypes;
  final List<String> initialGenres;
  final Function(List<String>) onChanged;

  const GenreSelectorWidget({
    required this.selectedTypes,
    required this.initialGenres,
    required this.onChanged,
    super.key,
  });

  @override
  GenreSelectorWidgetState createState() => GenreSelectorWidgetState();
}

class GenreSelectorWidgetState extends State<GenreSelectorWidget> {
  late Set<String> _selectedGenres;
  late Set<String> _customGenres;

  @override
  void initState() {
    super.initState();
    final availableGenres = _computeAvailableGenres();
    _selectedGenres =
        widget.initialGenres.where((genre) => genre.isNotEmpty).toSet();

    // Derive custom genres without modifying selected genres
    _customGenres = _selectedGenres.difference(availableGenres);
  }

  Set<String> _computeAvailableGenres() {
    final validGenres = widget.selectedTypes
        .expand((tipo) => tipo.validGenres.map((genero) => genero.nombre))
        .toSet();
    return validGenres;
  }

  void _addCustomGenre(String genre) {
    setState(() {
      _selectedGenres.add(genre);
      _customGenres.add(genre);
    });
    widget.onChanged(_selectedGenres.toList());
  }

  @override
  Widget build(BuildContext context) {
    final availableGenres = _computeAvailableGenres();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        // Official Chips
        ...availableGenres.map((genre) {
          return FilterChip(
            label: Text(ContentTranslator.translateGenre(context, genre)),
            selected: _selectedGenres.contains(genre),
            onSelected: (isSelected) {
              setState(() {
                if (isSelected) {
                  _selectedGenres.add(genre);
                } else {
                  _selectedGenres.remove(genre);
                }
              });
              widget.onChanged(_selectedGenres.toList());
            },
          );
        }),

        // Custom Chips
        ..._customGenres.map((genre) {
          return InputChip(
            label: Text(genre),
            backgroundColor: Colors.orange,
            onDeleted: () {
              setState(() {
                _selectedGenres.remove(genre);
                _customGenres.remove(genre);
              });
              widget.onChanged(_selectedGenres.toList());
            },
          );
        }),

        // Add Button
        ActionChip(
          label: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 4),
              Text('Add Genre'),
            ],
          ),
          onPressed: () async {
            final newGenre = await _showAddGenreDialog(context);
            if (newGenre != null && newGenre.isNotEmpty) {
              _addCustomGenre(newGenre);
            }
          },
        ),
      ],
    );
  }

  Future<String?> _showAddGenreDialog(BuildContext context) async {
    String? newGenre;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Genre'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter genre name'),
            onChanged: (value) {
              newGenre = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(newGenre),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
