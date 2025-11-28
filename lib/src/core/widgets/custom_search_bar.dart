import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterPressed;
  final String hintText;
  final VoidCallback? onChanged;

  const CustomSearchBar({
    required this.controller,
    required this.onFilterPressed,
    this.hintText = 'Buscar...',
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Campo de Texto Expandido
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged?.call(),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: Colors.grey), // Borde visible
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: Colors.grey), // Borde visible
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Botón de Filtros
        IconButton.filledTonal(
          onPressed: onFilterPressed,
          icon: const Icon(Icons.tune),
          tooltip: 'Filtros',
        ),
      ],
    );
  }
}
