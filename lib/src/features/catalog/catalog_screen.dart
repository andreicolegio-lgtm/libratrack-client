import '../../core/utils/error_translator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/catalog_service.dart';
import '../../model/catalogo_entrada.dart';
import '../../model/estado_personal.dart';
import 'widgets/catalog_entry_card.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/services/auth_service.dart';
import '../../core/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _catalogService = context.read<CatalogService>();
    _authService = context.read<AuthService>();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
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
          _loadingError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Map<EstadoPersonal, String> estadoDisplayNames = {
      EstadoPersonal.enProgreso: l10n.catalogInProgress,
      EstadoPersonal.pendiente: l10n.catalogPending,
      EstadoPersonal.terminado: l10n.catalogFinished,
      EstadoPersonal.abandonado: l10n.catalogDropped,
    };

    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.catalogTitle,
              style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
          bottom: TabBar(
            tabAlignment: TabAlignment.center,
            tabs: _estados
                .map((EstadoPersonal estado) =>
                    Tab(text: estadoDisplayNames[estado]))
                .toList(),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey[500],
          ),
        ),
        body: _buildBody(context, estadoDisplayNames),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, Map<EstadoPersonal, String> estadoDisplayNames) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_loadingError',
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
      children: _estados.map((EstadoPersonal estado) {
        final List<CatalogoEntrada> filteredList = _catalogoCompleto
            .where((CatalogoEntrada item) =>
                item.estadoPersonal == estado.apiValue)
            .toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              l10n.catalogEmptyState(estadoDisplayNames[estado]!),
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
