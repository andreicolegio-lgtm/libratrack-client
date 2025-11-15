// Archivo: lib/src/core/services/auth_service.dart
// (¡CORREGIDO - ID: QA-091!)

// import 'dart:convert'; // <-- ¡ELIMINADO!
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart'; 

import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';

// --- ¡CORREGIDO (Linter)! ---
const String _accessTokenKey = 'jwt_access_token';
const String _refreshTokenKey = 'jwt_refresh_token';
// ---

class AuthService with ChangeNotifier {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  // --- ¡CORRECCIÓN (ID: QA-091)! ---
  // Usar GoogleSignIn.instance (singleton) en lugar de crear una nueva instancia
  late final GoogleSignIn _googleSignIn;
  // ---

  String? _accessToken;
  String? _refreshToken;
  PerfilUsuario? _perfilUsuario;
  bool _isLoading = true;

  String? get token => _accessToken;
  PerfilUsuario? get perfilUsuario => _perfilUsuario;
  bool get isAuthenticated => _accessToken != null && _perfilUsuario != null;
  bool get isLoading => _isLoading;

  AuthService(this._apiClient, this._secureStorage) {
    // Inicialización asíncrona sin esperar (fire and forget)
    _initialize();
  }

  /// Inicialización asíncrona del servicio
  Future<void> _initialize() async {
    try {
      await _initializeGoogleSignIn();
      await _tryAutoLogin();
    } catch (e) {
      debugPrint('❌ Error durante inicialización: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicializa GoogleSignIn de forma segura
  Future<void> _initializeGoogleSignIn() async {
    _googleSignIn = GoogleSignIn.instance;
    // Inicializar con el serverClientId necesario para Android
    await _googleSignIn.initialize(
      serverClientId: '1078651925823-g53s0f6i4on4ugdc0t7pfg11vpu86rdp.apps.googleusercontent.com', // Reemplaza con tu Server Client ID de Google Cloud
    );
  }

  Future<void> _tryAutoLogin() async {
    try {
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      
      debugPrint('🔐 Auto-login: accessToken=${_accessToken != null ? "✅" : "❌"}, refreshToken=${_refreshToken != null ? "✅" : "❌"}');

      if (_accessToken != null && _refreshToken != null) {
        await _loadUserProfile(shouldNotify: false);
      } else {
        debugPrint('⚠️ No hay tokens guardados, cerrando sesión');
        await logout(shouldNotify: false);
      }
    } catch (e) {
      debugPrint('❌ Error en auto-login: $e');
      await logout(shouldNotify: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile({bool shouldNotify = true}) async {
    try {
      debugPrint('📥 Cargando perfil de usuario desde /usuarios/me...');
      final data = await _apiClient.get('usuarios/me');
      _perfilUsuario = PerfilUsuario.fromJson(data);
      debugPrint('✅ Perfil cargado: ${_perfilUsuario?.username}');
      if (shouldNotify) notifyListeners();
    } on UnauthorizedException catch (e) {
      debugPrint('❌ UnauthorizedException en _loadUserProfile: ${e.message}');
      await logout(shouldNotify: shouldNotify);
    } catch (e) {
      debugPrint('❌ Error en _loadUserProfile: $e');
      await logout(shouldNotify: shouldNotify);
    }
  }

  /// Inicia sesión con Email y Contraseña
  Future<void> login(String email, String password) async {
    try {
      final data = await _apiClient.post('auth/login', {
        'email': email,
        'password': password,
      }, isAuthEndpoint: true); 

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

  // --- ¡MÉTODO CORREGIDO (ID: QA-091)! ---
  /// Inicia sesión o se registra usando Google
  Future<void> signInWithGoogle() async {
    try {
      // 1. Mostrar el Pop-up de Google
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      debugPrint('✅ Google Sign-In exitoso: ${googleUser.email}');

      // 2. Si el usuario cierra el pop-up, authenticate() retorna null implícitamente
      // (pero el tipo es no-nullable, así que siempre tendremos un usuario válido aquí)

      // 3. Obtener el token de ID de Google
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      debugPrint('🔑 ID Token obtenido: ${idToken?.substring(0, 20) ?? "null"}...');

      if (idToken == null) {
        throw ApiException('No se pudo obtener el token de Google.');
      }

      // 4. Enviar el token de Google a NUESTRO backend
      debugPrint('📤 Enviando token a /auth/google...');
      debugPrint('📦 Payload: {"token": "${idToken.substring(0, 50)}..."}');
      final data = await _apiClient.post('auth/google', {
        'token': idToken,
      }, isAuthEndpoint: true);
      debugPrint('✅ Backend respondió correctamente');

      // 5. Recibir NUESTROS propios tokens (Access y Refresh)
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];

      // 6. Guardar nuestros tokens
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken!);
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken!);
      
      // 7. Cargar el perfil del usuario (desde nuestra BD)
      await _loadUserProfile(shouldNotify: false);
      
      // 8. Notificar a la UI para navegar a Home
      notifyListeners();

    } on ApiException catch (e) {
      debugPrint('❌ ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      throw ApiException('Error inesperado durante el inicio de sesión con Google: ${e.toString()}');
    }
  }
  // ---

  /// Cierra la sesión
  Future<void> logout({bool shouldNotify = true}) async {
    try {
      await _googleSignIn.signOut();
      await _apiClient.logout();
    } catch (e) {
      // Ignoramos errores aquí
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
      final data = await _apiClient.post('auth/register', {
        'username': username,
        'email': email,
        'password': password,
      }, isAuthEndpoint: true);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  /// (ID: QA-079) Actualiza la copia local del perfil de usuario
  void updateLocalProfileData(PerfilUsuario perfilActualizado) {
    _perfilUsuario = perfilActualizado;
    notifyListeners();
  }
}