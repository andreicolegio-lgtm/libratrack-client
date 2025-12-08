import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterPressed;
  final String? hintText;
  final VoidCallback? onChanged;

  const CustomSearchBar({
    required this.controller,
    this.onFilterPressed,
    this.hintText,
    this.onChanged,
    super.key,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Update state to show/hide the 'X' icon
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hint = widget.hintText ?? l10n.searchHintDefault;

    return Row(
      children: [
        // Campo de Texto Expandido
        Expanded(
          child: TextField(
            controller: widget.controller,
            onChanged: (_) => widget.onChanged?.call(),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged?.call();
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

        // Botón de Filtros (conditionally rendered)
        if (widget.onFilterPressed != null)
          IconButton.filledTonal(
            onPressed: widget.onFilterPressed,
            icon: const Icon(Icons.tune),
            tooltip: l10n.tooltipFilters,
          ),
      ],
    );
  }
}
