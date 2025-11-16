import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/tipo.dart';

class TipoService with ChangeNotifier {
  final ApiClient _apiClient;
  TipoService(this._apiClient);

  List<Tipo>? _tipos;
  List<Tipo>? get tipos => _tipos;

  Future<List<Tipo>> fetchTipos() async {
    if (_tipos != null) {
      return _tipos!;
    }

    try {
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
