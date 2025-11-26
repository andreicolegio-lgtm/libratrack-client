import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/catalog_service.dart';
import '../../core/services/auth_service.dart';
import '../../model/catalogo_entrada.dart';
import '../../model/estado_personal.dart';
import '../../core/utils/error_translator.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/api_exceptions.dart';
import 'widgets/catalog_entry_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late final CatalogService _catalogService;
  late final AuthService _authService;

  bool _isDataLoaded = false;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _catalogService = context.read<CatalogService>();
    _authService = context.read<AuthService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      _loadCatalog();
      _isDataLoaded = true;
    }
  }

  Future<void> _loadCatalog() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await _catalogService.fetchCatalog();
      if (mounted) {
        setState(() => _loadingError = null);
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      if (e is UnauthorizedException) {
        _authService.logout();
      } else {
        setState(() {
          _loadingError = ErrorTranslator.translate(context, e.message);
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingError = l10n.errorLoadingCatalog(e.toString());
      });
    }
  }

  List<CatalogoEntrada> _filterCatalogo(
      int tabIndex, List<CatalogoEntrada> all) {
    switch (tabIndex) {
      case 0: // Todos
        return all;
      case 1: // Favoritos
        return all.where((e) => e.esFavorito).toList();
      case 2: // En Progreso
        return all
            .where(
                (e) => e.estadoPersonal == EstadoPersonal.enProgreso.apiValue)
            .toList();
      case 3: // Pendiente
        return all
            .where((e) => e.estadoPersonal == EstadoPersonal.pendiente.apiValue)
            .toList();
      case 4: // Terminado
        return all
            .where((e) => e.estadoPersonal == EstadoPersonal.terminado.apiValue)
            .toList();
      case 5: // Abandonado
        return all
            .where(
                (e) => e.estadoPersonal == EstadoPersonal.abandonado.apiValue)
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Definición de pestañas
    final List<Tab> tabs = [
      Tab(text: l10n.adminPanelFilterAll),
      const Tab(icon: Icon(Icons.star, size: 18), text: 'Favs'), // "Favorites"
      Tab(text: l10n.catalogInProgress),
      Tab(text: l10n.catalogPending),
      Tab(text: l10n.catalogFinished),
      Tab(text: l10n.catalogDropped),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.catalogTitle,
              style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: tabs,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        body: Consumer<CatalogService>(
          builder: (context, catalogService, child) {
            if (catalogService.isLoading && catalogService.entradas.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_loadingError != null) {
              return _buildErrorState(_loadingError!);
            }

            return TabBarView(
              children: List.generate(tabs.length, (index) {
                final filteredList =
                    _filterCatalogo(index, catalogService.entradas);

                if (filteredList.isEmpty) {
                  return _buildEmptyState(l10n, index);
                }

                return RefreshIndicator(
                  onRefresh: _loadCatalog,
                  child: ListView.separated(
                    key: PageStorageKey(
                        'catalog_tab_$index'), // Preserva scroll por pestaña
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      return CatalogEntryCard(
                        key: ValueKey(filteredList[i].id),
                        entrada: filteredList[i],
                        onUpdate: () {},
                      );
                    },
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, int index) {
    IconData icon;
    String message;

    switch (index) {
      case 1: // Favoritos
        icon = Icons.star_border;
        message = 'Aún no tienes favoritos.';
        break;
      case 2: // En Progreso
        icon = Icons.play_circle_outline;
        message = 'No estás viendo nada actualmente.';
        break;
      case 3: // Pendiente
        icon = Icons.schedule;
        message = '¡Estás al día! Nada pendiente.';
        break;
      case 4: // Terminado
        icon = Icons.check_circle_outline;
        message = 'Aún no has terminado nada.';
        break;
      default:
        icon = Icons.collections_bookmark_outlined;
        message = 'Tu catálogo está vacío.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCatalog,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          )
        ],
      ),
    );
  }
}
