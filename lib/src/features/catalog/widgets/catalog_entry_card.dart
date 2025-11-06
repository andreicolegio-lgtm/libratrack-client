// lib/src/features/catalog/widgets/catalog_entry_card.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/estado_personal.dart';

/// Tarjeta de Catálogo Refactorizada (Mejora UX - RF06/RF07).
///
/// Este widget es Stateful para manejar la edición rápida (TextField) y
/// el estado de carga (Spinner) internamente, sin afectar la lista principal.
class CatalogEntryCard extends StatefulWidget {
  final CatalogoEntrada entrada;
  final VoidCallback onUpdate; // Callback para recargar la lista si es necesario

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
  
  // Estado local que se inicializa con la entrada.
  late CatalogoEntrada _entrada;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // 1. Inicializa la entrada y el controlador de progreso
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
    // Solo actualiza si hay un estado o si el texto ha cambiado
    if (nuevoEstado == null && _progresoController.text == (_entrada.progresoEspecifico ?? '')) {
      return;
    }

    setState(() { _isLoading = true; });
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // 1. Llama al servicio de actualización
      final CatalogoEntrada entradaActualizada =
          await _catalogService.updateElementoDelCatalogo(
        _entrada.elementoId,
        estado: nuevoEstado ?? _entrada.estadoPersonal,
        progreso: _progresoController.text,
      );

      // 2. (ÉXITO) Actualiza el estado local y la UI
      if (mounted) {
        // La lista principal se actualizará si el estado cambió de pestaña
        widget.onUpdate(); 
        
        setState(() {
          _entrada = entradaActualizada; // Reemplaza la entrada antigua con la nueva
          _isLoading = false;
        });

        // Feedback al usuario
        msgContext.showSnackBar(
          const SnackBar(content: Text('Progreso guardado.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // 3. (ERROR)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        msgContext.showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper para determinar el valor de la barra de progreso
  double get _progresoValue {
    if (_entrada.estadoPersonal == EstadoPersonal.TERMINADO.apiValue) {
      return 1.0;
    } else if (_entrada.estadoPersonal == EstadoPersonal.EN_PROGRESO.apiValue && _progresoController.text.isNotEmpty) {
      return 0.5; // Simulado
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deshabilita la edición si la tarjeta está cargando
    final bool isEditable = !_isLoading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: InkWell(
        onTap: isEditable ? () {
          // TO DO: Navegar a ElementoDetailScreen(elementoId: _entrada.elementoId)
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Imagen de Portada (70x100)
              _buildImageContainer(),
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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Botón de Dropdown de Estado (RF06)
                        _buildEstadoDropdown(isEditable),
                      ],
                    ),
                    
                    // --- Barra de Progreso ---
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progresoValue,
                      backgroundColor: Colors.grey[700],
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 4),

                    // --- Campo de Edición Rápida (RF07) ---
                    _buildProgresoField(isEditable),

                    // --- Estado Personal de Lectura ---
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        EstadoPersonal.fromString(_entrada.estadoPersonal).displayName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
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

  Widget _buildImageContainer() {
    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey[800],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: _entrada.elementoImagenPortadaUrl.isNotEmpty
            ? Image.network(
                _entrada.elementoImagenPortadaUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, color: Colors.blueGrey),
              )
            : const Icon(Icons.image, size: 40, color: Colors.blueGrey),
      ),
    );
  }

  /// NUEVO: Campo de texto para edición rápida del progreso (RF07)
  Widget _buildProgresoField(bool isEditable) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _progresoController,
            enabled: isEditable,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Progreso (Ej. T2:E5)',
              hintStyle: TextStyle(color: Colors.grey[600]),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              border: InputBorder.none,
              // Spinner de carga justo al lado del texto
              suffixIcon: _isLoading 
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            ),
            // Acción clave: al soltar el foco (teclado), se guarda.
            onEditingComplete: () => _handleUpdate(),
            textInputAction: TextInputAction.done,
          ),
        ),
        // Botón de guardar (opcional, si se prefiere un clic)
        if (isEditable && _progresoController.text != (_entrada.progresoEspecifico ?? ''))
          IconButton(
            icon: const Icon(Icons.save, color: Colors.blue),
            onPressed: () => _handleUpdate(),
          ),
      ],
    );
  }

  /// NUEVO: Dropdown simplificado de estado (RF06)
  Widget _buildEstadoDropdown(bool isEditable) {
    return DropdownButton<EstadoPersonal>(
      value: EstadoPersonal.fromString(_entrada.estadoPersonal),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
      underline: const SizedBox(), // Elimina la línea de abajo
      style: const TextStyle(color: Colors.white),
      dropdownColor: Colors.grey[850], // Mantiene el esquema oscuro
      onChanged: isEditable
          ? (EstadoPersonal? newValue) {
              if (newValue != null) {
                // Guarda inmediatamente con el nuevo estado
                _handleUpdate(nuevoEstado: newValue.apiValue); 
              }
            }
          : null, // Deshabilitado si no es editable
      items: EstadoPersonal.values.map((estado) {
        return DropdownMenuItem(
          value: estado,
          child: Text(estado.displayName, style: TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }
}