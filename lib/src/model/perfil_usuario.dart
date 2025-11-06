// lib/src/model/perfil_usuario.dart

/// Modelo de datos para representar la información del perfil del usuario.
///
/// Corresponde al 'UsuarioResponseDTO' del backend de Spring Boot.
/// Usamos un modelo (clase) en lugar de un 'Map<`String, dynamic`>'
/// para asegurar la "seguridad de tipos" (type-safety) y evitar
/// errores al escribir mal el nombre de una clave (ej. "userName" vs "username").
class PerfilUsuario {
  final int id;
  final String username;
  final String email;
  final String rol; // ej. "ROLE_USUARIO" o "ROLE_MODERADOR"

  // Constructor
  PerfilUsuario({
    required this.id,
    required this.username,
    required this.email,
    required this.rol,
  });

  /// "Constructor de fábrica" (Factory Constructor) para crear una instancia
  /// de PerfilUsuario a partir del JSON (Map) decodificado de la API.
  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      rol: json['rol'],
    );
  }
}