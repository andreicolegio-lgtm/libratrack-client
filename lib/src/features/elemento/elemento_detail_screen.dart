import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart'; // Import del servicio de catálogo
import 'package:libratrack_client/src/features/catalog/catalog_screen.dart'; // Import de la pantalla de catálogo

/// Pantalla que muestra la ficha detallada de un elemento (Mockup 6).
/// Implementa los requisitos RF10, RF11, RF12 y RF05.
class ElementoDetailScreen extends StatefulWidget {
  // Parámetro requerido para construir la pantalla
  final int elementoId;

  const ElementoDetailScreen({super.key, required this.elementoId});

  @override
  State<ElementoDetailScreen> createState() => _ElementoDetailScreenState();
}

class _ElementoDetailScreenState extends State<ElementoDetailScreen> {
  // --- Servicios ---
  final ElementoService _elementoService = ElementoService();
  final CatalogService _catalogService = CatalogService(); // Servicio para RF05
  
  // --- Estado ---
  Future<Map<String, dynamic>>? _detalleFuture;
  bool _isLoading = false; // Estado de carga para el botón "Añadir"

  @override
  void initState() {
    super.initState();
    // 1. Carga los detalles del elemento al iniciar la pantalla
    _loadDetalle();
  }

  /// Carga los datos de la API para este elemento (RF10)
  void _loadDetalle() {
    setState(() {
      _detalleFuture = _elementoService.getElementoById(widget.elementoId);
    });
  }

  /// Lógica para añadir el elemento al catálogo personal (RF05).
  Future<void> _handleAddToCatalog() async {
    // 1. Mostrar la rueda de carga en el botón
    setState(() {
      _isLoading = true;
    });

    // 2. (Mejor Práctica) Guardar 'context' en variables locales
    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context);

    try {
      // 3. Llamar al servicio de catálogo
      await _catalogService.addElementoAlCatalogo(widget.elementoId);
      
      // 4. (Éxito) Mostrar SnackBar verde
      msgContext.showSnackBar(
        const SnackBar(
          content: Text('¡Elemento añadido a tu catálogo!'),
          backgroundColor: Colors.green,
        ),
      );

      // (Opcional) Navegar al catálogo del usuario después de añadir
      // navContext.pop(); // Vuelve a la pantalla de búsqueda
      // O navegar a la pestaña de catálogo (más complejo, lo dejamos para después)

    } catch (e) {
      // 5. (Error) Mostrar SnackBar rojo
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 6. Ocultar la rueda de carga (tanto si hay éxito como si hay error)
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Elemento'),
      ),
      // 2. Usamos FutureBuilder para manejar los estados de la carga
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detalleFuture,
        builder: (context, snapshot) {
          
          /// Caso 1: Aún estamos cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// Caso 2: Hubo un error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          /// Caso 3: ¡Éxito! Tenemos los datos
          if (snapshot.hasData) {
            final elemento = snapshot.data!;
            // Extraemos los datos del DTO (ElementoResponseDTO)
            final String titulo = elemento['titulo'] ?? 'N/A';
            final String descripcion = elemento['descripcion'] ?? 'Sin sinopsis.';
            final String estadoContenido = elemento['estadoContenido'] ?? 'COMUNITARIO'; // RF11
            final String tipo = elemento['tipo'] ?? 'N/A';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Etiqueta de estado (RF11)
                  Chip(
                    label: Text(
                      estadoContenido,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: estadoContenido == 'OFICIAL' ? Colors.green[800] : Colors.blueGrey[700],
                  ),
                  const SizedBox(height: 8),

                  // 4. Título y Tipo (RF10)
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text('Tipo: $tipo', style: TextStyle(color: Colors.grey[400])),
                  
                  const Divider(height: 32),

                  // 5. Sinopsis (RF10)
                  const Text('Sinopsis:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(descripcion),
                  
                  const Divider(height: 32),

                  // 6. Botón Añadir al Catálogo (RF05)
                  ElevatedButton.icon(
                    // Llama al método _handleAddToCatalog
                    // Se deshabilita si _isLoading es true
                    onPressed: _isLoading ? null : _handleAddToCatalog,
                    icon: _isLoading 
                        ? Container() // Sin icono si está cargando
                        : const Icon(Icons.add),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white) // Rueda de carga
                        : const Text('Añadir a Mi Catálogo'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.blue[700],
                    ),
                  ),

                  // 7. Sección de Reseñas (RF12)
                  const SizedBox(height: 32),
                  const Text('Reseñas de la Comunidad (RF12)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // TO DO: Aquí iría la lista de reseñas y el botón 'Escribir Reseña'
                  
                ],
              ),
            );
          }

          /// Caso 4: Caso por defecto (no debería pasar)
          return const Center(child: Text('Datos no disponibles.'));
        },
      ),
    );
  }
}