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

    // Definimos los items
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

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _onItemTapped(0);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // --- DISEÑO MÓVIL (Vertical) ---
          if (constraints.maxWidth < 600) {
            return Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                // Forzamos etiquetas siempre para mejorar el centrado vertical del icono
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
            // --- DISEÑO TABLET/ESCRITORIO (Horizontal) ---
            return Scaffold(
              body: Row(
                children: [
                  // 1. BARRA LATERAL
                  // Usamos MediaQuery.removePadding para que el Rail ignore la barra de estado
                  // y calcule el centro (0.0) basándose en la altura TOTAL de la pantalla.
                  MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,

                      // Muestra Icono + Texto siempre
                      labelType: NavigationRailLabelType.all,

                      // Centrado vertical absoluto
                      groupAlignment: 0.0,

                      elevation: 5,
                      backgroundColor: theme.colorScheme.surface,
                      minWidth: 80,

                      destinations: navItems
                          .map((item) => NavigationRailDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.selectedIcon),
                                label: Text(item.label),
                                // Padding interno de cada botón (opcional, para airear)
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ))
                          .toList(),
                    ),
                  ),

                  const VerticalDivider(thickness: 1, width: 1),

                  // 2. CONTENIDO PRINCIPAL
                  Expanded(
                    child: SafeArea(
                      left: false,
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages,
                      ),
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
