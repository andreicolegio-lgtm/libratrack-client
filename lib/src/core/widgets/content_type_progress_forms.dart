import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

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
    switch (selectedTypeKey) {
      case 'Anime':
        return _buildTextField(
          context,
          controller: unitsController,
          label: l10n.totalEpisodes,
        );
      case 'Movie':
        return _buildTextField(
          context,
          controller: durationController,
          label: l10n.duration,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
          ],
          hintText: 'HH:mm:ss',
        );
      case 'Manga':
      case 'Manhwa':
        return _buildTextField(
          context,
          controller: chaptersController,
          label: l10n.totalChapters,
        );
      case 'Book':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              context,
              controller: pagesController,
              label: l10n.totalPages,
            ),
            const SizedBox(height: 16.0),
            _buildTextField(
              context,
              controller: chaptersController,
              label: l10n.totalChapters,
            ),
          ],
        );
      case 'Series':
        return _buildTextField(
          context,
          controller: episodesController,
          label: l10n.episodesPerSeason,
          hintText: '10, 12, 13',
        );
      case 'Video Game':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
