// lib/main.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';
import 'package:libratrack_client/src/features/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- ¡IMPORTACIÓN RENOMBRADA! ---
import 'package:libratrack_client/src/core/services/settings_service.dart';

// --- Importaciones de Localización (ya las tenías) ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:libratrack_client/src/core/l10n/app_localizations.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // --- ¡SERVICIO RENOMBRADO! ---
  // (Paso 4.1) Cambiamos ThemeService por SettingsService
  final SettingsService settingsService = SettingsService(prefs);

  runApp(
    // (Paso 4.2) Proveemos el SettingsService
    ChangeNotifierProvider(
      create: (context) => settingsService,
      child: const LibraTrackApp(),
    ),
  );
}

class LibraTrackApp extends StatefulWidget {
  const LibraTrackApp({super.key});

  @override
  State<LibraTrackApp> createState() => _LibraTrackAppState();
}

class _LibraTrackAppState extends State<LibraTrackApp> {
  final AuthService _authService = AuthService();
  Future<String?>? _tokenCheckFuture;

  @override
  void initState() {
    super.initState();
    _tokenCheckFuture = _authService.getToken(); 
  }

  // --- (Tema Claro - sin cambios) ---
  ThemeData _buildLightTheme() {
    const Color primaryColor = Colors.blue;
    const Color secondaryColor = Color(0xFF1E88E5); 
    const Color background = Color(0xFFF4F4F4); 
    const Color surfaceColor = Colors.white;   
    const Color onSurfaceColor = Colors.black; 

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,        
        onSurface: onSurfaceColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background, 
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: onSurfaceColor),
        titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600, color: onSurfaceColor),
        titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: onSurfaceColor),
        bodyMedium: TextStyle(fontSize: 14.0, color: Colors.grey[800]),
        labelLarge: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 1, 
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurfaceColor),
        iconTheme: IconThemeData(color: onSurfaceColor), 
      ),
      cardTheme: const CardThemeData( 
        color: surfaceColor, 
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  // --- (Tema Oscuro - sin cambios) ---
  ThemeData _buildDarkTheme() {
    const Color primaryColor = Colors.blue;
    const Color secondaryColor = Color(0xFF1E88E5); 
    const Color background = Color(0xFF121212);
    const Color surfaceColor = Color(0xFF1E1E1E); 

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onSurface: Colors.white, 
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background, 
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14.0, color: Colors.grey[300]),
        labelLarge: TextStyle(fontSize: 16.0, color: Colors.grey[500]),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white), 
      ),
      cardTheme: const CardThemeData( 
        color: surfaceColor, 
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // --- ¡SERVICIO RENOMBRADO! ---
    // 2. Escuchamos los cambios del SettingsService
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        
        return MaterialApp(
          // --- (Sección de Localización - sin cambios) ---
          onGenerateTitle: (context) {
            final localizations = AppLocalizations.of(context);
            return localizations?.appTitle ?? 'LibraTrack';
          },
          localizationsDelegates: const [
            AppLocalizations.delegate, 
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'), // Español
            Locale('en'), // Inglés
          ],
          // --- ¡LÍNEA AÑADIDA! (Paso 4.3) ---
          locale: settingsService.locale, // (Conecta el idioma al servicio)
          
          debugShowCheckedModeBanner: false,
          
          // --- Configuración de Tema (Conectada) ---
          theme: _buildLightTheme(),     
          darkTheme: _buildDarkTheme(),    
          themeMode: settingsService.themeMode, 

          navigatorKey: navigatorKey, 

          home: FutureBuilder<String?>(
            future: _tokenCheckFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      }
    );
  }
}