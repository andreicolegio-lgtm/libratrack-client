// Archivo: lib/src/core/services/genero_service.dart
// (¡REFACTORIZADO!)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/genero.dart';

class GeneroService with ChangeNotifier {
  // --- ¡MODIFICADO! ---
  final ApiClient _apiClient;
  GeneroService(this._apiClient);
  // ---

  List<Genero>? _generos;
  List<Genero>? get generos => _generos;

  /// Obtiene la lista de géneros (para filtros y formularios).
  Future<List<Genero>> fetchGeneros() async {
    // Si ya los tenemos, los devolvemos (cache simple)
    if (_generos != null) return _generos!;

    try {
      // ¡Lógica simplificada!
      final List<dynamic> data = await _apiClient.get('generos');

      _generos = data.map((item) => Genero.fromJson(item)).toList();
      notifyListeners();
      return _generos!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar los géneros: ${e.toString()}');
    }
  }
}