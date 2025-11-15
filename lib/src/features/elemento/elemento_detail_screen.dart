// Archivo: lib/src/features/elemento/elemento_detail_screen.dart
// (¡MODIFICADO POR GEMINI PARA MOSTRAR RELACIONES!)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; 
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/core/services/resena_service.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart'; 
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/resena.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';

// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:libratrack_client/src/model/elemento_relacion.dart'; 
// ---

import 'package:libratrack_client/src/features/elemento/widgets/resena_form_modal.dart';
import 'package:libratrack_client/src/features/elemento/widgets/resena_card.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/core/services/admin_service.dart';
import 'package:libratrack_client/src/features/admin/admin_elemento_form.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart'; 

/// --- ¡ACTUALIZADO (Sprint 10 / Relaciones)! ---
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
  
  // Servicios (inicializados en initState)
  late final ElementoService _elementoService;
  late final CatalogService _catalogService;
  late final ResenaService _resenaService;
  late final AdminService _adminService;
  late final AuthService _authService;

  // Futuro para el FutureBuilder
  late Future<Map<String, dynamic>> _screenDataFuture;

  // Estado de la UI
  bool _isInCatalog = false;
  bool _isAdding = false;
  bool _isDeleting = false;
  bool _isLoadingStatusChange = false;

  List<Resena> _resenas = [];
  bool _haResenado = false;
  String? _usernameActual;

  @override
  void initState() {
    super.initState();
    // Obtenemos todos los servicios necesarios desde Provider
    _elementoService = context.read<ElementoService>();
    _catalogService = context.read<CatalogService>();
    _resenaService = context.read<ResenaService>();
    _adminService = context.read<AdminService>();
    _authService = context.read<AuthService>();

    // Carga los datos del elemento inicial
    _loadScreenData();
  }

  // --- ¡NUEVO MÉTODO! (Añadido por Gemini) ---
  /// Se activa si esta pantalla ya está abierta y se navega a ella
  /// de nuevo, pero con un ID de elemento diferente (ej. al pulsar en una secuela).
  @override
  void didUpdateWidget(ElementoDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el ID del widget actual es diferente al del widget anterior...
    if (widget.elementoId != oldWidget.elementoId) {
      // ...vuelve a cargar los datos con el nuevo ID.
      _loadScreenData();
    }
  }
  // --- FIN DE MÉTODO AÑADIDO ---

  /// Carga (o recarga) todos los datos de la pantalla
  void _loadScreenData() {
    _screenDataFuture = _fetchData();
    if (mounted) {
      // Le decimos a Flutter que reconstruya el widget
      // usando el *nuevo* _screenDataFuture
      setState(() {});
    }
  }

  /// Método centralizado para todas las llamadas API
  Future<Map<String, dynamic>> _fetchData() async {
    try {
      // 1. Obtenemos el perfil y el catálogo primero
      final PerfilUsuario perfil = _authService.perfilUsuario!;
      _usernameActual = perfil.username;

      // El fetchCatalog actualiza el estado interno de catalogService
      await _catalogService.fetchCatalog();
      final List<CatalogoEntrada> catalogo = _catalogService.entradas;

      // 2. Buscamos el resto de datos en paralelo
      final results = await Future.wait([
        _elementoService.getElementoById(widget.elementoId),
        _resenaService.getResenas(widget.elementoId),
      ]);

      // 3. Procesamos los resultados
      final Elemento elemento = results[0] as Elemento;
      final List<Resena> resenas = results[1] as List<Resena>;

      final bool inCatalog =
          catalogo.any((entrada) => entrada.elementoId == widget.elementoId);

      final bool haResenado =
          resenas.any((resena) => resena.usernameAutor == _usernameActual);

      // Actualizamos el estado local (no es necesario un setState
      // porque el FutureBuilder se reconstruirá solo)
      _isInCatalog = inCatalog;
      _resenas = resenas;
      _haResenado = haResenado;

      return {'elemento': elemento, 'perfil': perfil};
    } on ApiException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // --- Lógica de Acciones (Añadir, Quitar, Reseñar, Admin) ---
  // (Sin cambios respecto a tu archivo, los mantenemos igual)

  Future<void> _handleAddElemento() async {
    setState(() {
      _isAdding = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      await _catalogService.addElemento(widget.elementoId);
      if (!mounted) return;
      setState(() {
        _isAdding = false;
        _isInCatalog = true;
      });
      SnackBarHelper.showTopSnackBar(
          msgContext, '¡Añadido al catálogo!', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAdding = false;
      });
      SnackBarHelper.showTopSnackBar(msgContext, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isAdding = false; });
      SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: $e', isError: true);
    }
  }

  Future<void> _handleRemoveElemento() async {
    setState(() {
      _isDeleting = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      await _catalogService.removeElemento(widget.elementoId);
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _isInCatalog = false;
      });
      SnackBarHelper.showTopSnackBar(
          msgContext, 'Elemento quitado del catálogo', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      SnackBarHelper.showTopSnackBar(msgContext, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isDeleting = false; });
      SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: $e', isError: true);
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

  Future<void> _handleToggleOficial(Elemento elemento) async {
    final bool esOficial = elemento.estadoContenido == 'OFICIAL';
    setState(() {
      _isLoadingStatusChange = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      await _adminService.toggleElementoOficial(
        elemento.id,
        !esOficial, // Invertimos la lógica
      );
      
      final successMessage = esOficial
          ? 'Elemento marcado como COMUNITARIO.'
          : '¡Elemento marcado como OFICIAL!';
      SnackBarHelper.showTopSnackBar(msgContext, successMessage, isError: false);

      if (!mounted) return;
      _loadScreenData(); // Recarga
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(msgContext, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatusChange = false;
        });
      }
    }
  }

  Future<void> _goToEditarElemento(Elemento elemento) async {
    if (_isAnyLoading()) return;
    final bool? seHaActualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminElementoFormScreen(elemento: elemento),
      ),
    );
    if (seHaActualizado == true && mounted) {
      _loadScreenData(); // Recarga
    }
  }

  bool _isAnyLoading() {
    return _isAdding || _isDeleting || _isLoadingStatusChange;
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // La AppBar se moverá al SliverAppBar
      body: FutureBuilder<Map<String, dynamic>>(
        future: _screenDataFuture, // Usa la variable de estado
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el elemento:\n${snapshot.error.toString()}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Elemento no encontrado.'));
          }

          final Elemento elemento = snapshot.data!['elemento'];
          final PerfilUsuario perfil = snapshot.data!['perfil'];

          // --- UI Principal (CustomScrollView) ---
          return CustomScrollView(
            slivers: <Widget>[
              // --- Cabecera con Imagen (SliverAppBar) ---
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding:
                      const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  title: Text(
                    elemento.titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        shadows: [const Shadow(blurRadius: 10)], fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (elemento.urlImagen != null &&
                          elemento.urlImagen!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: elemento.urlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Theme.of(context).colorScheme.surface),
                          errorWidget: (context, url, error) =>
                              Container(color: Theme.of(context).colorScheme.surface),
                        )
                      else
                        Container(color: Theme.of(context).colorScheme.surface),
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
                        child:
                            _buildEstadoChip(context, elemento.estadoContenido),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          const SizedBox(height: 24),

                          // --- Botones de Admin/Mod ---
                          _buildAdminButtons(context, perfil, elemento),

                          // --- Botón de Añadir / Quitar (RF05) ---
                          _buildAddOrRemoveButton(),
                          const SizedBox(height: 24),

                          // --- Sinopsis (RF10) ---
                          Text('Sinopsis',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(elemento.descripcion,
                              style: Theme.of(context).textTheme.bodyMedium),

                          // --- Detalles del Progreso (Petición 9) ---
                          _buildProgresoTotalInfo(elemento),
                          
                          // --- ¡NUEVAS SECCIONES DE RELACIONES! ---
                          
                          // --- Precuelas ---
                          _buildRelacionesSection(
                            context,
                            'Precuelas',
                            elemento.precuelas,
                          ),
                  
                          // --- Secuelas ---
                          _buildRelacionesSection(
                            context,
                            'Secuelas',
                            elemento.secuelas,
                          ),
                          // --- FIN DE SECCIONES AÑADIDAS ---

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
                              _buildWriteReviewButton(),
                            ],
                          ),
                          const SizedBox(height: 16),
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
  // (Sin cambios respecto a tu archivo, los mantenemos igual)

  List<int> _parseEpisodiosPorTemporada(String? data) {
    if (data == null || data.isEmpty) return [];
    try {
      return data.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildProgresoTotalInfo(Elemento elemento) {
    final tipo = elemento.tipo.toLowerCase();
    final List<Widget> infoWidgets = [];
    if (tipo == 'serie') {
      final epCounts =
          _parseEpisodiosPorTemporada(elemento.episodiosPorTemporada);
      final totalTemps = epCounts.length;
      if (totalTemps > 0) {
        infoWidgets.add(_buildInfoRow(
            context, Icons.movie_filter, 'Total Temporadas', '$totalTemps'));
        infoWidgets.add(
            _buildInfoRow(context, Icons.list_alt, 'Episodios', epCounts.join(', ')));
      }
    } else if (tipo == 'libro') {
      if (elemento.totalCapitulosLibro != null &&
          elemento.totalCapitulosLibro! > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.book_outlined,
            'Total Capítulos', '${elemento.totalCapitulosLibro}'));
      }
      if (elemento.totalPaginasLibro != null &&
          elemento.totalPaginasLibro! > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.pages_outlined,
            'Total Páginas', '${elemento.totalPaginasLibro}'));
      }
    } else if (tipo == 'anime' || tipo == 'manga') {
      if (elemento.totalUnidades != null && elemento.totalUnidades! > 0) {
        final label = tipo == 'anime' ? 'Total Episodios' : 'Total Capítulos';
        infoWidgets.add(
            _buildInfoRow(context, Icons.list, label, '${elemento.totalUnidades}'));
      }
    }
    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Divider(),
        ),
        Text('Detalles del Progreso',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...infoWidgets,
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Text('$label:',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey[300])),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(BuildContext context, String estado) {
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
        onPressed: _isAnyLoading() ? null : _handleRemoveElemento,
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
      onPressed: _isAnyLoading() ? null : _handleAddElemento,
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
      style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary),
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
        return ResenaCard(resena: _resenas[index]);
      },
    );
  }

  Widget _buildAdminButtons(
      BuildContext context, PerfilUsuario perfil, Elemento elemento) {
    if (!perfil.esModerador) {
      return const SizedBox.shrink();
    }
    final bool esOficial = elemento.estadoContenido == 'OFICIAL';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_note, size: 18),
              label: const Text('Editar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed:
                  _isAnyLoading() ? null : () => _goToEditarElemento(elemento),
            ),
          ),
          if (perfil.esAdministrador) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: _isLoadingStatusChange
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(esOficial ? Icons.public_off : Icons.verified,
                        size: 18),
                label: Text(_isLoadingStatusChange
                    ? '...'
                    : (esOficial ? 'Comunitarizar' : 'Oficializar')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: esOficial
                      ? Colors.grey[700]
                      : Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    _isAnyLoading() ? null : () => _handleToggleOficial(elemento),
              ),
            ),
          ]
        ],
      ),
    );
  }
  
  // --- ¡NUEVO WIDGET HELPER! (Añadido por Gemini) ---
  /// Construye una sección horizontal para Precuelas o Secuelas.
  Widget _buildRelacionesSection(
    BuildContext context,
    String titulo,
    List<ElementoRelacion> relaciones,
  ) {
    // Si la lista está vacía, no muestra nada
    if (relaciones.isEmpty) {
      return const SizedBox.shrink(); // No ocupa espacio
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
          child: Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        // Lista horizontal
        SizedBox(
          height: 190, // Altura fija para la lista (tarjeta + padding)
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relaciones.length,
            itemBuilder: (context, index) {
              final relacion = relaciones[index];
              // Llama a la tarjeta de relación
              return _RelacionCard(
                relacion: relacion,
                // --- ¡NAVEGACIÓN! ---
                // Al pulsar, navega a una *nueva* pantalla de detalle
                // pasando el ID de la precuela/secuela.
                onTap: () {
                  // Usamos 'push' para crear una nueva pantalla en la pila.
                  // 'didUpdateWidget' se encargará de recargar los datos.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ElementoDetailScreen(elementoId: relacion.id),
                    ),
                  // 'then' se ejecuta al volver a esta pantalla
                  ).then((_) => _loadScreenData());
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// --- ¡NUEVO WIDGET HELPER! (Añadido por Gemini) ---
/// Una tarjeta pequeña para mostrar en la lista de relaciones.
class _RelacionCard extends StatelessWidget {
  final ElementoRelacion relacion;
  final VoidCallback onTap;

  const _RelacionCard({
    required this.relacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, // Ancho fijo de la tarjeta
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0), // Espacio entre tarjetas
        child: InkWell(
          onTap: onTap, // Acción de navegación
          borderRadius: BorderRadius.circular(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Imagen de la tarjeta ---
              Card(
                clipBehavior: Clip.antiAlias, // Para redondear la imagen
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SizedBox(
                  height: 130,
                  width: 120,
                  child: (relacion.urlImagen != null &&
                          relacion.urlImagen!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: relacion.urlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey[400])),
                        )
                      // Placeholder si no hay imagen
                      : Container(
                          color: Colors.grey[800], // Color de fondo para tema oscuro
                          child: Center(
                            child: Icon(
                              Icons.movie, // O usa Icons.book
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // --- Título de la tarjeta ---
              Text(
                relacion.titulo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2, // Máximo 2 líneas
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}