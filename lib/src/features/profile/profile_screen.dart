import 'package:flutter/material.dart';

/// Pantalla para ver y editar el perfil del usuario (Mockup 5).
/// Implementa el requisito RF04.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: const Center(
        child: Text('Aquí irá el formulario de perfil (RF04)'),
      ),
    );
  }
}