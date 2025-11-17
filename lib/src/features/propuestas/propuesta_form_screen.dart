import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/propuesta_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/utils/error_translator.dart';

class PropuestaFormScreen extends StatefulWidget {
  const PropuestaFormScreen({super.key});

  @override
  State<PropuestaFormScreen> createState() => _PropuestaFormScreenState();
}

class _PropuestaFormScreenState extends State<PropuestaFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _generosController = TextEditingController();

  final TextEditingController _episodiosPorTemporadaController =
      TextEditingController();
  final TextEditingController _totalUnidadesController =
      TextEditingController();
  final TextEditingController _totalCapitulosLibroController =
      TextEditingController();
  final TextEditingController _totalPaginasLibroController =
      TextEditingController();

  String _tipoSeleccionado = '';

  @override
  void initState() {
    super.initState();
    _tipoController.addListener(_actualizarCamposDinamicos);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tipoController.removeListener(_actualizarCamposDinamicos);
    _tipoController.dispose();
    _generosController.dispose();
    _episodiosPorTemporadaController.dispose();
    _totalUnidadesController.dispose();
    _totalCapitulosLibroController.dispose();
    _totalPaginasLibroController.dispose();
    super.dispose();
  }

  void _actualizarCamposDinamicos() {
    setState(() {
      _tipoSeleccionado = _tipoController.text.trim().toLowerCase();
    });
  }

  Future<void> _submitPropuesta() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);
    final NavigatorState navContext = Navigator.of(context);

    final PropuestaService propuestaService = context.read<PropuestaService>();

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'tituloSugerido': _tituloController.text,
        'descripcionSugerida': _descripcionController.text,
        'tipoSugerido': _tipoController.text,
        'generosSugeridos': _generosController.text,
        'episodiosPorTemporada': _episodiosPorTemporadaController.text.isEmpty
            ? null
            : _episodiosPorTemporadaController.text,
        'totalUnidades': _totalUnidadesController.text.isEmpty
            ? null
            : int.tryParse(_totalUnidadesController.text),
        'totalCapitulosLibro': _totalCapitulosLibroController.text.isEmpty
            ? null
            : int.tryParse(_totalCapitulosLibroController.text),
        'totalPaginasLibro': _totalPaginasLibroController.text.isEmpty
            ? null
            : int.tryParse(_totalPaginasLibroController.text),
      };
      body.removeWhere((String key, value) => value == null);

      await propuestaService.crearPropuesta(body);

      if (!mounted) {
        return;
      }

      SnackBarHelper.showTopSnackBar(msgContext, l10n.snackbarProposalSent,
          isError: false);

      navContext.pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          msgContext,
          ErrorTranslator.translate(context, e.message),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showTopSnackBar(
          msgContext,
          l10n.errorUnexpected(e.toString()),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.proposalFormTitle,
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildInputField(
                context,
                l10n: l10n,
                controller: _tituloController,
                labelText: l10n.proposalFormTitleLabel,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _descripcionController,
                labelText: l10n.proposalFormDescLabel,
                maxLines: 4,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationDescRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _tipoController,
                labelText: l10n.proposalFormTypeLabel,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationTypeRequired
                    : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                l10n: l10n,
                controller: _generosController,
                labelText: l10n.proposalFormGenresLabel,
                validator: (String? value) => (value == null || value.isEmpty)
                    ? l10n.validationGenresRequired
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              Text(l10n.proposalFormProgressTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (_tipoSeleccionado == 'serie')
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _episodiosPorTemporadaController,
                  labelText: l10n.proposalFormSeriesEpisodesLabel,
                  hintText: l10n.proposalFormSeriesEpisodesHint,
                ),
              if (_tipoSeleccionado == 'libro') ...<Widget>[
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalCapitulosLibroController,
                  labelText: l10n.proposalFormBookChaptersLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalPaginasLibroController,
                  labelText: l10n.proposalFormBookPagesLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ],
              if (_tipoSeleccionado == 'anime' || _tipoSeleccionado == 'manga')
                _buildInputField(
                  context,
                  l10n: l10n,
                  controller: _totalUnidadesController,
                  labelText: _tipoSeleccionado == 'anime'
                      ? l10n.proposalFormAnimeEpisodesLabel
                      : l10n.proposalFormMangaChaptersLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              if (_tipoSeleccionado != 'serie' &&
                  _tipoSeleccionado != 'libro' &&
                  _tipoSeleccionado != 'anime' &&
                  _tipoSeleccionado != 'manga' &&
                  _tipoSeleccionado.isNotEmpty)
                Text(
                  l10n.proposalFormNoProgress(_tipoController.text),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isLoading ? null : _submitPropuesta,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        l10n.proposalFormSubmitButton,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey[600]),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
