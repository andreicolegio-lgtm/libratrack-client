// Archivo: lib/src/core/services/catalog_service.dart
// (¡REFACTORIZADO! Acepta 'int' para IDs y corrige el bug de 'removeWhere')

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';

class CatalogService with ChangeNotifier {
  final ApiClient _apiClient;
  CatalogService(this._apiClient);

  List<CatalogoEntrada> _entradas = [];
  bool _isLoading = true;

  List<CatalogoEntrada> get entradas => _entradas;
  bool get isLoading => _isLoading;

  /// Obtiene el catálogo completo del usuario.
  Future<void> fetchCatalog() async {
    try {
      _isLoading = true;

      final List<dynamic> data = await _apiClient.get('catalogo');
      _entradas = data.map((item) => CatalogoEntrada.fromJson(item)).toList();
    } on ApiException {
      _entradas = [];
      rethrow;
    } catch (e) {
      _entradas = [];
      throw ApiException('Error al cargar el catálogo: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Añade un elemento al catálogo.
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<void> addElemento(int elementoId) async {
    try {
      // Convierte a String en el último momento
      final data = await _apiClient.post('catalogo/elementos/${elementoId.toString()}', {});

      final nuevaEntrada = CatalogoEntrada.fromJson(data);
      _entradas.add(nuevaEntrada);
      notifyListeners();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al añadir elemento: ${e.toString()}');
    }
  }

  /// Elimina un elemento del catálogo.
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<void> removeElemento(int elementoId) async {
    try {
      // Convierte a String en el último momento
      await _apiClient.delete('catalogo/elementos/${elementoId.toString()}');

      // --- ¡CORREGIDO (ID: QA-048)! ---
      // Ahora es una comparación limpia de int == int
      _entradas.removeWhere((entrada) => entrada.elementoId == elementoId);
      // ---
      notifyListeners();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al eliminar elemento: ${e.toString()}');
    }
  }

  /// Actualiza el progreso de una entrada del catálogo.
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<void> updateProgreso(int elementoId, Map<String, dynamic> body) async {
    try {
      // Convierte a String en el último momento
      final data = await _apiClient.put('catalogo/elementos/${elementoId.toString()}', body);

      final entradaActualizada = CatalogoEntrada.fromJson(data);
      _actualizarEntradaEnLista(entradaActualizada);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el progreso: ${e.toString()}');
    }
  }

  /// Actualiza solo el estado de una entrada del catálogo.
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<void> updateEstado(int elementoId, String estado) async {
    try {
      final Map<String, dynamic> body = {'estadoPersonal': estado};
      // Convierte a String en el último momento
      final data = await _apiClient.put('catalogo/elementos/${elementoId.toString()}', body);

      final entradaActualizada = CatalogoEntrada.fromJson(data);
      _actualizarEntradaEnLista(entradaActualizada);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el estado: ${e.toString()}');
    }
  }

  /// Helper interno para actualizar la lista local sin recargar todo.
  void _actualizarEntradaEnLista(CatalogoEntrada entradaActualizada) {
    final index =
        _entradas.indexWhere((entrada) => entrada.id == entradaActualizada.id);
    if (index != -1) {
      _entradas[index] = entradaActualizada;
      notifyListeners();
    }
  }
}