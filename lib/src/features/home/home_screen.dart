import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../catalog/catalog_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Usamos IndexedStack, así que instanciamos las pantallas una sola vez.
  // Esto preserva el estado (scroll, búsquedas) al cambiar de pestaña.
  static const List<Widget> _pages = <Widget>[
    CatalogScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      // IndexedStack mantiene vivas las pantallas inactivas en el árbol de widgets
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            selectedIcon: const Icon(Icons.collections_bookmark),
            label: l10n.bottomNavCatalog,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: l10n.bottomNavSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.bottomNavProfile,
          ),
        ],
      ),
    );
  }
}
