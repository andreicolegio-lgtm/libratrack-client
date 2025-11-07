// lib/src/features/catalog/widgets/catalog_entry_card.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/estado_personal.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart'; 
// --- NUEVA IMPORTACIÓN (Punto 2) ---
import 'package:libratrack_client/src/features/elemento/elemento_detail_screen.dart'; 

/// Tarjeta de Catálogo Refactorizada (Mejora UX - RF06/RF07).
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
  final CatalogService _catalogService = CatalogService();
  final TextEditingController _progresoController = TextEditingController();
  
  late CatalogoEntrada _entrada;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _entrada = widget.entrada;
    _progresoController.text = _entrada.progresoEspecifico ?? '';
  }

  @override
  void dispose() {
    _progresoController.dispose();
    super.dispose();
  }

  /// Lógica para actualizar el progreso o el estado (RF06/RF07)
  Future<void> _handleUpdate({String? nuevoEstado}) async {
    if (nuevoEstado == null && _progresoController.text == (_entrada.progresoEspecifico ?? '')) {
      return;
    }

    setState(() { _isLoading = true; });
    final msgContext = ScaffoldMessenger.of(context); // Guardamos el context

    try {
      final CatalogoEntrada entradaActualizada =
          await _catalogService.updateElementoDelCatalogo(
        _entrada.elementoId,
        estado: nuevoEstado ?? _entrada.estadoPersonal,
        progreso: _progresoController.text,
      );

      if (mounted) {
        widget.onUpdate(); 
        
        setState(() {
          _entrada = entradaActualizada; 
          _isLoading = false;
        });

        // Usa el helper
        SnackBarHelper.showTopSnackBar(
          msgContext, 
          'Progreso guardado.', 
          isError: false
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Usa el helper
        SnackBarHelper.showTopSnackBar(
          msgContext, 
          'Error al actualizar: ${e.toString().replaceFirst("Exception: ", "")}', 
          isError: true
        );
      }
    }
  }

  double get _progresoValue {
    if (_entrada.estadoPersonal == EstadoPersonal.TERMINADO.apiValue) {
      return 1.0;
    } else if (_entrada.estadoPersonal == EstadoPersonal.EN_PROGRESO.apiValue && _progresoController.text.isNotEmpty) {
      return 0.5;
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditable = !_isLoading;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color fadedIconColor = onSurfaceColor.withAlpha(0x80); 

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface, 
      child: InkWell(
        // --- CORRECCIÓN (Punto 2) ---
        // Al hacer clic en la tarjeta, navega a la Ficha de Detalle (RF10)
        onTap: isEditable ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ElementoDetailScreen(elementoId: _entrada.elementoId),
            ),
          ).then((_) => widget.onUpdate()); // Recarga la lista al volver (por si se borró)
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Imagen de Portada
              _buildImageContainer(fadedIconColor),
              const SizedBox(width: 16),
              
              // 2. Contenido Principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Fila 1: Título y Botón de Estado ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _entrada.elementoTitulo,
                            style: Theme.of(context).textTheme.titleMedium, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Botón de Dropdown de Estado (RF06)
                        _buildEstadoDropdown(context, isEditable),
                      ],
                    ),
                    
                    // --- Barra de Progreso ---
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progresoValue,
                      backgroundColor: Colors.grey[700],
                      color: Theme.of(context).colorScheme.primary, 
                    ),
                    const SizedBox(height: 4),

                    // --- Campo de Edición Rápida (RF07) ---
                    _buildProgresoField(context, isEditable),

                    // --- Estado Personal de Lectura ---
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        EstadoPersonal.fromString(_entrada.estadoPersonal).displayName,
                        style: Theme.of(context).textTheme.bodyMedium, 
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildImageContainer(Color fadedIconColor) {
    final String? imageUrl = _entrada.elementoImagenPortadaUrl;
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
            ? Image.network(
                imageUrl, // '!' eliminado
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.broken_image, color: fadedIconColor),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: Icon(Icons.downloading, color: fadedIconColor));
                },
              )
            : Icon(Icons.image, size: 40, color: fadedIconColor),
      ),
    );
  }

  /// Campo de texto para edición rápida del progreso (RF07)
  Widget _buildProgresoField(BuildContext context, bool isEditable) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _progresoController,
            enabled: isEditable,
            style: Theme.of(context).textTheme.bodyMedium, 
            decoration: InputDecoration(
              hintText: 'Progreso (Ej. T2:E5)',
              hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14), 
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              border: InputBorder.none,
              suffixIcon: _isLoading 
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            ),
            onEditingComplete: () => _handleUpdate(),
            textInputAction: TextInputAction.done,
          ),
        ),
        if (isEditable && _progresoController.text != (_entrada.progresoEspecifico ?? ''))
          IconButton(
            icon: Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _handleUpdate(),
          ),
      ],
    );
  }

  /// Dropdown simplificado de estado (RF06)
  Widget _buildEstadoDropdown(BuildContext context, bool isEditable) {
    return DropdownButton<EstadoPersonal>(
      value: EstadoPersonal.fromString(_entrada.estadoPersonal),
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
      underline: const SizedBox(),
      style: Theme.of(context).textTheme.titleMedium, 
      dropdownColor: Theme.of(context).colorScheme.surface, 
      onChanged: isEditable
          ? (EstadoPersonal? newValue) {
              if (newValue != null) {
                _handleUpdate(nuevoEstado: newValue.apiValue); 
              }
            }
          : null,
      items: EstadoPersonal.values.map((estado) {
        return DropdownMenuItem(
          value: estado,
          child: Text(estado.displayName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
        );
      }).toList(),
    );
  }
}