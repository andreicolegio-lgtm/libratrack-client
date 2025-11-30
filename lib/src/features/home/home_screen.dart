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

  // Instancias const para preservar estado (scroll, búsquedas, etc.)
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Definimos los items una sola vez
    final navItems = [
      _NavItem(
        icon: Icons.collections_bookmark_outlined,
        selectedIcon: Icons.collections_bookmark,
        label: l10n.bottomNavCatalog,
      ),
      _NavItem(
        icon: Icons.search_outlined,
        selectedIcon: Icons.search,
        label: l10n.bottomNavSearch,
      ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.bottomNavProfile,
      ),
    ];

    // Gestión del botón Atrás (Android)
    return PopScope(
      canPop: _selectedIndex == 0, // Solo sale si está en Catálogo
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _onItemTapped(0); // Si no, vuelve al Catálogo
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Punto de corte para Tablet/Escritorio (600dp)
          if (constraints.maxWidth < 600) {
            // --- DISEÑO MÓVIL (Barra Inferior) ---
            return Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                destinations: navItems
                    .map((item) => NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                        ))
                    .toList(),
              ),
            );
          } else {
            // --- DISEÑO TABLET/ESCRITORIO (Barra Lateral) ---
            return Scaffold(
              body: Row(
                children: [
                  // Usamos Stack para separar el Logo de la Navegación
                  // Esto permite que los botones se centren perfectamente en la pantalla
                  // sin que el logo ocupe espacio y los empuje hacia abajo.
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onItemTapped,

                        // Muestra Icono + Texto siempre
                        labelType: NavigationRailLabelType.all,

                        // Centrado vertical matemático (0.0 = centro absoluto)
                        // Al incluir el texto en el labelType, el "centro" calculado
                        // es el centro del bloque completo [Icono + Texto].
                        groupAlignment: 0.0,

                        elevation: 5,
                        backgroundColor: theme.colorScheme.surface,

                        destinations: navItems
                            .map((item) => NavigationRailDestination(
                                  icon: Icon(item.icon),
                                  selectedIcon: Icon(item.selectedIcon),
                                  label: Text(item.label),
                                ))
                            .toList(),
                      ),

                      // El Logo flota encima, posicionado absolutamente
                      Positioned(
                        top: 16, // Margen superior seguro
                        child: SafeArea(
                          bottom: false,
                          child: Icon(
                            Icons.library_books,
                            color: theme.primaryColor,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Divisor vertical
                  const VerticalDivider(thickness: 1, width: 1),

                  // Contenido Principal
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
