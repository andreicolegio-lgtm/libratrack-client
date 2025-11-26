/// Representa la información pública o privada de un usuario.
/// Coincide con `UsuarioResponseDTO`.
class PerfilUsuario {
  final int id;
  final String username;
  final String email;
  final String? fotoPerfilUrl;

  // Permisos
  final bool esModerador;
  final bool esAdministrador;

  const PerfilUsuario({
    required this.id,
    required this.username,
    required this.email,
    required this.esModerador,
    required this.esAdministrador,
    this.fotoPerfilUrl,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      esModerador: json['esModerador'] as bool? ?? false,
      esAdministrador: json['esAdministrador'] as bool? ?? false,
    );
  }

  /// Crea una copia de la instancia con campos modificados (útil para State Management).
  PerfilUsuario copyWith({
    String? username,
    String? fotoPerfilUrl,
    bool? esModerador,
    bool? esAdministrador,
  }) {
    return PerfilUsuario(
      id: id,
      email: email, // El email raramente cambia en esta vista
      username: username ?? this.username,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      esModerador: esModerador ?? this.esModerador,
      esAdministrador: esAdministrador ?? this.esAdministrador,
    );
  }
}
