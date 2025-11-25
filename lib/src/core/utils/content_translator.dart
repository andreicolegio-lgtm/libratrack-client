import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

class ContentTranslator {
  static String translateType(BuildContext context, String backendKey) {
    switch (backendKey) {
      case 'Anime':
        return AppLocalizations.of(context)!.typeAnime;
      case 'Movie':
        return AppLocalizations.of(context)!.typeMovie;
      case 'Video Game':
        return AppLocalizations.of(context)!.typeVideoGame;
      case 'Manga':
        return AppLocalizations.of(context)!.typeManga;
      case 'Manhwa':
        return AppLocalizations.of(context)!.typeManhwa;
      case 'Book':
        return AppLocalizations.of(context)!.typeBook;
      case 'Series':
        return AppLocalizations.of(context)!.typeSeries;
      default:
        return backendKey;
    }
  }

  static String translateGenre(BuildContext context, String backendKey) {
    switch (backendKey) {
      case 'Action':
        return AppLocalizations.of(context)!.genreAction;
      case 'Adventure':
        return AppLocalizations.of(context)!.genreAdventure;
      case 'Comedy':
        return AppLocalizations.of(context)!.genreComedy;
      case 'Drama':
        return AppLocalizations.of(context)!.genreDrama;
      case 'Fantasy':
        return AppLocalizations.of(context)!.genreFantasy;
      case 'Horror':
        return AppLocalizations.of(context)!.genreHorror;
      case 'Mystery':
        return AppLocalizations.of(context)!.genreMystery;
      case 'Romance':
        return AppLocalizations.of(context)!.genreRomance;
      case 'Sci-Fi':
        return AppLocalizations.of(context)!.genreSciFi;
      case 'Slice of Life':
        return AppLocalizations.of(context)!.genreSliceOfLife;
      case 'Psychological':
        return AppLocalizations.of(context)!.genrePsychological;
      case 'Thriller':
        return AppLocalizations.of(context)!.genreThriller;
      case 'Historical':
        return AppLocalizations.of(context)!.genreHistorical;
      case 'Crime':
        return AppLocalizations.of(context)!.genreCrime;
      case 'Family':
        return AppLocalizations.of(context)!.genreFamily;
      case 'War':
        return AppLocalizations.of(context)!.genreWar;
      case 'Cyberpunk':
        return AppLocalizations.of(context)!.genreCyberpunk;
      case 'Post-Apocalyptic':
        return AppLocalizations.of(context)!.genrePostApocalyptic;
      case 'Shonen':
        return AppLocalizations.of(context)!.genreShonen;
      case 'Shojo':
        return AppLocalizations.of(context)!.genreShojo;
      case 'Seinen':
        return AppLocalizations.of(context)!.genreSeinen;
      case 'Josei':
        return AppLocalizations.of(context)!.genreJosei;
      case 'Isekai':
        return AppLocalizations.of(context)!.genreIsekai;
      case 'Mecha':
        return AppLocalizations.of(context)!.genreMecha;
      case 'Harem':
        return AppLocalizations.of(context)!.genreHarem;
      case 'Ecchi':
        return AppLocalizations.of(context)!.genreEcchi;
      case 'Yaoi':
        return AppLocalizations.of(context)!.genreYaoi;
      case 'Yuri':
        return AppLocalizations.of(context)!.genreYuri;
      case 'Martial Arts':
        return AppLocalizations.of(context)!.genreMartialArts;
      case 'School':
        return AppLocalizations.of(context)!.genreSchool;
      case 'RPG':
        return AppLocalizations.of(context)!.genreRPG;
      case 'Shooter':
        return AppLocalizations.of(context)!.genreShooter;
      case 'Platformer':
        return AppLocalizations.of(context)!.genrePlatformer;
      case 'Strategy':
        return AppLocalizations.of(context)!.genreStrategy;
      case 'Puzzle':
        return AppLocalizations.of(context)!.genrePuzzle;
      case 'Fighting':
        return AppLocalizations.of(context)!.genreFighting;
      case 'Sports':
        return AppLocalizations.of(context)!.genreSports;
      case 'Racing':
        return AppLocalizations.of(context)!.genreRacing;
      case 'Open World':
        return AppLocalizations.of(context)!.genreOpenWorld;
      case 'Roguelike':
        return AppLocalizations.of(context)!.genreRoguelike;
      case 'MOBA':
        return AppLocalizations.of(context)!.genreMOBA;
      case 'Battle Royale':
        return AppLocalizations.of(context)!.genreBattleRoyale;
      case 'Simulator':
        return AppLocalizations.of(context)!.genreSimulator;
      case 'Survival Horror':
        return AppLocalizations.of(context)!.genreSurvivalHorror;
      case 'Biography':
        return AppLocalizations.of(context)!.genreBiography;
      case 'Essay':
        return AppLocalizations.of(context)!.genreEssay;
      case 'Poetry':
        return AppLocalizations.of(context)!.genrePoetry;
      case 'Self-Help':
        return AppLocalizations.of(context)!.genreSelfHelp;
      case 'Business':
        return AppLocalizations.of(context)!.genreBusiness;
      case 'Noir':
        return AppLocalizations.of(context)!.genreNoir;
      case 'Magical Realism':
        return AppLocalizations.of(context)!.genreMagicalRealism;
      default:
        return backendKey;
    }
  }
}
