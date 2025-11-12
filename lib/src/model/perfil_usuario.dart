// lib/src/model/perfil_usuario.dart

/// Corresponde al 'UsuarioResponseDTO' del backend.
/// --- ¡ACTUALIZADO (Sprint 3)! ---
class PerfilUsuario {
  final int id;
  final String username;
  final String email;
  final String rol; 
  final String? fotoPerfilUrl; // <-- ¡NUEVO CAMPO!

  // Constructor
  PerfilUsuario({
    required this.id,
    required this.username,
    required this.email,
    required this.rol,
    this.fotoPerfilUrl, // <-- ¡NUEVO CAMPO!
  });

  /// "Constructor de fábrica"
  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      rol: json['rol'],
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?, // <-- ¡NUEVO MAPEO!
    );
  }
}