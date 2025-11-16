import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/elemento.dart';
import '../../model/propuesta.dart';

class ModeracionService with ChangeNotifier {
  final ApiClient _apiClient;
  ModeracionService(this._apiClient);

  Future<List<Propuesta>> fetchPropuestasPorEstado(String estado) async {
    try {
      final List<dynamic> data =
          await _apiClient.get('moderacion?estado=$estado');
      return data.map((item) => Propuesta.fromJson(item)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar las propuestas: ${e.toString()}');
    }
  }

  Future<Elemento> aprobarPropuesta(
      int propuestaId, Map<String, dynamic> body) async {
    try {
      final data = await _apiClient.post(
          'moderacion/aprobar/${propuestaId.toString()}', body);
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al aprobar la propuesta: ${e.toString()}');
    }
  }
}
