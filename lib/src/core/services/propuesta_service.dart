import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/propuesta.dart';

class PropuestaService with ChangeNotifier {
  final ApiClient _apiClient;
  PropuestaService(this._apiClient);

  Future<Propuesta> crearPropuesta(Map<String, dynamic> body) async {
    try {
      final data = await _apiClient.post('propuestas', body);
      return Propuesta.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al enviar la propuesta: ${e.toString()}');
    }
  }
}
