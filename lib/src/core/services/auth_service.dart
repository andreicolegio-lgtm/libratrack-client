import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/perfil_usuario.dart';

class GoogleSignInCanceledException implements Exception {
  const GoogleSignInCanceledException();
  @override
  String toString() => 'GoogleSignInCanceledException';
}

const String _accessTokenKey = 'jwt_access_token';
const String _refreshTokenKey = 'jwt_refresh_token';

class AuthService with ChangeNotifier {
  Future<void> logout({bool shouldNotify = true}) async {
    _accessToken = null;
    _refreshToken = null;
    _perfilUsuario = null;
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    if (shouldNotify) {
      notifyListeners();
    }
  }

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  late final GoogleSignIn _googleSignIn;

  String? _accessToken;
  String? _refreshToken;
  PerfilUsuario? _perfilUsuario;
  bool _isLoading = true;

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
        serverClientId:
            '1078651925823-g53s0f6i4on4ugdc0t7pfg11vpu86rdp.apps.googleusercontent.com',
      );
      await _tryAutoLogin();
    } catch (e) {
      debugPrint('❌ Error durante inicialización: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _tryAutoLogin() async {
    try {
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      debugPrint(
          '🔐 Auto-login: accessToken=${_accessToken != null ? "✅" : "❌"}, refreshToken=${_refreshToken != null ? "✅" : "❌"}');

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
      if (shouldNotify) {
        notifyListeners();
      }
    } on UnauthorizedException catch (e) {
      debugPrint('❌ UnauthorizedException en _loadUserProfile: ${e.message}');
      await logout(shouldNotify: shouldNotify);
    } catch (e) {
      debugPrint('❌ Error en _loadUserProfile: $e');
      await logout(shouldNotify: shouldNotify);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final data = await _apiClient.post(
          'auth/login',
          <String, dynamic>{
            'email': email,
            'password': password,
          },
          isAuthEndpoint: true);

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

  Future<void> signInWithGoogle(BuildContext? context) async {
    try {
      final user = await _googleSignIn.authenticate();
      debugPrint('✅ Google Sign-In exitoso: ${user.email}');

      final googleAuth = user.authentication;
      final String? idToken = googleAuth.idToken;
      debugPrint(
          '🔑 ID Token obtenido: ${idToken?.substring(0, 20) ?? "null"}...');

      if (idToken == null) {
        throw ApiException('No se pudo obtener el token de Google.');
      }

      debugPrint('📤 Enviando token a /auth/google...');
      debugPrint('📦 Payload: {"token": "${idToken.substring(0, 50)}..."}');
      final data = await _apiClient.post(
          'auth/google',
          <String, dynamic>{
            'token': idToken,
          },
          isAuthEndpoint: true);
      debugPrint('✅ Backend respondió correctamente');

      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];

      await _secureStorage.write(key: _accessTokenKey, value: _accessToken!);
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken!);

      await _loadUserProfile(shouldNotify: false);

      notifyListeners();
    } on GoogleSignInCanceledException {
      rethrow;
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('canceled') || message.contains('cancelled')) {
        debugPrint('ℹ️ Google Sign-In cancelado por el usuario');
        throw const GoogleSignInCanceledException();
      }
      debugPrint('❌ Error inesperado: $e');
      throw ApiException(
          'Error inesperado durante el inicio de sesión con Google: ${e.toString()}');
    }
  }

  Future<PerfilUsuario> register(
      String username, String email, String password) async {
    try {
      final data = await _apiClient.post(
          'auth/register',
          <String, dynamic>{
            'username': username,
            'email': email,
            'password': password,
          },
          isAuthEndpoint: true);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  void updateLocalProfileData(PerfilUsuario perfilActualizado) {
    _perfilUsuario = perfilActualizado;
    notifyListeners();
  }
}
