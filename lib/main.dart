// Archivo: lib/main.dart
// (¡SIN CAMBIOS! El código de ID: QA-016 ahora es correcto)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// --- ¡NUEVAS IMPORTACIONES! ---
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
// ---
import 'package:libratrack_client/src/core/l10n/app_localizations.dart';
import 'package:libratrack_client/src/core/services/admin_service.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/genero_service.dart';
import 'package:libratrack_client/src/core/services/moderacion_service.dart';
import 'package:libratrack_client/src/core/services/propuesta_service.dart';
import 'package:libratrack_client/src/core/services/resena_service.dart';
import 'package:libratrack_client/src/core/services/settings_service.dart';
import 'package:libratrack_client/src/core/services/tipo_service.dart';
import 'package:libratrack_client/src/core/services/user_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';
import 'package:libratrack_client/src/features/home/home_screen.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        
        // --- NIVEL 0: UTILIDADES BASE ---
        // (ID: QA-075) Proveemos el storage para que los servicios lo usen
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),

        // --- NIVEL 1: SERVICIOS BASE (Independientes) ---
        
        // (ID: QA-075) ApiClient ahora necesita el storage
        Provider<ApiClient>(
          create: (context) => ApiClient(
            context.read<FlutterSecureStorage>(),
          ),
        ),

        ChangeNotifierProvider<SettingsService>(
          create: (_) => SettingsService(),
        ),

        // --- NIVEL 2: SERVICIOS DE AUTENTICACIÓN ---
        
        // (ID: QA-075) AuthService necesita ApiClient y el Storage
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(
            context.read<ApiClient>(),
            context.read<FlutterSecureStorage>(),
          ),
        ),

        // --- NIVEL 3: SERVICIOS DE DATOS ---
        // (Estos no cambian, ya reciben el ApiClient configurado)
        
        ChangeNotifierProvider<AdminService>(
          create: (context) => AdminService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<CatalogService>(
          create: (context) => CatalogService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ElementoService>(
          create: (context) => ElementoService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<GeneroService>(
          create: (context) => GeneroService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ModeracionService>(
          create: (context) => ModeracionService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<PropuestaService>(
          create: (context) => PropuestaService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ResenaService>(
          create: (context) => ResenaService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<TipoService>(
          create: (context) => TipoService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<UserService>(
          create: (context) => UserService(context.read<ApiClient>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el SettingsService para el tema y el idioma
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'LibraTrack',
          debugShowCheckedModeBanner: false,

          // --- Configuración de Idioma (i18n) ---
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // Inglés
            Locale('es', ''), // Español
          ],

          // --- Configuración de Tema (Claro/Oscuro) ---
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,

          // --- Lógica de Navegación Inicial ---
          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Widget que decide qué pantalla mostrar al inicio (Carga, Login o Home)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          // Pantalla de carga mientras se verifica el token
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (auth.isAuthenticated) {
          // Usuario autenticado
          return const HomeScreen();
        } else {
          // Usuario no autenticado
          return const LoginScreen();
        }
      },
    );
  }
}