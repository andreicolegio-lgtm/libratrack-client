import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/propuesta_service.dart';
import '../../core/services/tipo_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/utils/error_translator.dart';
import '../../model/tipo.dart';
import '../../core/widgets/genre_selector_widget.dart';
import '../../core/widgets/content_type_progress_forms.dart';

class PropuestaFormScreen extends StatefulWidget {
  const PropuestaFormScreen({super.key});

  @override
  State<PropuestaFormScreen> createState() => _PropuestaFormScreenState();
}

class _PropuestaFormScreenState extends State<PropuestaFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isDataLoaded = false;

  // Controladores
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController =
      TextEditingController(); // Opcional, pero útil para contexto
  final TextEditingController _generosController = TextEditingController();

  // Controladores de Progreso
  final TextEditingController _episodiosPorTemporadaController =
      TextEditingController();
  final TextEditingController _totalUnidadesController =
      TextEditingController();
  final TextEditingController _totalCapitulosLibroController =
      TextEditingController();
  final TextEditingController _totalPaginasLibroController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _tipoSeleccionado;
  String? _estadoPublicacionSeleccionado;

  List<Tipo> _tipos = [];

  @override
  void initState() {
    super.initState();
    _loadTipos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _generosController.dispose();
    _episodiosPorTemporadaController.dispose();
    _totalUnidadesController.dispose();
    _totalCapitulosLibroController.dispose();
    _totalPaginasLibroController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadTipos() async {
    final tipoService = context.read<TipoService>();
    try {
      final tipos = await tipoService.fetchTipos('Error loading types');
      if (mounted) {
        setState(() {
          _tipos = tipos;
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDataLoaded = true);
      }
    }
  }

  Future<void> _submitPropuesta() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      SnackBarHelper.showTopSnackBar(
          context, 'Por favor, revisa los campos obligatorios.',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    final propuestaService = context.read<PropuestaService>();

    try {
      final Map<String, dynamic> body = {
        'tituloSugerido': _tituloController.text.trim(),
        'descripcionSugerida': _descripcionController.text.trim(), // Opcional
        'tipoSugerido': _tipoSeleccionado,
        'generosSugeridos': _generosController.text.trim(),

        // Progreso (Opcional)
        'episodiosPorTemporada':
            _episodiosPorTemporadaController.text.trim().isEmpty
                ? null
                : _episodiosPorTemporadaController.text.trim(),
        'totalUnidades': int.tryParse(_totalUnidadesController.text.trim()),
        'totalCapitulosLibro':
            int.tryParse(_totalCapitulosLibroController.text.trim()),
        'totalPaginasLibro':
            int.tryParse(_totalPaginasLibroController.text.trim()),
        'duracion': _durationController.text.trim().isEmpty
            ? null
            : _durationController.text.trim(),

        // Disponibilidad (Opcional, backend debe aceptarlo o ignorarlo si no está en DTO de propuesta inicial)
        // Si tu DTO de CREACIÓN de propuesta no tiene este campo, el backend lo ignorará silenciosamente.
        'estadoPublicacion': _estadoPublicacionSeleccionado,
      };

      body.removeWhere((key, value) => value == null || value == '');

      await propuestaService.crearPropuesta(body);

      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarProposalSent,
          isError: false);
      navigator.pop();
    } catch (e) {
      _handleError(e, l10n);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(Object e, AppLocalizations l10n) {
    if (!mounted) {
      return;
    }
    String msg = l10n.errorUnexpected(e.toString());
    if (e is ApiException) {
      msg = ErrorTranslator.translate(context, e.message);
    }
    SnackBarHelper.showTopSnackBar(context, msg, isError: true);
  }

  // --- UI Helpers (Estilo ElementoForm) ---

  InputDecoration getCommonDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  Widget _buildSectionField(
      {required String label, required Widget child, String? errorText}) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                    color: hasError ? theme.colorScheme.error : Colors.grey),
              ),
              child: child,
            ),
            Positioned(
              left: 10,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: theme.scaffoldBackgroundColor,
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: hasError
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant)),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(errorText,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 12))),
      ],
    );
  }

  Widget _buildGenreSelector() {
    final selectedTypeObj = _tipos.firstWhere(
      (t) => t.nombre == _tipoSeleccionado,
      orElse: () => const Tipo(id: 0, nombre: '', validGenres: []),
    );
    return GenreSelectorWidget(
      selectedTypes: _tipoSeleccionado != null ? [selectedTypeObj] : [],
      initialGenres: _generosController.text
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((e) => e.trim())
          .toList(),
      onChanged: (genres) =>
          setState(() => _generosController.text = genres.join(', ')),
    );
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_isDataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.proposalFormTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.proposalFormTitle,
            style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. Título (Obligatorio)
                TextFormField(
                  controller: _tituloController,
                  decoration: getCommonDecoration(l10n.proposalFormTitleLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.validationTitleRequired
                      : null,
                ),
                const SizedBox(height: 24),

                // 2. Tipo (Obligatorio)
                DropdownButtonFormField<String>(
                  initialValue: _tipoSeleccionado,
                  hint: Text(l10n.proposalFormTypeLabel),
                  items: _tipos
                      .map((t) => DropdownMenuItem(
                          value: t.nombre, child: Text(t.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoSeleccionado = v),
                  decoration: getCommonDecoration(l10n.proposalFormTypeLabel),
                  validator: (v) =>
                      v == null ? l10n.validationTypeRequired : null,
                ),
                const SizedBox(height: 24),

                // 3. Género (Obligatorio)
                FormField<String>(
                  validator: (_) => _generosController.text.isEmpty
                      ? l10n.validationGenresRequired
                      : null,
                  builder: (state) => _buildSectionField(
                    label: 'Genre',
                    errorText: state.errorText,
                    child: _buildGenreSelector(),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Progress Data (Opcional para propuesta, pero útil)
                if (_tipoSeleccionado != 'Video Game') ...[
                  _buildSectionField(
                    label: 'Progress Data (Optional)',
                    child: ContentTypeProgressForms(
                      selectedTypeKey: _tipoSeleccionado,
                      episodesController: _episodiosPorTemporadaController,
                      chaptersController: _totalCapitulosLibroController,
                      pagesController: _totalPaginasLibroController,
                      durationController: _durationController,
                      unitsController: _totalUnidadesController,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 5. Availability (Opcional)
                DropdownButtonFormField<String>(
                  initialValue: _estadoPublicacionSeleccionado,
                  hint: const Text('Select Availability'),
                  items: const [
                    DropdownMenuItem(
                        value: 'RELEASING', child: Text('Releasing')),
                    DropdownMenuItem(
                        value: 'FINISHED', child: Text('Finished')),
                    DropdownMenuItem(
                        value: 'ANNOUNCED', child: Text('Announced')),
                    DropdownMenuItem(
                        value: 'CANCELLED', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'PAUSADO', child: Text('Paused')),
                    DropdownMenuItem(
                        value: 'AVAILABLE', child: Text('Available')),
                  ],
                  onChanged: (v) =>
                      setState(() => _estadoPublicacionSeleccionado = v),
                  decoration: getCommonDecoration('Availability (Optional)'),
                ),
                const SizedBox(height: 32),

                // Botón Enviar
                FilledButton(
                  onPressed: _isLoading ? null : _submitPropuesta,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l10n.proposalFormSubmitButton,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
