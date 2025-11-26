import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/environment_config.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/perfil_usuario.dart';

/// Excepción específica para cuando el usuario cancela el flujo de Google.
class GoogleSignInCanceledException implements Exception {
  const GoogleSignInCanceledException();
  @override
  String toString() => 'El usuario canceló el inicio de sesión con Google.';
}

const String _accessTokenKey = 'jwt_access_token';
const String _refreshTokenKey = 'jwt_refresh_token';

class AuthService with ChangeNotifier {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  late final GoogleSignIn _googleSignIn;

  // Estado interno
  String? _accessToken;
  String? _refreshToken;
  PerfilUsuario? _perfilUsuario;
  bool _isLoading = true;

  // Getters públicos
  String? get token => _accessToken;
  PerfilUsuario? get perfilUsuario => _perfilUsuario;
  bool get isAuthenticated => _accessToken != null && _perfilUsuario != null;
  bool get isLoading => _isLoading;

  AuthService(this._apiClient, this._secureStorage) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _googleSignIn = GoogleSignIn.instance;
      await _googleSignIn.initialize(
        serverClientId: EnvironmentConfig.googleWebClientId,
      );
      await _tryAutoLogin();
    } catch (e) {
      debugPrint('❌ Error crítico en inicialización de Auth: $e');
      // En caso de error grave, aseguramos que la app no se quede en splash infinito
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Intenta restaurar la sesión desde el almacenamiento seguro.
  Future<void> _tryAutoLogin() async {
    try {
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (_accessToken != null && _refreshToken != null) {
        debugPrint('🔐 Tokens encontrados. Cargando perfil...');
        // Intentamos cargar el perfil. Si el token es inválido, _loadUserProfile
        // lanzará excepción y forzará logout.
        await _loadUserProfile(shouldNotify: false);
      } else {
        debugPrint('⚠️ No hay sesión guardada.');
        await logout(shouldNotify: false);
      }
    } catch (e) {
      debugPrint('❌ Fallo en auto-login: $e');
      await logout(shouldNotify: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene los datos actualizados del usuario desde la API.
  Future<void> _loadUserProfile({bool shouldNotify = true}) async {
    try {
      final data = await _apiClient.get('usuarios/me');
      _perfilUsuario = PerfilUsuario.fromJson(data);
      debugPrint('✅ Perfil cargado: ${_perfilUsuario?.username}');
      if (shouldNotify) {
        notifyListeners();
      }
    } catch (e) {
      // Si falla la carga del perfil (ej. 401 persistente), limpiamos todo.
      debugPrint('❌ Error cargando perfil: $e');
      throw UnauthorizedException('Sesión inválida.');
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<void> login(String email, String password) async {
    try {
      final data = await _apiClient.post(
        'auth/login',
        {'email': email, 'password': password},
        isAuthEndpoint: true,
      );

      await _saveTokens(data['accessToken'], data['refreshToken']);
      await _loadUserProfile(shouldNotify: false);
      notifyListeners();
    } catch (e) {
      // Propagamos la excepción tal cual para que la UI muestre el mensaje correcto
      rethrow;
    }
  }

  /// Registra un nuevo usuario.
  Future<void> register(String username, String email, String password) async {
    try {
      // 1. Registrar
      await _apiClient.post(
        'auth/register',
        {'username': username, 'email': email, 'password': password},
        isAuthEndpoint: true,
      );

      // 2. Auto-login inmediato tras registro exitoso
      await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  /// Inicia sesión con Google Identity Services.
  Future<void> signInWithGoogle() async {
    try {
      // 1. Flujo nativo de Google
      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw ApiException(
            'No se pudo obtener el token de identidad de Google.');
      }

      // 2. Intercambio con nuestro Backend
      final data = await _apiClient.post(
        'auth/google',
        {'token': idToken},
        isAuthEndpoint: true,
      );

      await _saveTokens(data['accessToken'], data['refreshToken']);
      await _loadUserProfile(shouldNotify: false);
      notifyListeners();
    } catch (e) {
      if (e is GoogleSignInCanceledException || e is ApiException) {
        rethrow;
      }

      // Capturamos errores específicos de cancelación en Android/iOS si la librería los lanza diferente
      final msg = e.toString().toLowerCase();
      if (msg.contains('canceled') || msg.contains('cancelled')) {
        throw const GoogleSignInCanceledException();
      }

      throw ApiException('Error inesperado con Google: $e');
    }
  }

  /// Cierra la sesión del usuario.
  Future<void> logout({bool shouldNotify = true}) async {
    try {
      // Intentamos avisar al backend (best effort)
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token != null) {
        await _apiClient
            .post(
              'auth/logout',
              {'refreshToken': token},
              isAuthEndpoint: true,
            )
            .catchError((_) {}); // Ignoramos errores de red en logout
      }

      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error en proceso de logout: $e');
    } finally {
      // Limpieza local obligatoria
      _accessToken = null;
      _refreshToken = null;
      _perfilUsuario = null;

      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);

      if (shouldNotify) {
        notifyListeners();
      }
    }
  }

  /// Helper para guardar tokens y actualizar estado en memoria.
  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _secureStorage.write(key: _accessTokenKey, value: access);
    await _secureStorage.write(key: _refreshTokenKey, value: refresh);
  }

  /// Permite actualizar el perfil en memoria sin recargar de la red (ej. tras cambiar foto).
  void updateLocalProfileData(PerfilUsuario nuevoPerfil) {
    _perfilUsuario = nuevoPerfil;
    notifyListeners();
  }
}
