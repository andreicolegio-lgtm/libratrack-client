// lib/src/features/elemento/elemento_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
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
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';

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
  // ... (Servicios y estado sin cambios) ...
  final ElementoService _elementoService = ElementoService();
  final CatalogService _catalogService = CatalogService();
  final ResenaService _resenaService = ResenaService();
  final UserService _userService = UserService();

  late Future<Map<String, dynamic>> _screenDataFuture; 

  bool _isInCatalog = false;
  bool _isAdding = false;
  bool _isDeleting = false; 
  
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
      // (Manejo de 401/403 ya es global en ApiClient)
      rethrow;
    }
  }

  // ... (Lógica _handleAddElemento, _handleRemoveElemento, _openWriteReviewModal sin cambios) ...
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
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        '¡Añadido al catálogo!', 
        isError: false
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isAdding = false; });
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        e.toString().replaceFirst("Exception: ", ""),
        isError: true
      );
    }
  }

  Future<void> _handleRemoveElemento() async {
    setState(() { _isDeleting = true; });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      await _catalogService.removeElementoDelCatalogo(widget.elementoId);
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _isInCatalog = false; 
      });
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        'Elemento quitado del catálogo', 
        isError: false
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isDeleting = false; });
      SnackBarHelper.showTopSnackBar(
        msgContext, 
        e.toString().replaceFirst("Exception: ", ""),
        isError: true
      );
    }
  }

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
                  'Error al cargar el elemento:\n${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
            );
          }
          
          final Elemento elemento = snapshot.data!['elemento'];
          
          return CustomScrollView(
            slivers: <Widget>[
              // --- Cabecera con Imagen (SliverAppBar) ---
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface, 
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  title: Text(
                    elemento.titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(shadows: [const Shadow(blurRadius: 10)], fontSize: 20),
                    textAlign: TextAlign.center, 
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Usamos CachedNetworkImage
                      if (elemento.imagenPortadaUrl != null && elemento.imagenPortadaUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: elemento.imagenPortadaUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Theme.of(context).colorScheme.surface),
                          errorWidget: (context, url, error) => Container(color: Theme.of(context).colorScheme.surface),
                        )
                      else
                        Container(color: Theme.of(context).colorScheme.surface),
                      
                      // Gradiente oscuro
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
                      
                      // Chip "OFICIAL" / "COMUNITARIO"
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          // --- Botón de Añadir / Quitar (RF05) ---
                          _buildAddOrRemoveButton(),
                          
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
                          
                          // --- ¡NUEVO WIDGET! (Petición 9) ---
                          _buildProgresoTotalInfo(elemento),

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
  
  // --- WIDGETS AUXILIARES ---
  
  // --- ¡NUEVO HELPER! (Petición 9) ---
  /// Helper para parsear el string "10,8,12" a [10, 8, 12]
  List<int> _parseEpisodiosPorTemporada(String? data) {
    if (data == null || data.isEmpty) return [];
    try {
      return data.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    } catch (e) {
      return [];
    }
  }
  
  // --- ¡NUEVO WIDGET! (Petición 9) ---
  /// Construye la sección de "Detalles del Progreso"
  Widget _buildProgresoTotalInfo(Elemento elemento) {
    final tipo = elemento.tipo.toLowerCase();
    final List<Widget> infoWidgets = []; // Lista para guardar las filas de info

    // 1. Lógica para Series
    if (tipo == 'serie') {
      final epCounts = _parseEpisodiosPorTemporada(elemento.episodiosPorTemporada);
      final totalTemps = epCounts.length;
      if (totalTemps > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.movie_filter, 'Total Temporadas', '$totalTemps'));
        infoWidgets.add(_buildInfoRow(context, Icons.list_alt, 'Episodios', epCounts.join(', ')));
      }
    } 
    // 2. Lógica para Libros
    else if (tipo == 'libro') {
      if (elemento.totalCapitulosLibro != null && elemento.totalCapitulosLibro! > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.book_outlined, 'Total Capítulos', '${elemento.totalCapitulosLibro}'));
      }
      if (elemento.totalPaginasLibro != null && elemento.totalPaginasLibro! > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.pages_outlined, 'Total Páginas', '${elemento.totalPaginasLibro}'));
      }
    } 
    // 3. Lógica para Anime o Manga
    else if (tipo == 'anime' || tipo == 'manga') {
      if (elemento.totalUnidades != null && elemento.totalUnidades! > 0) {
        final label = tipo == 'anime' ? 'Total Episodios' : 'Total Capítulos';
        infoWidgets.add(_buildInfoRow(context, Icons.list, label, '${elemento.totalUnidades}'));
      }
    }

    // 4. Si no hay widgets (Película, Videojuego), no mostrar nada
    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink(); 
    }

    // 5. Construir el widget final
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Divider(),
        ),
        Text('Detalles del Progreso', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...infoWidgets, // Desplegar la lista de filas
      ],
    );
  }
  
  // --- ¡NUEVO WIDGET! (Petición 9) ---
  /// Helper para construir una fila de información (Icono - Label - Valor)
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Text(
            '$label:', 
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
          ),
          const SizedBox(width: 8),
          // Usamos Expanded para que el valor (ej. lista de episodios) pueda hacer wrap
          Expanded(
            child: Text(
              value, 
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[300])
            ),
          ),
        ],
      ),
    );
  }
  
  // --- (Resto de Widgets Auxiliares sin cambios) ---
  
  Widget _buildEstadoChip(BuildContext context, String estado) {
    // ... (código sin cambios)
    final bool isOficial = estado == "OFICIAL"; 
    final Color chipColor = isOficial 
        ? Theme.of(context).colorScheme.secondary 
        : Colors.grey[700]!; 
    return Chip(
      label: Text(
        isOficial ? "OFICIAL" : "COMUNITARIO",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildAddOrRemoveButton() {
    // ... (código sin cambios)
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    if (_isDeleting) {
      return ElevatedButton.icon(
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        label: const Text('Eliminando...'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: null,
      );
    }
    if (_isInCatalog) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Quitar del catálogo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Colors.red[300], 
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: _handleRemoveElemento,
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
    // ... (código sin cambios)
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
    // ... (código sin cambios)
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
        return ResenaCard(resena: _resenas[index]);
      },
    );
  }
}