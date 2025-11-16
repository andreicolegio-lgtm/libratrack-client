import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/maybe_marquee.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/elemento_service.dart';
import '../../core/services/tipo_service.dart';
import '../../core/services/genero_service.dart';
import '../elemento/elemento_detail_screen.dart';
import '../propuestas/propuesta_form_screen.dart';
import '../../model/elemento.dart';
import '../../model/tipo.dart';
import '../../model/genero.dart';
import '../../model/paginated_response.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/services/auth_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ElementoService _elementoService;
  late final TipoService _tipoService;
  late final GeneroService _generoService;
  late AuthService _authService;

  final TextEditingController _searchController = TextEditingController();
  List<Tipo> _tipos = <Tipo>[];
  List<Genero> _generos = <Genero>[];
  String? _filtroTipoActivo;
  String? _filtroGeneroActivo;
  Future<void>? _filtrosFuture;
  final ScrollController _scrollController = ScrollController();
  final List<Elemento> _elementos = <Elemento>[];
  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _elementoService = context.read<ElementoService>();
    _tipoService = context.read<TipoService>();
    _generoService = context.read<GeneroService>();
    _authService = context.read<AuthService>();

    _filtrosFuture = _loadInitialData();
    _loadElementos(isFirstPage: true);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    try {
      final List<List<Object>> results =
          await Future.wait(<Future<List<Object>>>[
        _tipoService.fetchTipos(),
        _generoService.fetchGeneros(),
      ]);
      if (mounted) {
        setState(() {
          _tipos = results[0] as List<Tipo>;
          _generos = results[1] as List<Genero>;
        });
      }
    } on ApiException catch (e) {
      debugPrint('Error al cargar datos de consulta: $e');
      if (mounted) {
        setState(() {
          _loadingError = 'Error al cargar filtros: ${e.message}';
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos de consulta: $e');
      if (mounted) {
        setState(() {
          _loadingError = 'Error al cargar filtros: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    if (_isLoadingMore || !_hasNextPage) {
      return;
    }
    _loadElementos();
  }

  Future<void> _loadElementos({bool isFirstPage = false}) async {
    if (isFirstPage) {
      setState(() {
        _isLoadingFirstPage = true;
        _currentPage = 0;
        _elementos.clear();
        _hasNextPage = true;
        _loadingError = null;
      });
    } else {
      if (_isLoadingMore) {
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
    }
    try {
      final PaginatedResponse<Elemento> respuesta =
          await _elementoService.searchElementos(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        tipo: _filtroTipoActivo,
        genero: _filtroGeneroActivo,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _elementos.addAll(respuesta.content);
          _currentPage++;
          _hasNextPage = !respuesta.isLast;
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    } on UnauthorizedException {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.message;
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString();
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _reiniciarBusqueda() {
    FocusScope.of(context).unfocus();
    _loadElementos(isFirstPage: true);
  }

  void _clearSearch() {
    _searchController.clear();
    _filtroTipoActivo = null;
    _filtroGeneroActivo = null;
    _reiniciarBusqueda();
  }

  void _handleFiltroTap(String tipoFiltro, String nombre) {
    setState(() {
      if (tipoFiltro == 'tipo') {
        _filtroTipoActivo = (_filtroTipoActivo == nombre) ? null : nombre;
        _filtroGeneroActivo = null;
      } else if (tipoFiltro == 'genero') {
        _filtroGeneroActivo = (_filtroGeneroActivo == nombre) ? null : nombre;
        _filtroTipoActivo = null;
      }
    });
    _reiniciarBusqueda();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: _buildSearchTextField(context),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Proponer Elemento'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const PropuestaFormScreen(),
            ),
          ).then((_) => _reiniciarBusqueda());
        },
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FutureBuilder<void>(
            future: _filtrosFuture,
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _tipos.isEmpty) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snapshot.hasError && _tipos.isEmpty) {
                return Center(
                    child: Text('Error al cargar filtros: ${snapshot.error}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.red)));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Explorar por Tipo',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  _buildFiltroChips(
                    context,
                    data: _tipos.map((Tipo t) => t.nombre).toList(),
                    tipoFiltro: 'tipo',
                    filtroActivo: _filtroTipoActivo,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Explorar por Género',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  _buildFiltroChips(
                    context,
                    data: _generos.map((Genero g) => g.nombre).toList(),
                    tipoFiltro: 'genero',
                    filtroActivo: _filtroGeneroActivo,
                  ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: _buildResultadosLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadosLista() {
    if (_isLoadingFirstPage) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: CircularProgressIndicator(),
      ));
    }
    if (_loadingError != null) {
      return Center(
          child: Text('Error en la búsqueda: $_loadingError',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red)));
    }
    if (_elementos.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: Text('No se encontraron elementos con el filtro aplicado.'),
      ));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _elementos.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == _elementos.length) {
          return _isLoadingMore
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ))
              : const SizedBox(height: 1);
        }
        final Elemento elemento = _elementos[index];
        return _buildElementoListTile(context, elemento);
      },
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
    );
  }

  Widget _buildSearchTextField(BuildContext context) {
    final Color iconColor =
        Theme.of(context).colorScheme.onSurface.withAlpha(0x80);
    return TextField(
      controller: _searchController,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        hintText: 'Buscar por título...',
        hintStyle: Theme.of(context).textTheme.labelLarge,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.search, color: iconColor),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: iconColor),
                onPressed: _clearSearch,
              )
            : null,
      ),
      onSubmitted: (String value) {
        _reiniciarBusqueda();
      },
      onChanged: (String value) {
        setState(() {});
      },
    );
  }

  Widget _buildElementoListTile(BuildContext context, Elemento elemento) {
    final Color iconColor =
        Theme.of(context).colorScheme.onSurface.withAlpha(0x80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) =>
                  ElementoDetailScreen(elementoId: elemento.id),
            ),
          ).then((_) => _reiniciarBusqueda());
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 120,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5.0),
                child: elemento.urlImagen != null &&
                        elemento.urlImagen!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: elemento.urlImagen!,
                        fit: BoxFit.cover,
                        placeholder: (BuildContext context, String url) =>
                            Icon(Icons.downloading, color: iconColor),
                        errorWidget: (BuildContext context, String url,
                                Object error) =>
                            Icon(Icons.image_not_supported, color: iconColor),
                      )
                    : Icon(Icons.movie_filter, color: iconColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MaybeMarquee(
                    text: elemento.titulo,
                    style: Theme.of(context).textTheme.titleMedium ??
                        const TextStyle(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${elemento.tipo} | ${elemento.generos.join(", ")}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          overflow: TextOverflow.ellipsis,
                        ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  _buildEstadoChip(context, elemento.estadoContenido),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoChip(BuildContext context, String estado) {
    final bool isOficial = estado == 'OFICIAL';
    final Color chipColor =
        isOficial ? Theme.of(context).colorScheme.secondary : Colors.grey[700]!;
    return Chip(
      label: Text(
        isOficial ? 'OFICIAL' : 'COMUNITARIO',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFiltroChips(
    BuildContext context, {
    required List<String> data,
    required String tipoFiltro,
    required String? filtroActivo,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: data.map((String nombre) {
          final bool isSelected = nombre == filtroActivo;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(nombre),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.grey[400],
                  ),
              onPressed: () => _handleFiltroTap(tipoFiltro, nombre),
            ),
          );
        }).toList(),
      ),
    );
  }
}
