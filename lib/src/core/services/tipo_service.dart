// Archivo: lib/src/core/services/tipo_service.dart
// (¡REFACTORIZADO!)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/tipo.dart';

class TipoService with ChangeNotifier {
  // --- ¡MODIFICADO! ---
  final ApiClient _apiClient;
  TipoService(this._apiClient);
  // ---

  List<Tipo>? _tipos;
  List<Tipo>? get tipos => _tipos;

  /// Obtiene la lista de tipos (para filtros y formularios).
  Future<List<Tipo>> fetchTipos() async {
    // Cache simple
    if (_tipos != null) return _tipos!;

    try {
      // ¡Lógica simplificada!
      final List<dynamic> data = await _apiClient.get('tipos');
      
      _tipos = data.map((item) => Tipo.fromJson(item)).toList();
      notifyListeners();
      return _tipos!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar los tipos: ${e.toString()}');
    }
  }
}