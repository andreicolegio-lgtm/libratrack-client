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

  // Controladores
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
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
        });
      }
    } catch (e) {
      debugPrint('Error cargando tipos: $e');
      // Opcional: Mostrar error si es crítico, aunque el dropdown simplemente estará vacío
    }
  }

  Future<void> _submitPropuesta() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validación manual extra: Tipo requerido
    if (_tipoSeleccionado == null) {
      SnackBarHelper.showTopSnackBar(context, l10n.validationTypeRequired,
          isError: true);
      return;
    }

    // Validación manual extra: Géneros requeridos
    if (_generosController.text.trim().isEmpty) {
      SnackBarHelper.showTopSnackBar(context, l10n.validationGenresRequired,
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Guardar referencia al navegador antes del async
    final navigator = Navigator.of(context);
    final propuestaService = context.read<PropuestaService>();

    try {
      // Construir el cuerpo del request limpiando datos vacíos
      final Map<String, dynamic> body = {
        'tituloSugerido': _tituloController.text.trim(),
        'descripcionSugerida': _descripcionController.text.trim(),
        'tipoSugerido': _tipoSeleccionado,
        'generosSugeridos': _generosController.text.trim(),
        // La imagen es opcional y no se sube aquí en la propuesta inicial para simplificar,
        // pero se podría añadir un ImagePicker igual que en el perfil.

        // Datos opcionales de progreso
        'episodiosPorTemporada': _episodiosPorTemporadaController.text.isEmpty
            ? null
            : _episodiosPorTemporadaController.text.trim(),
        'totalUnidades': int.tryParse(_totalUnidadesController.text),
        'totalCapitulosLibro':
            int.tryParse(_totalCapitulosLibroController.text),
        'totalPaginasLibro': int.tryParse(_totalPaginasLibroController.text),
        'duracion': _durationController.text.isEmpty
            ? null
            : _durationController.text.trim(),
      };

      // Eliminar claves con valor null para que el backend reciba un JSON limpio
      body.removeWhere((key, value) => value == null);

      await propuestaService.crearPropuesta(body);

      if (!mounted) {
        return;
      }

      SnackBarHelper.showTopSnackBar(context, l10n.snackbarProposalSent,
          isError: false);
      navigator.pop(); // Volver a la pantalla anterior
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

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.proposalFormTitle,
            style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildInfoSection(l10n),
              const SizedBox(height: 24),
              _buildProgressSection(l10n),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                onPressed: _isLoading ? null : _submitPropuesta,
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
    );
  }

  Widget _buildInfoSection(AppLocalizations l10n) {
    return Column(
      children: [
        _buildInputField(
          controller: _tituloController,
          labelText: l10n.proposalFormTitleLabel,
          validator: (value) => (value == null || value.isEmpty)
              ? l10n.validationTitleRequired
              : null,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _descripcionController,
          labelText: l10n.proposalFormDescLabel,
          maxLines: 4,
          validator: (value) => (value == null || value.isEmpty)
              ? l10n.validationDescRequired
              : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _tipoSeleccionado,
          hint: Text(l10n.proposalFormTypeLabel),
          items: _tipos.map((tipo) {
            return DropdownMenuItem(
              value: tipo.nombre,
              child: Text(tipo.nombre),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _tipoSeleccionado = value;
            });
          },
          decoration: InputDecoration(
            labelText: l10n.proposalFormTypeLabel,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
        const SizedBox(height: 16),
        // Selector de Géneros
        GenreSelectorWidget(
          selectedTypes: _tipoSeleccionado != null
              ? [
                  _tipos.firstWhere((t) => t.nombre == _tipoSeleccionado,
                      orElse: () =>
                          const Tipo(id: 0, nombre: '', validGenres: []))
                ]
              : [],
          initialGenres: _generosController.text
              .split(',')
              .where((s) => s.isNotEmpty)
              .map((e) => e.trim())
              .toList(),
          onChanged: (updatedGenres) {
            setState(() {
              _generosController.text = updatedGenres.join(', ');
            });
          },
        ),
      ],
    );
  }

  Widget _buildProgressSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(l10n.proposalFormProgressTitle,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ContentTypeProgressForms(
          selectedTypeKey: _tipoSeleccionado,
          episodesController: _episodiosPorTemporadaController,
          chaptersController: _totalCapitulosLibroController,
          pagesController: _totalPaginasLibroController,
          durationController: _durationController,
          unitsController: _totalUnidadesController,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
