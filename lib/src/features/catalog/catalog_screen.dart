import '../../core/utils/error_translator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/catalog_service.dart';
import '../../model/catalogo_entrada.dart';
import 'widgets/catalog_entry_card.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/services/auth_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../model/estado_personal.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late final CatalogService _catalogService;
  late final AuthService _authService;

  bool _isLoading = true;
  String? _loadingError;
  List<CatalogoEntrada> _catalogoCompleto = <CatalogoEntrada>[];

  bool _isDataLoaded = false;

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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    try {
      await _catalogService.fetchCatalog();

      if (mounted) {
        setState(() {
          _catalogoCompleto = _catalogService.entradas;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e is UnauthorizedException) {
          _authService.logout();
        } else {
          setState(() {
            _loadingError = ErrorTranslator.translate(context, e.message);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = l10n.errorLoadingCatalog(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  List<CatalogoEntrada> _filterCatalogo(int index) {
    switch (index) {
      case 0: // All
        return _catalogoCompleto;
      case 1: // Favorites
        return _catalogoCompleto.where((item) => item.esFavorito).toList();
      case 2: // In Progress
        return _catalogoCompleto
            .where((item) =>
                item.estadoPersonal == EstadoPersonal.enProgreso.apiValue)
            .toList();
      case 3: // Pending
        return _catalogoCompleto
            .where((item) =>
                item.estadoPersonal == EstadoPersonal.pendiente.apiValue)
            .toList();
      case 4: // Finished
        return _catalogoCompleto
            .where((item) =>
                item.estadoPersonal == EstadoPersonal.terminado.apiValue)
            .toList();
      case 5: // Dropped
        return _catalogoCompleto
            .where((item) =>
                item.estadoPersonal == EstadoPersonal.abandonado.apiValue)
            .toList();
      default:
        return _catalogoCompleto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // Definimos las pestañas dentro del build para usar l10n correctamente
    final List<Tab> tabs = [
      Tab(text: l10n.adminPanelFilterAll), // All / Todos
      const Tab(text: 'Favorites'), // TODO: Añadir clave l10n.catalogFavorites
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              physics: const BouncingScrollPhysics(),
              tabs: tabs,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[500],
            ),
          ),
        ),
        body: _buildBody(context, l10n, tabs),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppLocalizations l10n, List<Tab> tabs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _loadingError!,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    return TabBarView(
      children: List.generate(tabs.length, (int index) {
        final List<CatalogoEntrada> filteredList = _filterCatalogo(index);

        if (filteredList.isEmpty) {
          final String tabName = tabs[index].text ?? '';
          return Center(
            child: Text(
              l10n.catalogEmptyState(tabName),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (BuildContext context, int listIndex) {
            final CatalogoEntrada item = filteredList[listIndex];
            return CatalogEntryCard(
              key: ValueKey(item.id), // Importante para rendimiento y estado
              entrada: item,
              onUpdate: _loadCatalog,
            );
          },
        );
      }),
    );
  }
}
