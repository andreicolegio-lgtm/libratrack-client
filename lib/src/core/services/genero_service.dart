import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/genero.dart';

/// Servicio para gestionar la lista maestra de géneros.
/// Utiliza un patrón de caché en memoria para evitar peticiones redundantes.
class GeneroService with ChangeNotifier {
  final ApiClient _apiClient;
  GeneroService(this._apiClient);

  List<Genero>? _generos;

  /// Devuelve la lista actual en memoria (puede ser null si no se ha cargado).
  List<Genero>? get generos => _generos;

  /// Carga la lista de géneros desde el backend.
  /// Si ya están cargados en memoria, los devuelve inmediatamente sin llamar a la API.
  Future<List<Genero>> fetchGeneros() async {
    // Cache hit: devolver datos existentes
    if (_generos != null && _generos!.isNotEmpty) {
      return _generos!;
    }

    try {
      final dynamic response = await _apiClient.get('generos');

      // Validación de tipo segura
      final List<dynamic> data = response is List ? response : [];

      _generos = data
          .map((item) => Genero.fromJson(item as Map<String, dynamic>))
          .toList();

      notifyListeners();
      return _generos!;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al cargar los géneros: $e');
    }
  }

  /// Fuerza la recarga de géneros (útil si un admin añade uno nuevo).
  Future<void> refresh() async {
    _generos = null;
    await fetchGeneros();
  }
}
