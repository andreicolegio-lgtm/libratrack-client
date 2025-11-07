// lib/src/features/elemento/elemento_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/core/services/resena_service.dart';
import 'package:libratrack_client/src/core/services/user_service.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/resena.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';
import 'package:libratrack_client/src/features/elemento/widgets/resena_form_modal.dart';
import 'package:libratrack_client/src/features/elemento/widgets/resena_card.dart';


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
  final ResenaService _resenaService = ResenaService();
  final UserService _userService = UserService();

  late Future<Map<String, dynamic>> _screenDataFuture; 

  // --- Estado de la UI ---
  bool _isInCatalog = false;
  bool _isAdding = false;
  
  List<Resena> _resenas = [];
  bool _haResenado = false; 
  String? _usernameActual; 

  @override
  void initState() {
    super.initState();
    _loadScreenData();
  }

  void _loadScreenData() {
    _screenDataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      // Pide 4 grupos de datos en paralelo
      final results = await Future.wait([
        _elementoService.getElementoById(widget.elementoId), // [0]
        _catalogService.getMyCatalog(),                     // [1]
        _resenaService.getResenas(widget.elementoId),       // [2]
        _userService.getMiPerfil(),                         // [3]
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
      
      // Comprueba el estado de las reseñas (RF12)
      _usernameActual = perfil.username; 
      final bool haResenado = resenas.any(
        (resena) => resena.usernameAutor == _usernameActual
      );
      
      if (mounted) {
        setState(() {
          _isInCatalog = inCatalog;
          _resenas = resenas;
          _haResenado = haResenado;
        });
      }
      
      return { 'elemento': elemento };
    } catch (e) {
      rethrow;
    }
  }

  /// Lógica para "Añadir al Catálogo" (RF05)
  Future<void> _handleAddElemento() async {
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

  /// Abre el modal para escribir una nueva reseña (RF12)
  Future<void> _openWriteReviewModal() async {
    final resultado = await showModalBottomSheet<Resena>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return ResenaFormModal(elementoId: widget.elementoId);
      },
    );

    if (resultado != null) {
      setState(() {
        // Añade la nueva reseña al principio de la lista
        _resenas.insert(0, resultado);
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el elemento:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  // REFACTORIZADO: Usa bodyMedium del tema
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
            );
          }
          
          final Elemento elemento = snapshot.data!['elemento'];
          
          return CustomScrollView(
            slivers: <Widget>[
              // --- Cabecera con Imagen ---
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface, // Usa color de tema
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    elemento.titulo,
                    // REFACTORIZADO: Usa titleLarge con sombra
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(shadows: [const Shadow(blurRadius: 10)]),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // La imagen (si existe)
                      if (elemento.imagenPortadaUrl != null && elemento.imagenPortadaUrl!.isNotEmpty)
                        Image.network(
                          elemento.imagenPortadaUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Theme.of(context).colorScheme.surface);
                          },
                        )
                      else
                        Container(color: Theme.of(context).colorScheme.surface),
                      
                      // Gradiente oscuro para que el título sea legible
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
                      
                      // --- Chip "OFICIAL" (RF11) ---
                      Positioned(
                        top: 40,
                        right: 16,
                        child: _buildEstadoChip(context, elemento.estadoContenido),
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
                            // REFACTORIZADO: Usa bodyMedium
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            // REFACTORIZADO: Usa titleLarge
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            elemento.descripcion,
                            // REFACTORIZADO: Usa bodyMedium
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          
                          // --- Sección de Reseñas (RF12) ---
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reseñas (${_resenas.length})',
                                // REFACTORIZADO: Usa titleLarge
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              // Botón para escribir reseña
                              _buildWriteReviewButton(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Lista de reseñas
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
  
  // --- WIDGETS AUXILIARES (Refactorizados) ---
  
  Widget _buildEstadoChip(BuildContext context, String estado) {
    // REFACTORIZADO: Usa colores de tema
    final bool isOficial = estado == "OFICIAL"; 
    
    return Chip(
      label: Text(
        isOficial ? "OFICIAL" : "COMUNITARIO",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      backgroundColor: isOficial ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildAddButton() {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    
    if (_isInCatalog) {
      return ElevatedButton.icon(
        icon: Icon(Icons.check, color: Colors.grey[400]),
        label: const Text('Añadido al catálogo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
          backgroundColor: primaryColor,
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
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _handleAddElemento,
    );
  }
  
  Widget _buildWriteReviewButton() {
    if (_haResenado) {
      return const TextButton(
        onPressed: null,
        child: Text('Ya has reseñado', style: TextStyle(color: Colors.grey)),
      );
    }
    return TextButton.icon(
      icon: const Icon(Icons.edit, size: 16),
      label: const Text('Escribir Reseña'),
      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
      onPressed: _openWriteReviewModal,
    );
  }
  
  Widget _buildReviewList() {
    if (_resenas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Aún no hay reseñas para este elemento.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _resenas.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        // Usamos el ResenaCard que ya creamos (que debe ser consistente)
        return ResenaCard(resena: _resenas[index]);
      },
    );
  }
}