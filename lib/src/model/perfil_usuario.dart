class PerfilUsuario {
  final int id;
  final String username;
  final String email;
  final String? fotoPerfilUrl;

  final bool esModerador;
  final bool esAdministrador;

  PerfilUsuario({
    required this.id,
    required this.username,
    required this.email,
    required this.esModerador,
    required this.esAdministrador,
    this.fotoPerfilUrl,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      esModerador: json['esModerador'] as bool,
      esAdministrador: json['esAdministrador'] as bool,
    );
  }
}
