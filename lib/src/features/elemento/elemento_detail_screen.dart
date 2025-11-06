// lib/src/features/elemento/elemento_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/core/services/resena_service.dart'; // NUEVO
import 'package:libratrack_client/src/core/services/user_service.dart'; // NUEVO
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/resena.dart'; // NUEVO
import 'package:libratrack_client/src/model/perfil_usuario.dart'; // NUEVO
import 'package:libratrack_client/src/features/elemento/widgets/resena_form_modal.dart'; // NUEVO
import 'package:libratrack_client/src/features/elemento/widgets/resena_card.dart'; // NUEVO


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
  final CatalogService _catalogService = CatalogService();
  final ResenaService _resenaService = ResenaService(); // NUEVO
  final UserService _userService = UserService(); // NUEVO

  // REFACTORIZADO: Este Future ahora carga 4 grupos de datos
  late Future<Map<String, dynamic>> _screenDataFuture; 

  // --- Estado de la UI ---
  bool _isInCatalog = false;
  bool _isAdding = false;
  
  // --- NUEVO: Estado para Reseñas (RF12) ---
  List<Resena> _resenas = [];
  bool _haResenado = false; // El usuario actual ya ha reseñado esto
  String? _usernameActual; // Nombre del usuario logueado

  @override
  void initState() {
    super.initState();
    _loadScreenData();
  }

  /// REFACTORIZADO: Carga todos los datos de la pantalla en paralelo
  void _loadScreenData() {
    _screenDataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      // Pide 4 grupos de datos en paralelo
      final results = await Future.wait([
        _elementoService.getElementoById(widget.elementoId), // [0]
        _catalogService.getMyCatalog(),                     // [1]
        _resenaService.getResenas(widget.elementoId),       // [2] NUEVO
        _userService.getMiPerfil(),                         // [3] NUEVO
      ]);

      // Parsea los resultados
      final Elemento elemento = results[0] as Elemento;
      final List<CatalogoEntrada> catalogo = results[1] as List<CatalogoEntrada>;
      final List<Resena> resenas = results[2] as List<Resena>;
      final PerfilUsuario perfil = results[3] as PerfilUsuario;

      // Comprueba el estado del catálogo (RF05)
      final bool inCatalog = catalogo.any(
        (entrada) => entrada.elementoId == widget.elementoId
      );
      
      // NUEVO: Comprueba el estado de las reseñas (RF12)
      // Guarda el username para futuras comprobaciones
      _usernameActual = perfil.username; 
      // Comprueba si alguna reseña en la lista fue escrita por el usuario actual
      final bool haResenado = resenas.any(
        (resena) => resena.usernameAutor == _usernameActual
      );
      
      // Actualiza el estado de la UI
      if (mounted) {
        setState(() {
          _isInCatalog = inCatalog;
          _resenas = resenas; // Guarda la lista de reseñas
          _haResenado = haResenado; // Guarda si ya ha reseñado
        });
      }
      
      // Devuelve solo los datos que el FutureBuilder necesita (el elemento)
      return { 'elemento': elemento };
    } catch (e) {
      rethrow;
    }
  }

  /// Lógica para "Añadir al Catálogo" (RF05)
  Future<void> _handleAddElemento() async {
    // ... (código existente sin cambios)
    setState(() { _isAdding = true; });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      await _catalogService.addElementoAlCatalogo(widget.elementoId);
      if (!mounted) return;
      setState(() {
        _isAdding = false;
        _isInCatalog = true;
      });
      msgContext.showSnackBar(
        const SnackBar(content: Text('¡Añadido al catálogo!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isAdding = false; });
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// --- NUEVO MÉTODO (RF12) ---
  /// Abre el modal para escribir una nueva reseña
  Future<void> _openWriteReviewModal() async {
    final resultado = await showModalBottomSheet<Resena>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return ResenaFormModal(elementoId: widget.elementoId);
      },
    );

    // (Actualización instantánea)
    // Si el modal se cerró con éxito, 'resultado' será la nueva reseña
    if (resultado != null) {
      setState(() {
        // Añade la nueva reseña al principio de la lista
        _resenas.insert(0, resultado);
        // Deshabilita el botón "Escribir Reseña"
        _haResenado = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _screenDataFuture,
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center( /* ... (código de error sin cambios) ... */
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
          
          final Elemento elemento = snapshot.data!['elemento'];
          
          return CustomScrollView(
            slivers: <Widget>[
              // --- Cabecera con Imagen ---
              SliverAppBar(
                // ... (código de SliverAppBar sin cambios) ...
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
                          
                          // --- REFACTORIZADO: Sección de Reseñas (RF12) ---
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reseñas (${_resenas.length})',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              // NUEVO: Botón para escribir reseña
                              _buildWriteReviewButton(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // NUEVO: Lista de reseñas
                          _buildReviewList(),
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
  
  // --- Helpers de UI (RF05, RF11, RF12) ---

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

  Widget _buildAddButton() {
    // ... (código del botón "Añadir" sin cambios)
    if (_isInCatalog) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check, color: Colors.grey),
        label: const Text('Añadido al catálogo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.grey[400],
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: null,
      );
    }
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
        onPressed: null,
      );
    }
    return ElevatedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Añadir a Mi Catálogo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _handleAddElemento,
    );
  }
  
  /// NUEVO: Construye el botón de "Escribir Reseña" (RF12)
  Widget _buildWriteReviewButton() {
    // Si el usuario ya ha reseñado, muestra un botón deshabilitado
    if (_haResenado) {
      return const TextButton(
        onPressed: null,
        child: Text('Ya has reseñado', style: TextStyle(color: Colors.grey)),
      );
    }
    // Si no, muestra el botón para abrir el modal
    return TextButton.icon(
      icon: const Icon(Icons.edit, size: 16),
      label: const Text('Escribir Reseña'),
      style: TextButton.styleFrom(foregroundColor: Colors.blue[300]),
      onPressed: _openWriteReviewModal,
    );
  }
  
  /// NUEVO: Construye la lista de reseñas (RF12)
  Widget _buildReviewList() {
    // Si la lista que cargamos está vacía
    if (_resenas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aún no hay reseñas para este elemento.'),
        ),
      );
    }
    // Si hay reseñas, las muestra usando el ResenaCard
    return ListView.builder(
      itemCount: _resenas.length,
      shrinkWrap: true, // Importante dentro de un SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll
      itemBuilder: (context, index) {
        return ResenaCard(resena: _resenas[index]);
      },
    );
  }
}