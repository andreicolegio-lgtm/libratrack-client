import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/resena.dart';

class ResenaService with ChangeNotifier {
  final ApiClient _apiClient;
  ResenaService(this._apiClient);

  Future<List<Resena>> getResenas(int elementoId) async {
    try {
      final List<dynamic> data =
          await _apiClient.get('resenas/elemento/${elementoId.toString()}');
      return data.map((item) => Resena.fromJson(item)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar las reseñas: ${e.toString()}');
    }
  }

  Future<Resena> crearResena(
      {required int elementoId,
      required int valoracion,
      String? textoResena}) async {
    try {
      final Map<String, Object?> body = <String, Object?>{
        'elementoId': elementoId,
        'valoracion': valoracion,
        'textoResena': textoResena,
      };

      final data = await _apiClient.post('resenas', body);
      return Resena.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al publicar la reseña: ${e.toString()}');
    }
  }
}
