// lib/src/features/elemento/elemento_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart'; // NUEVO
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart'; // NUEVO

/// Pantalla de Ficha de Detalle (RF10, RF11, RF12, y ahora RF05).
class ElementoDetailScreen extends StatefulWidget {
  final int elementoId;
  
  const ElementoDetailScreen({
    super.key,
    required this.elementoId,
  });

  @override
  State<ElementoDetailScreen> createState() => _ElementoDetailScreenState();
}

class _ElementoDetailScreenState extends State<ElementoDetailScreen> {
  // --- Servicios ---
  final ElementoService _elementoService = ElementoService();
  final CatalogService _catalogService = CatalogService(); // NUEVO

  // REFACTORIZADO: Este Future ahora cargará AMBAS cosas:
  // 1. Los detalles del elemento (Elemento)
  // 2. La lista del catálogo del usuario (List<CatalogoEntrada>)
  late Future<Map<String, dynamic>> _screenDataFuture; 

  // --- Estado de la UI ---
  // NUEVO: Estado para saber si el elemento ya está en el catálogo
  bool _isInCatalog = false;
  // NUEVO: Estado de carga para el botón "Añadir"
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // 1. Llama al nuevo método que carga todos los datos necesarios
    _loadScreenData();
  }

  /// NUEVO: Método que carga los datos del elemento Y el catálogo del usuario
  /// al mismo tiempo usando Future.wait (más eficiente).
  void _loadScreenData() {
    _screenDataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      // Pide ambos grupos de datos en paralelo
      final results = await Future.wait([
        _elementoService.getElementoById(widget.elementoId),
        _catalogService.getMyCatalog(),
      ]);

      // Parsea los resultados
      final Elemento elemento = results[0] as Elemento;
      final List<CatalogoEntrada> catalogo = results[1] as List<CatalogoEntrada>;

      // Comprueba si el elemento actual (widget.elementoId)
      // ya existe en la lista del catálogo del usuario.
      final bool inCatalog = catalogo.any(
        (entrada) => entrada.elementoId == widget.elementoId
      );
      
      // Actualiza el estado de la UI ANTES de construir el widget
      // (usamos 'mounted' por seguridad)
      if (mounted) {
        setState(() {
          _isInCatalog = inCatalog;
        });
      }
      
      // Devuelve los datos al FutureBuilder
      return {
        'elemento': elemento,
      };
    } catch (e) {
      // Si algo falla (ej. el token expira), lanza el error
      rethrow;
    }
  }

  /// NUEVO: Lógica para el botón "Añadir al Catálogo" (RF05)
  Future<void> _handleAddElemento() async {
    setState(() {
      _isAdding = true; // Muestra el spinner en el botón
    });

    final msgContext = ScaffoldMessenger.of(context);

    try {
      // 1. Llama al servicio (que devuelve la nueva entrada)
      await _catalogService.addElementoAlCatalogo(widget.elementoId);

      // 2. (ÉXITO) Actualiza la UI
      if (!mounted) return;
      setState(() {
        _isAdding = false;
        _isInCatalog = true; // El elemento YA está en el catálogo
      });
      
      msgContext.showSnackBar(
        const SnackBar(content: Text('¡Añadido al catálogo!'), backgroundColor: Colors.green),
      );

    } catch (e) {
      // 3. (ERROR)
      if (!mounted) return;
      setState(() {
        _isAdding = false;
      });
      
      // Muestra el error (ej. "Ya está en tu catálogo" (409))
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REFACTORIZADO: El FutureBuilder ahora espera un Map
      body: FutureBuilder<Map<String, dynamic>>(
        future: _screenDataFuture,
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el elemento:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          
          // REFACTORIZADO: Extrae el elemento del Map
          final Elemento elemento = snapshot.data!['elemento'];
          
          return CustomScrollView(
            slivers: <Widget>[
              // --- Cabecera con Imagen ---
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    elemento.titulo,
                    style: const TextStyle(shadows: [Shadow(blurRadius: 10)]),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ... (Código de la imagen de fondo sin cambios) ...
                      if (elemento.imagenPortadaUrl != null)
                        Image.network(
                          elemento.imagenPortadaUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey[800]);
                          },
                        )
                      else
                        Container(color: Colors.grey[800]),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 16,
                        child: _buildEstadoChip(elemento.estadoContenido),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- Cuerpo de la Página (Detalles) ---
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Tipo y Géneros ---
                          Text(
                            '${elemento.tipo} | ${elemento.generos.join(", ")}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          // --- Botón de Añadir (RF05) ---
                          // REFACTORIZADO: Ahora es dinámico
                          _buildAddButton(),
                          
                          const SizedBox(height: 24),

                          // --- Sinopsis (RF10) ---
                          Text(
                            'Sinopsis',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            elemento.descripcion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // --- Reseñas (RF12) ---
                          Text(
                            'Reseñas',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          // ... (TODO: Lógica de Reseñas) ...
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Las reseñas irán aquí.'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// (RF11) Widget auxiliar para el chip
  Widget _buildEstadoChip(String estado) {
    // ... (código del chip sin cambios)
    final bool isOficial = estado == "OFICIAL"; 
    return Chip(
      label: Text(
        isOficial ? "OFICIAL" : "COMUNITARIO",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isOficial ? Colors.blue[600] : Colors.grey[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  /// NUEVO: Widget auxiliar que construye el botón de "Añadir" (RF05)
  /// de forma dinámica, basado en el estado.
  Widget _buildAddButton() {
    // Caso 1: El elemento YA está en el catálogo
    if (_isInCatalog) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check, color: Colors.grey),
        label: const Text('Añadido al catálogo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.grey[400],
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: null, // Botón deshabilitado
      );
    }
    
    // Caso 2: El elemento NO está, y estamos en proceso de añadirlo
    if (_isAdding) {
      return ElevatedButton.icon(
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        label: const Text('Añadiendo...'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: null, // Deshabilitado mientras carga
      );
    }

    // Caso 3: El elemento NO está en el catálogo (listo para añadir)
    return ElevatedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Añadir a Mi Catálogo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _handleAddElemento, // Conecta la lógica
    );
  }
}