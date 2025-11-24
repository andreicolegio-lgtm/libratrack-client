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

  static const List<Widget> _widgetOptions = <Widget>[
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
  void initState() {
    super.initState();
    debugPrint('[HomeScreen] Loaded with _selectedIndex=$_selectedIndex');
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: l10n.bottomNavCatalog,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: l10n.bottomNavSearch,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.bottomNavProfile,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[300],
        onTap: _onItemTapped,
      ),
    );
  }
}
