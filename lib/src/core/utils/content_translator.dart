import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// Utilidad para traducir claves de contenido (Tipos, Géneros) que vienen del backend
/// a los textos localizados de la aplicación.
class ContentTranslator {
  /// Traduce el nombre del Tipo de contenido (ej. "Anime" -> "Anime", "Movie" -> "Película").
  static String translateType(BuildContext context, String backendKey) {
    final l10n = AppLocalizations.of(context);

    switch (backendKey) {
      case 'Anime':
        return l10n.typeAnime;
      case 'Movie':
        return l10n.typeMovie;
      case 'Video Game':
        return l10n.typeVideoGame;
      case 'Manga':
        return l10n.typeManga;
      case 'Manhwa':
        return l10n.typeManhwa;
      case 'Book':
        return l10n.typeBook;
      case 'Series':
        return l10n.typeSeries;
      default:
        // Fallback: Devuelve la clave original si no hay traducción (ej. tipos nuevos)
        return backendKey;
    }
  }

  /// Traduce el nombre del Género (ej. "Action" -> "Acción").
  static String translateGenre(BuildContext context, String backendKey) {
    final l10n = AppLocalizations.of(context);

    switch (backendKey) {
      // Generales
      case 'Action':
        return l10n.genreAction;
      case 'Adventure':
        return l10n.genreAdventure;
      case 'Comedy':
        return l10n.genreComedy;
      case 'Drama':
        return l10n.genreDrama;
      case 'Fantasy':
        return l10n.genreFantasy;
      case 'Horror':
        return l10n.genreHorror;
      case 'Mystery':
        return l10n.genreMystery;
      case 'Romance':
        return l10n.genreRomance;
      case 'Sci-Fi':
        return l10n.genreSciFi;
      case 'Slice of Life':
        return l10n.genreSliceOfLife;
      case 'Psychological':
        return l10n.genrePsychological;
      case 'Thriller':
        return l10n.genreThriller;
      case 'Historical':
        return l10n.genreHistorical;
      case 'Crime':
        return l10n.genreCrime;
      case 'Family':
        return l10n.genreFamily;
      case 'War':
        return l10n.genreWar;
      case 'Cyberpunk':
        return l10n.genreCyberpunk;
      case 'Post-Apocalyptic':
        return l10n.genrePostApocalyptic;

      // Asiáticos / Anime
      case 'Shonen':
        return l10n.genreShonen;
      case 'Shojo':
        return l10n.genreShojo;
      case 'Seinen':
        return l10n.genreSeinen;
      case 'Josei':
        return l10n.genreJosei;
      case 'Isekai':
        return l10n.genreIsekai;
      case 'Mecha':
        return l10n.genreMecha;
      case 'Harem':
        return l10n.genreHarem;
      case 'Ecchi':
        return l10n.genreEcchi;
      case 'Yaoi':
        return l10n.genreYaoi;
      case 'Yuri':
        return l10n.genreYuri;
      case 'Martial Arts':
        return l10n.genreMartialArts;
      case 'School':
        return l10n.genreSchool;

      // Gaming
      case 'RPG':
        return l10n.genreRPG;
      case 'Shooter':
        return l10n.genreShooter;
      case 'Platformer':
        return l10n.genrePlatformer;
      case 'Strategy':
        return l10n.genreStrategy;
      case 'Puzzle':
        return l10n.genrePuzzle;
      case 'Fighting':
        return l10n.genreFighting;
      case 'Sports':
        return l10n.genreSports;
      case 'Racing':
        return l10n.genreRacing;
      case 'Open World':
        return l10n.genreOpenWorld;
      case 'Roguelike':
        return l10n.genreRoguelike;
      case 'MOBA':
        return l10n.genreMOBA;
      case 'Battle Royale':
        return l10n.genreBattleRoyale;
      case 'Simulator':
        return l10n.genreSimulator;
      case 'Survival Horror':
        return l10n.genreSurvivalHorror;

      // Literarios
      case 'Biography':
        return l10n.genreBiography;
      case 'Essay':
        return l10n.genreEssay;
      case 'Poetry':
        return l10n.genrePoetry;
      case 'Self-Help':
        return l10n.genreSelfHelp;
      case 'Business':
        return l10n.genreBusiness;
      case 'Noir':
        return l10n.genreNoir;
      case 'Magical Realism':
        return l10n.genreMagicalRealism;

      default:
        return backendKey;
    }
  }
}
