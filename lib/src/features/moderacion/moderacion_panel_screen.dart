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
        body: TabBarView(
          children:
              _estados.map((estado) => _PropuestasTab(estado: estado)).toList(),
        ),
      ),
    );
  }
}

class _PropuestasTab extends StatefulWidget {
  final EstadoPropuesta estado;
  const _PropuestasTab({required this.estado});

  @override
  State<_PropuestasTab> createState() => _PropuestasTabState();
}

class _PropuestasTabState extends State<_PropuestasTab>
    with AutomaticKeepAliveClientMixin {
  late final ModeracionService _moderacionService;
  late Future<List<Propuesta>> _propuestasFuture;

  // Lista local mutable para eliminar items visualmente al procesarlos
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
    // Como no implementamos "Rechazar" en el backend explícitamente (solo aprobar),
    // esto podría ser una llamada a un endpoint de actualización de estado a RECHAZADO.
    // Por ahora simularemos el éxito visual.

    setState(() => _processingIds.add(id));

    // TODO: Implementar endpoint real de rechazo en backend y servicio
    // await _moderacionService.rechazarPropuesta(id);

    // Simulación
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _propuestasList?.removeWhere((p) => p.id == id);
        _processingIds.remove(id);
      });
      SnackBarHelper.showTopSnackBar(context, 'Propuesta rechazada (Simulado)',
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
      // Eliminar de la lista de pendientes visualmente
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
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(errorMsg, textAlign: TextAlign.center),
                  TextButton(
                      onPressed: _refresh, child: const Text('Reintentar'))
                ],
              ),
            );
          }

          // Inicializar lista mutable la primera vez que llegan datos
          if (snapshot.hasData && _propuestasList == null) {
            _propuestasList = List.from(snapshot.data!);
          }

          final lista = _propuestasList ?? [];

          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.estado == EstadoPropuesta.pendiente
                        ? l10n.modPanelNoPending
                        : l10n.modPanelNoOthers(
                            widget.estado.displayName(context)),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = lista[index];
              return _buildPropuestaCard(context, p, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildPropuestaCard(
      BuildContext context, Propuesta p, AppLocalizations l10n) {
    final bool isPending = widget.estado == EstadoPropuesta.pendiente;
    final bool isProcessing = _processingIds.contains(p.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(100),
            child: Row(
              children: [
                Expanded(
                  child: MaybeMarquee(
                    text: p.tituloSugerido,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (p.tipoSugerido.isNotEmpty)
                  Chip(
                    label: Text(p.tipoSugerido,
                        style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person,
                    l10n.modPanelProposalFrom(p.proponenteUsername)),
                const SizedBox(height: 4),
                _infoRow(Icons.category,
                    l10n.modPanelProposalGenres(p.generosSugeridos)),
                if (p.descripcionSugerida != null &&
                    p.descripcionSugerida!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      p.descripcionSugerida!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        isProcessing ? null : () => _handleRechazar(p.id),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(l10n.modPanelReject),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isProcessing ? null : () => _handleRevisar(p),
                    icon: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.edit, size: 16),
                    label: Text(l10n.modPanelReview),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
