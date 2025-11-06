import 'package:flutter/material.dart';
import 'package:libratrack_client/src/features/catalog/catalog_screen.dart';
import 'package:libratrack_client/src/features/profile/profile_screen.dart';
import 'package:libratrack_client/src/features/search/search_screen.dart';

/// Este es el "widget contenedor" principal de la aplicación.
///
/// Gestiona la barra de navegación inferior (BottomNavigationBar)
/// y controla cuál de las pantallas principales (Catálogo, Búsqueda, Perfil)
/// está actualmente visible.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. El índice de la pestaña seleccionada actualmente (0 = Catálogo)
  int _selectedIndex = 0; 

  // 2. La lista de las pantallas principales
  static const List<Widget> _widgetOptions = <Widget>[
    CatalogScreen(), // Índice 0
    SearchScreen(),  // Índice 1
    ProfileScreen(), // Índice 2
  ];

  // 3. Método que se llama cuando el usuario toca un icono
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. El cuerpo (Body) muestra la pantalla seleccionada
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // 5. La Barra de Navegación Inferior (Mockups 3, 7, 5)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex, // Marca el icono activo
        selectedItemColor: Colors.blue[300], // Color del icono activo
        onTap: _onItemTapped, // Llama al método cuando se toca
      ),
    );
  }
}