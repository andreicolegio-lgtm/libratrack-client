import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/moderacion_service.dart';
import '../../model/propuesta.dart';
import '../../model/estado_propuesta.dart';
import '../../core/widgets/maybe_marquee.dart';
import '../elemento/elemento_detail_screen.dart';
import 'propuesta_edit_screen.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/filter_modal.dart';
import 'elemento_form.dart';
import 'created_elements_screen.dart';
import '../../core/services/auth_service.dart';

class ModeracionPanelScreen extends StatefulWidget {
  const ModeracionPanelScreen({super.key});

  @override
  State<ModeracionPanelScreen> createState() => _ModeracionPanelScreenState();
}

class _ModeracionPanelScreenState extends State<ModeracionPanelScreen>
    with SingleTickerProviderStateMixin {
  final List<EstadoPropuesta> _estados = [
    EstadoPropuesta.pendiente,
    EstadoPropuesta.aprobado,
    EstadoPropuesta.rechazado,
  ];

  // Estado para búsqueda y filtros
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTypes = [];
  List<String> _selectedGenres = [];
  String _sortMode = 'DATE'; // 'DATE' o 'ALPHA'
  bool _isAscending = false; // Por defecto descendente (más nuevo arriba)

  late TabController _tabController;
  late final ModeracionService
      _moderacionService; // Service for moderation logic

  final Map<EstadoPropuesta, List<Propuesta>> _cacheGlobal =
      {}; // Caché global para propuestas

  Timer? _debounce; // Timer para manejar el debounce
  String _activeSearchQuery = ''; // Nueva variable de estado

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _estados.length, vsync: this);
    _moderacionService =
        context.read<ModeracionService>(); // Initialize the service
    _preloadAllData(); // Ensure data is preloaded
    _searchController
        .addListener(_onSearchChanged); // Add listener for search changes
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSmartSearch(String query) {
    if (query.isEmpty) {
      return;
    }

    // Buscar en la caché de cada estado
    for (final estado in _estados) {
      final list = _cacheGlobal[estado] ?? [];
      final hasMatch = list.any(
          (p) => p.tituloSugerido.toLowerCase().contains(query.toLowerCase()));

      if (hasMatch) {
        final index = _estados.indexOf(estado);
        if (_tabController.index != index) {
          _tabController.animateTo(index);
        }
        break; // Encontrado, dejamos de buscar
      }
    }
  }

  void _onSearchChanged() {
    // 1. Cancelar el timer anterior si el usuario sigue escribiendo
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    // 2. Iniciar nuevo timer de 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // 3. Solo actualizamos el estado (y por tanto las tabs hijas) cuando el timer termina
      if (mounted) {
        setState(() {
          _activeSearchQuery = _searchController.text.trim();
          // Al hacer setState, el texto actual del controller se propaga a los hijos
          // y dispara su lógica de 'didUpdateWidget' -> API Call
        });

        _performSmartSearch(_activeSearchQuery);
      }
    });
  }

  Future<void> _preloadAllData() async {
    // Carga paralela de todos los estados para llenar la caché lo antes posible
    final results = await Future.wait([
      _moderacionService
          .fetchPropuestasPorEstado(EstadoPropuesta.pendiente.apiValue),
      _moderacionService
          .fetchPropuestasPorEstado(EstadoPropuesta.aprobado.apiValue),
      _moderacionService
          .fetchPropuestasPorEstado(EstadoPropuesta.rechazado.apiValue),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _cacheGlobal[EstadoPropuesta.pendiente] = results[0];
      _cacheGlobal[EstadoPropuesta.aprobado] = results[1];
      _cacheGlobal[EstadoPropuesta.rechazado] = results[2];
    });

    // Si el usuario ya escribió algo mientras cargaba, re-evaluamos la redirección ahora
    if (_searchController.text.isNotEmpty) {
      _onSearchChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation Panel'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Buscar propuestas...',
                  onFilterPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => FilterModal(
                        selectedTypes: _selectedTypes,
                        selectedGenres: _selectedGenres,
                        currentSortMode: _sortMode,
                        isAscending: _isAscending,
                        onSortChanged: (mode, ascending) {
                          setState(() {
                            _sortMode = mode;
                            _isAscending = ascending;
                          });
                        },
                        onApply: (types, genres) {
                          setState(() {
                            _selectedTypes = types;
                            _selectedGenres = genres;
                          });
                        },
                      ),
                    );
                  },
                  onChanged: _onSearchChanged, // Eliminado setState
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: 'Pendientes'),
                  Tab(text: 'Aprobados'),
                  Tab(text: 'Rechazados'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _estados
                    .map((estado) => _PropuestasTab(
                          // CLAVE MÁGICA: Si cambia cualquier filtro, Flutter recrea este widget
                          key: ValueKey('${estado.name}_${_activeSearchQuery}_'
                              '${_selectedTypes.length}_${_selectedGenres.length}_$_sortMode$_isAscending'),
                          estado: estado,
                          searchQuery: _activeSearchQuery, // Cambio clave
                          types: _selectedTypes,
                          genres: _selectedGenres,
                          sortMode: _sortMode, // Pasar _sortMode
                          isAscending: _isAscending, // Pasar _isAscending
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Botón Historial (Izquierda)
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'btnHistorial',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatedElementsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Historial'),
              ),
            ),
            const SizedBox(width: 16), // Espacio central
            // Botón Crear (Derecha)
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'btnCrear',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ElementoFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Elemento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropuestasTab extends StatefulWidget {
  final EstadoPropuesta estado;
  final String searchQuery;
  final List<String> types;
  final List<String> genres;
  final String sortMode; // Nuevo
  final bool isAscending; // Nuevo

  const _PropuestasTab({
    required this.estado,
    required this.searchQuery,
    required this.types,
    required this.genres,
    required this.sortMode, // Nuevo
    required this.isAscending, // Nuevo
    super.key, // Usa super.key
  });

  @override
  State<_PropuestasTab> createState() => _PropuestasTabState();
}

class _PropuestasTabState extends State<_PropuestasTab> {
  late final ModeracionService _moderacionService;
  late Future<List<Propuesta>> _propuestasFuture;

  List<Propuesta>? _propuestasList;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _moderacionService = context.read<ModeracionService>();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _PropuestasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.types != oldWidget.types ||
        widget.genres != oldWidget.genres ||
        widget.sortMode != oldWidget.sortMode || // Nuevo
        widget.isAscending != oldWidget.isAscending) {
      // Nuevo
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _propuestasFuture = _moderacionService.fetchPropuestasPorEstado(
        widget.estado.apiValue,
        search: widget.searchQuery,
        types: widget.types,
        genres: widget.genres,
        sortMode: widget.sortMode, // Nuevo
        isAscending: widget.isAscending, // Nuevo
      );
    });
  }

  Future<void> _handleRechazar(int id) async {
    final TextEditingController reasonController = TextEditingController();

    // 1. Pedir motivo (Obligatorio)
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Propuesta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Indica el motivo del rechazo:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Ej. Información duplicada o incorrecta',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                return; // Validar vacío
              }
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _processingIds.add(id));

    try {
      // Llamada real al servicio pasando el motivo
      await _moderacionService.rechazarPropuesta(
          id, reasonController.text.trim());

      if (mounted) {
        setState(() {
          _propuestasList?.removeWhere((p) => p.id == id);
          _processingIds.remove(id);
        });
        SnackBarHelper.showTopSnackBar(context, 'Propuesta rechazada',
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingIds.remove(id));
        // Manejo de error visual si lo deseas
      }
    }
  }

  Future<void> _handleRevisar(Propuesta propuesta) async {
    final bool? approved = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PropuestaEditScreen(propuesta: propuesta)),
    );

    if (approved == true && mounted) {
      setState(() {
        _propuestasList?.removeWhere((p) => p.id == propuesta.id);
      });
      SnackBarHelper.showTopSnackBar(
          context, AppLocalizations.of(context).snackbarModProposalApproved,
          isError: false);
    }
  }

  void _showComentarios(Propuesta p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comentarios de Revisión'),
        content: SingleChildScrollView(
          child: Text(
            (p.comentariosRevision != null && p.comentariosRevision!.isNotEmpty)
                ? p.comentariosRevision!
                : 'Sin comentarios registrados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPending =
        widget.estado == EstadoPropuesta.pendiente; // Chequeo de estado

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Propuesta>>(
        future: _propuestasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _propuestasList == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            String errorMsg = l10n.errorUnexpected(snapshot.error.toString());
            if (snapshot.error is ApiException) {
              errorMsg = ErrorTranslator.translate(
                  context, (snapshot.error as ApiException).message);
            }
            return Center(child: Text(errorMsg));
          }

          if (snapshot.hasData && _propuestasList == null) {
            _propuestasList = List.from(snapshot.data!);
          }
          final lista = _propuestasList ?? [];

          if (lista.isEmpty) {
            return const Center(child: Text('No hay resultados'));
          }

          return ListView.separated(
            padding: const EdgeInsets.only(
                top: 16, left: 16, right: 16, bottom: 100),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = lista[index];
              final isProcessing = _processingIds.contains(p.id);

              return _PropuestaCard(
                propuesta: p,
                isProcessing: isProcessing,

                // LÓGICA DE BOTONES:
                // Si es Pendiente -> Mostrar Rechazar/Revisar
                onRechazar: isPending && !isProcessing
                    ? () => _handleRechazar(p.id)
                    : null,
                onRevisar:
                    isPending && !isProcessing ? () => _handleRevisar(p) : null,

                // Si NO es Pendiente (Aprobada/Rechazada) -> Mostrar Comentarios
                onVerComentarios: !isPending ? () => _showComentarios(p) : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _PropuestaCard extends StatelessWidget {
  final Propuesta propuesta; // Pasamos el objeto entero para acceder a todo
  final bool isProcessing;
  final VoidCallback? onRechazar; // Null si no aplica (ej. ya aprobado)
  final VoidCallback? onRevisar; // Null si no aplica
  final VoidCallback? onVerComentarios; // Nuevo botón

  const _PropuestaCard({
    required this.propuesta,
    required this.isProcessing,
    this.onRechazar,
    this.onRevisar,
    this.onVerComentarios,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<AuthService>();
    final bool isAdmin = authService.currentUser?.esAdministrador ?? false;

    final String genresText =
        propuesta.generosSugeridos.split(',').map((e) => e.trim()).join(', ');
    final String typeText = propuesta.tipoSugerido;

    // Lógica de Navegación: Solo si está aprobado y ya se creó el elemento real
    final bool canNavigate = propuesta.estadoPropuesta == 'APROBADO' &&
        propuesta.elementoCreadoId != null;

    return Card(
      clipBehavior: Clip
          .antiAlias, // Para que la onda de choque respete los bordes redondeados
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        // TRUCO: Si onTap es null, el InkWell se desactiva visualmente (sin efecto)
        onTap: canNavigate
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ElementoDetailScreen(
                        elementoId: propuesta.elementoCreadoId!),
                    settings: const RouteSettings(name: 'ElementoDetailScreen'),
                  ),
                );
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BARRA SUPERIOR (Título)
            Container(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(
                height: 22,
                child: MaybeMarquee(
                  text: propuesta.tituloSugerido,
                  style: theme.textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // 2. CUERPO
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo • Géneros
                  SizedBox(
                    height: 20,
                    child: MaybeMarquee(
                      text: '$typeText • $genresText',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // INFORMACIÓN DE USUARIOS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IZQUIERDA: Revised By
                      Expanded(
                        child: propuesta.revisorUsername != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    propuesta.estadoPropuesta == 'APROBADO'
                                        ? 'Approved by:'
                                        : 'Rejected by:',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.grey, fontSize: 10),
                                  ),
                                  Text(
                                    propuesta.revisorUsername!,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (isAdmin && propuesta.revisorEmail != null)
                                    Text(
                                      '(${propuesta.revisorEmail})',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              fontSize: 10, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 8),
                      // DERECHA: Proposed By
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Proposed by:',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: Colors.grey, fontSize: 10),
                            ),
                            Text(
                              propuesta.proponenteUsername,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                            if (isAdmin && propuesta.proponenteEmail != null)
                              Text(
                                '(${propuesta.proponenteEmail})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10, color: Colors.grey),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 3. BOTONES DE ACCIÓN
            if (onRechazar != null ||
                onRevisar != null ||
                onVerComentarios != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onVerComentarios != null)
                      TextButton.icon(
                        icon: const Icon(Icons.comment, size: 16),
                        label: const Text('Comentarios'),
                        onPressed: onVerComentarios,
                      ),
                    const Spacer(),
                    if (onRechazar != null)
                      TextButton(
                        onPressed: onRechazar,
                        style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error),
                        child: const Text('Rechazar'),
                      ),
                    if (onRevisar != null) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onRevisar,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.edit, size: 16),
                        label: const Text('Revisar'),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
