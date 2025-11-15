// Archivo: lib/src/core/services/auth_service.dart
// (¡LINTER CORREGIDO!)

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';

// --- ¡CORREGIDO (LINTER)! ---
const String _accessTokenKey = 'jwt_access_token';
const String _refreshTokenKey = 'jwt_refresh_token';
// ---

class AuthService with ChangeNotifier {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  // Estado en memoria
  String? _accessToken;
  String? _refreshToken;
  PerfilUsuario? _perfilUsuario;
  bool _isLoading = true;

  String? get token => _accessToken;
  PerfilUsuario? get perfilUsuario => _perfilUsuario;
  bool get isAuthenticated => _accessToken != null && _perfilUsuario != null;
  bool get isLoading => _isLoading;

  AuthService(this._apiClient, this._secureStorage) {
    _tryAutoLogin();
  }

  /// Intenta cargar tokens desde el almacenamiento seguro al iniciar la app.
  Future<void> _tryAutoLogin() async {
    try {
      // 1. Intentamos leer ambos tokens
      // --- ¡CORREGIDO (LINTER)! ---
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      // ---

      if (_accessToken != null && _refreshToken != null) {
        // 2. Si existen, cargamos el perfil
        await _loadUserProfile(shouldNotify: false);
      } else {
        // 3. Si falta alguno, limpiamos todo
        await logout(shouldNotify: false);
      }
    } catch (e) {
      // 4. Si algo falla (ej. storage corrupto), limpiamos todo
      await logout(shouldNotify: false);
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  /// Carga el perfil del usuario desde la API (/api/usuarios/me)
  Future<void> _loadUserProfile({bool shouldNotify = true}) async {
    try {
      // --- ¡CORREGIDO (ID: QA-078)! ---
      // get() por defecto NO es un auth endpoint, lo cual es correcto.
      final data = await _apiClient.get('usuarios/me');
      _perfilUsuario = PerfilUsuario.fromJson(data);
      if (shouldNotify) notifyListeners();
    } on UnauthorizedException {
      await logout(shouldNotify: shouldNotify);
    } catch (e) {
      await logout(shouldNotify: shouldNotify);
    }
  }

  /// Inicia sesión (Login)
  Future<void> login(String email, String password) async {
    try {
      // --- ¡CORREGIDO (ID: QA-078)! ---
      // Le decimos al ApiClient que esta es una llamada de autenticación
      // para que no intente refrescar si falla.
      final data = await _apiClient.post('auth/login', {
        'email': email,
        'password': password,
      }, isAuthEndpoint: true); // <-- AÑADIDO
      // ---

      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];

      await _secureStorage.write(key: _accessTokenKey, value: _accessToken!);
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken!);
      
      await _loadUserProfile(shouldNotify: false);
      
      notifyListeners();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  /// Cierra la sesión
  Future<void> logout({bool shouldNotify = true}) async {
    try {
      await _apiClient.logout();
    } catch (e) {
      // --- ¡CORREGIDO (LINTER)! ---
      // Se elimina el print()
      // print("Error during API logout, proceeding with local cleanup: $e");
      // ---
    }

    _accessToken = null;
    _refreshToken = null;
    _perfilUsuario = null;
    
    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Registra un nuevo usuario
  Future<PerfilUsuario> register(
      String username, String email, String password) async {
    try {
      // --- ¡CORREGIDO (ID: QA-078)! ---
      // Le decimos al ApiClient que esta es una llamada de autenticación
      final data = await _apiClient.post('auth/register', {
        'username': username,
        'email': email,
        'password': password,
      }, isAuthEndpoint: true); // <-- AÑADIDO
      // ---
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  // --- ¡NUEVO MÉTODO (ID: QA-079)! ---
  /// Actualiza la copia local del perfil de usuario.
  /// Llamado desde ProfileScreen después de una actualización exitosa
  /// (ej. cambio de nombre, cambio de foto) para mantener el estado sincronizado.
  void updateLocalProfileData(PerfilUsuario perfilActualizado) {
    _perfilUsuario = perfilActualizado;
    // Notificamos a cualquier widget que pueda estar escuchando el perfil
    // (aunque en ProfileScreen no es estrictamente necesario, es buena práctica).
    notifyListeners();
  }
}