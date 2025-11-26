import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

/// Widget que muestra diferentes campos de formulario según el tipo de contenido seleccionado.
/// Por ejemplo, si es 'Libro' muestra páginas/capítulos, si es 'Serie' muestra temporadas.
class ContentTypeProgressForms extends StatelessWidget {
  final String? selectedTypeKey;
  final TextEditingController episodesController;
  final TextEditingController chaptersController;
  final TextEditingController pagesController;
  final TextEditingController durationController;
  final TextEditingController unitsController;
  final AppLocalizations l10n;

  const ContentTypeProgressForms({
    required this.selectedTypeKey,
    required this.episodesController,
    required this.chaptersController,
    required this.pagesController,
    required this.durationController,
    required this.unitsController,
    required this.l10n,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Normalización básica del tipo para el switch
    final type = selectedTypeKey;

    switch (type) {
      case 'Anime':
        return _buildTextField(
          context,
          controller: unitsController,
          label: l10n.elementDetailAnimeEpisodes, // 'Total Episodios'
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
        );

      case 'Movie':
        return _buildTextField(
          context,
          controller: durationController,
          label: l10n.duration,
          // Permite números y dos puntos para formato HH:mm
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))
          ],
          hintText: '120 min / 02:00',
        );

      case 'Manga':
      case 'Manhwa':
        return _buildTextField(
          context,
          controller: chaptersController,
          label: l10n.elementDetailMangaChapters, // 'Total Capítulos'
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
        );

      case 'Book':
        return Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                controller: pagesController,
                label: l10n.elementDetailBookPages, // 'Total Páginas'
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                context,
                controller: chaptersController,
                label: l10n.elementDetailBookChapters, // 'Total Capítulos'
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        );

      case 'Series':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              context,
              controller: episodesController,
              label: l10n.proposalFormSeriesEpisodesLabel,
              hintText: l10n.proposalFormSeriesEpisodesHint, // 'Ej. 10,8,12'
              // Permite dígitos y comas
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Introduce el número de episodios por temporada separados por comas.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        );

      case 'Video Game':
        return const SizedBox
            .shrink(); // Los juegos suelen tener % o horas, no implementado aún

      default:
        if (selectedTypeKey != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              l10n.proposalFormNoProgress(selectedTypeKey!),
              style: const TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
