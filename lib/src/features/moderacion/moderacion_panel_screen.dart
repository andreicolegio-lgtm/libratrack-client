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

class ModeracionPanelScreen extends StatefulWidget {
  const ModeracionPanelScreen({super.key});

  @override
  State<ModeracionPanelScreen> createState() => _ModeracionPanelScreenState();
}

class _ModeracionPanelScreenState extends State<ModeracionPanelScreen>
    with SingleTickerProviderStateMixin {
  final List<EstadoPropuesta> _estados = <EstadoPropuesta>[
    EstadoPropuesta.pendiente,
    EstadoPropuesta.aprobado,
    EstadoPropuesta.rechazado,
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileModPanelButton,
              style: Theme.of(context).textTheme.titleLarge),
          backgroundColor: Theme.of(context).colorScheme.surface,
          centerTitle: true,
          bottom: TabBar(
            tabAlignment: TabAlignment.center,
            tabs: _estados
                .map((EstadoPropuesta estado) => Tab(text: estado.displayName))
                .toList(),
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey[500],
          ),
        ),
        body: TabBarView(
          children: _estados.map((EstadoPropuesta estado) {
            return _PropuestasTab(
              estado: estado,
              key: ValueKey(estado.apiValue),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PropuestasTab extends StatefulWidget {
  final EstadoPropuesta estado;
  const _PropuestasTab({required this.estado, super.key});
  @override
  State<_PropuestasTab> createState() => _PropuestasTabState();
}

class _PropuestasTabState extends State<_PropuestasTab>
    with AutomaticKeepAliveClientMixin {
  late final ModeracionService _moderacionService;

  late Future<List<Propuesta>> _propuestasFuture;
  List<Propuesta> _propuestas = <Propuesta>[];
  final Set<int> _processingItems = <int>{};

  @override
  void initState() {
    super.initState();
    _moderacionService = context.read<ModeracionService>();
    _loadPropuestas();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadPropuestas() async {
    _propuestasFuture =
        _moderacionService.fetchPropuestasPorEstado(widget.estado.apiValue);
    try {
      _propuestas = await _propuestasFuture;
      if (mounted) {
        setState(() {});
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleRevisar(Propuesta propuesta) async {
    final bool? seHaAprobado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            PropuestaEditScreen(propuesta: propuesta),
      ),
    );

    if (seHaAprobado == true && mounted) {
      setState(() {
        _propuestas.removeWhere((Propuesta p) => p.id == propuesta.id);
      });
      SnackBarHelper.showTopSnackBar(
        ScaffoldMessenger.of(context),
        '¡Propuesta aprobada!',
        isError: false,
      );
    }
  }

  Future<void> _handleRechazar(int propuestaId) async {
    setState(() {
      _processingItems.add(propuestaId);
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _propuestas.removeWhere((Propuesta p) => p.id == propuestaId);
        _processingItems.remove(propuestaId);
      });
      SnackBarHelper.showTopSnackBar(
        ScaffoldMessenger.of(context),
        'Propuesta rechazada (simulado).',
        isError: false,
        isNeutral: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Propuesta>>(
      future: _propuestasFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Propuesta>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar:\n${snapshot.error.toString()}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.red),
              ),
            ),
          );
        }
        if (_propuestas.isEmpty) {
          return Center(
            child: Text(widget.estado == EstadoPropuesta.pendiente
                ? '¡Buen trabajo! No hay propuestas pendientes.'
                : 'No hay propuestas ${widget.estado.displayName.toLowerCase()}.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: _propuestas.length,
          itemBuilder: (BuildContext context, int index) {
            final Propuesta propuesta = _propuestas[index];
            final bool isProcessing = _processingItems.contains(propuesta.id);
            return _buildPropuestaCard(context, propuesta, isProcessing, l10n);
          },
        );
      },
    );
  }

  Widget _buildPropuestaCard(BuildContext context, Propuesta propuesta,
      bool isProcessing, AppLocalizations l10n) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MaybeMarquee(
              text: propuesta.tituloSugerido,
              style:
                  Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
              height: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Propuesto por: ${propuesta.proponenteUsername}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tipo: ${propuesta.tipoSugerido}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Géneros: ${propuesta.generosSugeridos}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.estado == EstadoPropuesta.pendiente) ...<Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.red[300]),
                    onPressed: isProcessing
                        ? null
                        : () => _handleRechazar(propuesta.id),
                    child: const Text('Rechazar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        isProcessing ? null : () => _handleRevisar(propuesta),
                    child: isProcessing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Revisar'),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
