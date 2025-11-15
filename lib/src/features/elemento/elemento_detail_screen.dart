// Archivo: lib/src/features/elemento/elemento_detail_screen.dart
// (¡CORREGIDO Y REFACTORIZADO!)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/core/services/resena_service.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/resena.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';
import 'package:libratrack_client/src/features/elemento/widgets/resena_form_modal.dart';
import 'package:libratrack_client/src/features/elemento/widgets/resena_card.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/core/services/admin_service.dart';
import 'package:libratrack_client/src/features/admin/admin_elemento_form.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart'; // <-- ¡NUEVA IMPORTACIÓN!

/// --- ¡ACTUALIZADO (Sprint 6)! ---
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
  
  // --- ¡CORREGIDO (Errores 1-5)! ---
  // Se eliminan las instancias locales. Se declaran como 'late final'
  // para ser inicializadas en initState.
  late final ElementoService _elementoService;
  late final CatalogService _catalogService;
  late final ResenaService _resenaService;
  late final AdminService _adminService;
  late final AuthService _authService;
  // ---

  late Future<Map<String, dynamic>> _screenDataFuture;

  // --- Estado de la UI ---
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
    // --- ¡CORREGIDO (Errores 1-5)! ---
    // Obtenemos todos los servicios necesarios desde Provider.
    _elementoService = context.read<ElementoService>();
    _catalogService = context.read<CatalogService>();
    _resenaService = context.read<ResenaService>();
    _adminService = context.read<AdminService>();
    _authService = context.read<AuthService>();
    // ---

    _loadScreenData();
  }

  // Recarga todos los datos de la pantalla
  void _loadScreenData() {
    _screenDataFuture = _fetchData();
    if (mounted) {
      setState(() {});
    }
  }

  // --- ¡REFACTORIZADO (Errores 6, 7, 8, 9)! ---
  Future<Map<String, dynamic>> _fetchData() async {
    try {
      // 1. Obtenemos el perfil y el catálogo primero (uno es síncrono, el otro void)
      
      // (Corrección Error 9) Obtenemos el perfil desde AuthService (síncrono)
      final PerfilUsuario perfil = _authService.perfilUsuario!;
      _usernameActual = perfil.username;

      // (Corrección Error 7) Llamamos a fetchCatalog (es void)
      await _catalogService.fetchCatalog();
      // Leemos el resultado desde el getter del servicio
      final List<CatalogoEntrada> catalogo = _catalogService.entradas;

      // 2. Buscamos el resto de datos en paralelo
      final results = await Future.wait([
        // (Corrección Error 6) Pasamos el ID como String
        _elementoService.getElementoById(widget.elementoId),
        // (Corrección Error 8) Pasamos el ID como String
        _resenaService.getResenas(widget.elementoId),
      ]);

      // 3. Procesamos los resultados
      final Elemento elemento = results[0] as Elemento;
      final List<Resena> resenas = results[1] as List<Resena>;

      final bool inCatalog =
          catalogo.any((entrada) => entrada.elementoId == widget.elementoId);

      final bool haResenado =
          resenas.any((resena) => resena.usernameAutor == _usernameActual);

      if (mounted) {
        setState(() {
          _isInCatalog = inCatalog;
          _resenas = resenas;
          _haResenado = haResenado;
        });
      }
      return {'elemento': elemento, 'perfil': perfil};
    // --- ¡MEJORADO! ---
    } on ApiException {
      // Si el token expira (401), el AuthService se encargará del logout.
      // Solo relanzamos el error para el FutureBuilder.
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // --- Lógica de Acciones ---

  Future<void> _handleAddElemento() async {
    setState(() {
      _isAdding = true;
    });
    final msgContext = ScaffoldMessenger.of(context);
    try {
      // --- ¡CORREGIDO (Error 10)! ---
      // Se llama a 'addElemento' y se pasa el ID como String
      await _catalogService.addElemento(widget.elementoId);
      // ---

      if (!mounted) return;
      setState(() {
        _isAdding = false;
        _isInCatalog = true;
      });
      SnackBarHelper.showTopSnackBar(
          msgContext, '¡Añadido al catálogo!', isError: false);
    // --- ¡MEJORADO! ---
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
      // --- ¡CORREGIDO (Error 11)! ---
      // Se llama a 'removeElemento' y se pasa el ID como String
      await _catalogService.removeElemento(widget.elementoId);
      // ---

      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _isInCatalog = false;
      });
      SnackBarHelper.showTopSnackBar(
          msgContext, 'Elemento quitado del catálogo', isError: false);
    // --- ¡MEJORADO! ---
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

  // --- ¡MÉTODO UNIFICADO! (Petición 17 y F) ---
  Future<void> _handleToggleOficial(Elemento elemento) async {
    // Determinamos qué acción tomar
    final bool esOficial = elemento.estadoContenido == 'OFICIAL';

    setState(() {
      _isLoadingStatusChange = true;
    });
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // --- ¡CORREGIDO (Errores 12 y 13)! ---
      // Se llama al método unificado 'toggleElementoOficial'.
      // Se pasa 'false' para "Comunitarizar" (si era oficial)
      // Se pasa 'true' para "Oficializar" (si no lo era)
      await _adminService.toggleElementoOficial(
        elemento.id,
        !esOficial, // Invertimos la lógica
      );
      // ---
      
      final successMessage = esOficial
          ? 'Elemento marcado como COMUNITARIO.'
          : '¡Elemento marcado como OFICIAL!';
      SnackBarHelper.showTopSnackBar(msgContext, successMessage, isError: false);


      if (!mounted) return;
      // Recarga todos los datos de la pantalla (para actualizar el tag y el botón)
      _loadScreenData();
    // --- ¡MEJORADO! ---
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(msgContext, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(msgContext, 'Error inesperado: $e', isError: true);
    } finally {
      if (mounted) {
        // Aseguramos que el spinner se oculte
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
      _loadScreenData();
    }
  }

  bool _isAnyLoading() {
    return _isAdding || _isDeleting || _isLoadingStatusChange; // <-- ¡ACTUALIZADO!
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
                  // --- ¡MEJORADO! ---
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

          final Elemento elemento = snapshot.data!['elemento'];
          final PerfilUsuario perfil = snapshot.data!['perfil'];

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

  // (Este código es el que me enviaste)
  List<int> _parseEpisodiosPorTemporada(String? data) {
    if (data == null || data.isEmpty) return [];
    try {
      return data.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildProgresoTotalInfo(Elemento elemento) {
    // (Este código es el que me enviaste)
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
    // (Este código es el que me enviaste)
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
    // (Este código es el que me enviaste)
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
    // (Este código es el que me enviaste)
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
    // (Este código es el que me enviaste)
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
    // (Este código es el que me enviaste)
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

  /// --- ¡WIDGET REFACTORIZADO! (Petición 8, 17, F) ---
  Widget _buildAdminButtons(
      BuildContext context, PerfilUsuario perfil, Elemento elemento) {
    if (!perfil.esModerador) {
      return const SizedBox.shrink();
    }

    // --- Lógica del "interruptor" (Petición F) ---
    final bool esOficial = elemento.estadoContenido == 'OFICIAL';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // (Petición 8) Botón de Editar
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

          // (Petición 17 y F) Botón de Oficializar/Comunitarizar (Solo Admins)
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
                    // Icono dinámico
                    : Icon(esOficial ? Icons.public_off : Icons.verified,
                        size: 18),
                // Texto dinámico
                label: Text(_isLoadingStatusChange
                    ? '...'
                    : (esOficial ? 'Comunitarizar' : 'Oficializar')),
                style: ElevatedButton.styleFrom(
                  // Color dinámico
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
}