import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/moderacion_service.dart';
import '../../model/propuesta.dart';
import '../../model/estado_propuesta.dart';
import '../../core/widgets/maybe_marquee.dart';
import 'propuesta_edit_screen.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/filter_modal.dart';
import '../admin/admin_elemento_form.dart';
import 'created_elements_screen.dart';

class ModeracionPanelScreen extends StatefulWidget {
  const ModeracionPanelScreen({super.key});

  @override
  State<ModeracionPanelScreen> createState() => _ModeracionPanelScreenState();
}

class _ModeracionPanelScreenState extends State<ModeracionPanelScreen> {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.modPanelTitle),
          centerTitle: true,
          bottom: TabBar(
            tabs:
                _estados.map((e) => Tab(text: e.displayName(context))).toList(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Barra de búsqueda y filtros
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                        // Pasar parámetros de ordenamiento
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
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: _estados
                      .map((estado) => _PropuestasTab(
                            estado: estado,
                            searchQuery: _searchController.text,
                            // Pasar filtros si quieres filtrar en cliente
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'crearElemento',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminElementoFormScreen(),
                  ),
                );
              },
              tooltip: 'Crear Elemento',
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              heroTag: 'historial',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatedElementsScreen(),
                  ),
                );
              },
              tooltip: 'Historial',
              child: const Icon(Icons.history),
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

  const _PropuestasTab({
    required this.estado,
    required this.searchQuery,
  });

  @override
  State<_PropuestasTab> createState() => _PropuestasTabState();
}

class _PropuestasTabState extends State<_PropuestasTab>
    with AutomaticKeepAliveClientMixin {
  late final ModeracionService _moderacionService;
  late Future<List<Propuesta>> _propuestasFuture;

  List<Propuesta>? _propuestasList;
  final Set<int> _processingIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _moderacionService = context.read<ModeracionService>();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _propuestasFuture =
          _moderacionService.fetchPropuestasPorEstado(widget.estado.apiValue);
    });
  }

  Future<void> _handleRechazar(int id) async {
    setState(() => _processingIds.add(id));
    // TODO: Implementar endpoint real. Por ahora simulamos éxito.
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _propuestasList?.removeWhere((p) => p.id == id);
        _processingIds.remove(id);
      });
      SnackBarHelper.showTopSnackBar(context, 'Propuesta rechazada',
          isError: false, isNeutral: true);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);

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
          // Aquí podrías aplicar el filtro de _searchQuery localmente si lo deseas

          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No hay propuestas ${widget.estado.name}'),
                ],
              ),
            );
          }

          return ListView.separated(
            key: PageStorageKey('mod_tab_${widget.estado.apiValue}'),
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = lista[index];
              final isProcessing = _processingIds.contains(p.id);

              // Usamos el nuevo widget _PropuestaCard
              return _PropuestaCard(
                titulo: p.tituloSugerido,
                usuario: p.proponenteUsername,
                tipo: p.tipoSugerido,
                generos: p.generosSugeridos.split(','),
                isProcessing: isProcessing,
                onRechazar: isProcessing ? () {} : () => _handleRechazar(p.id),
                onRevisar: isProcessing ? () {} : () => _handleRevisar(p),
              );
            },
          );
        },
      ),
    );
  }
}

class _PropuestaCard extends StatelessWidget {
  final String titulo;
  final String usuario;
  final String tipo;
  final List<String> generos;
  final bool isProcessing;
  final VoidCallback onRechazar;
  final VoidCallback onRevisar;

  const _PropuestaCard({
    required this.titulo,
    required this.usuario,
    required this.tipo,
    required this.generos,
    required this.isProcessing,
    required this.onRechazar,
    required this.onRevisar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con Marquee
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              height: 24,
              child: MaybeMarquee(
                text: titulo,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Cuerpo
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text: 'Proposed by: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: usuario),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text: 'Type: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: tipo),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                // Lista horizontal de géneros
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: generos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Chip(
                        label: Text(generos[index].trim()),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 11),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRechazar,
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                  child: const Text('Rechazar'),
                ),
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
            ),
          ),
        ],
      ),
    );
  }
}
