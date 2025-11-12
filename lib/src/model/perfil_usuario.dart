// lib/src/model/perfil_usuario.dart

/// Corresponde al 'UsuarioResponseDTO' del backend.
/// --- ¡ACTUALIZADO (Sprint 4)! ---
class PerfilUsuario {
  final int id;
  final String username;
  final String email;
  final String? fotoPerfilUrl;
  
  // --- ¡CAMPOS DE ROL REFACTORIZADOS! ---
  final bool esModerador;
  final bool esAdministrador;

  // Constructor
  PerfilUsuario({
    required this.id,
    required this.username,
    required this.email,
    this.fotoPerfilUrl,
    required this.esModerador,
    required this.esAdministrador,
  });

  /// "Constructor de fábrica"
  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      
      // --- ¡NUEVO MAPEO DE ROLES! ---
      // Esto ahora coincide con el JSON de la API
      esModerador: json['esModerador'] as bool,
      esAdministrador: json['esAdministrador'] as bool,
    );
  }
}