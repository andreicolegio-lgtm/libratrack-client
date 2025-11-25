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

  final List<EstadoPersonal> _estados = <EstadoPersonal>[
    EstadoPersonal.enProgreso,
    EstadoPersonal.pendiente,
    EstadoPersonal.terminado,
    EstadoPersonal.abandonado
  ];

  final List<Tab> _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Favorites'),
    Tab(text: 'In Progress'),
    Tab(text: 'Pending'),
    Tab(text: 'Finished'),
    Tab(text: 'Dropped'),
  ];

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

  List<CatalogoEntrada> _filterCatalogo(String tab) {
    if (_estados.any((estado) => estado.name == tab)) {
      return _catalogoCompleto
          .where((item) => item.estadoPersonal == tab.toUpperCase())
          .toList();
    }
    switch (tab) {
      case 'Favorites':
        return _catalogoCompleto.where((item) => item.esFavorito).toList();
      default:
        return _catalogoCompleto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: _tabs.length,
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
              tabs: _tabs,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[500],
            ),
          ),
        ),
        body: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
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
      children: _tabs.map((Tab tab) {
        final List<CatalogoEntrada> filteredList = _filterCatalogo(tab.text!);

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              l10n.catalogEmptyState(tab.text!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (BuildContext context, int index) {
            final CatalogoEntrada item = filteredList[index];
            return CatalogEntryCard(
              entrada: item,
              onUpdate: _loadCatalog,
            );
          },
        );
      }).toList(),
    );
  }
}
