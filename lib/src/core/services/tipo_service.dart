import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/tipo.dart';

/// Servicio para gestionar los Tipos de contenido (Anime, Libro, etc.).
/// Los tipos incluyen la lista de géneros válidos para cada uno.
class TipoService with ChangeNotifier {
  final ApiClient _apiClient;
  TipoService(this._apiClient);

  List<Tipo> _tipos = [];

  List<Tipo> get tipos => _tipos;

  /// Carga los tipos disponibles.
  /// Utiliza caché en memoria.
  Future<List<Tipo>> fetchTipos(String errorLoadingFilters) async {
    if (_tipos.isNotEmpty) {
      return _tipos;
    }

    try {
      final dynamic response = await _apiClient.get('tipos');

      final List<dynamic> data = response is List ? response : [];

      _tipos = data
          .map((item) => Tipo.fromJson(item as Map<String, dynamic>))
          .toList();

      notifyListeners();
      return _tipos;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al cargar los tipos de contenido: $e');
    }
  }
}
