import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Configuración y Utilidades
import 'src/core/l10n/app_localizations.dart';
import 'src/core/utils/api_client.dart';

// Servicios (Lógica de Negocio)
import 'src/core/services/admin_service.dart';
import 'src/core/services/auth_service.dart';
import 'src/core/services/catalog_service.dart';
import 'src/core/services/elemento_service.dart';
import 'src/core/services/genero_service.dart';
import 'src/core/services/moderacion_service.dart';
import 'src/core/services/propuesta_service.dart';
import 'src/core/services/resena_service.dart';
import 'src/core/services/settings_service.dart';
import 'src/core/services/tipo_service.dart';
import 'src/core/services/user_service.dart';

// Pantallas Principales
import 'src/features/auth/login_screen.dart';
import 'src/features/home/home_screen.dart';

/// Clave global para acceder al navegador desde cualquier lugar (ej. para redirecciones forzadas).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Asegura que el binding de Flutter esté inicializado antes de cualquier operación asíncrona.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // MultiProvider permite inyectar múltiples dependencias en el árbol de widgets de una vez.
    // Esto establece el "Service Locator" para toda la aplicación.
    MultiProvider(
      providers: <SingleChildWidget>[
        // --- CAPA 1: INFRAESTRUCTURA (Sin dependencias) ---

        // Almacenamiento seguro para tokens (Keychain/Keystore)
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),

        // Servicio de configuración local (Tema, Idioma)
        ChangeNotifierProvider<SettingsService>(
          create: (_) => SettingsService(),
        ),

        // --- CAPA 2: RED Y CLIENTE HTTP (Depende de Storage) ---

        // Cliente API centralizado que maneja interceptores y tokens
        Provider<ApiClient>(
          create: (BuildContext context) => ApiClient(
            context.read<FlutterSecureStorage>(),
          ),
        ),

        // --- CAPA 3: SERVICIOS DE NEGOCIO (Dependen de ApiClient) ---

        // Servicio de Autenticación (Login, Registro, Google)
        ChangeNotifierProvider<AuthService>(
          create: (BuildContext context) => AuthService(
            context.read<ApiClient>(),
            context.read<FlutterSecureStorage>(),
          ),
        ),

        // Servicios de Gestión de Contenido y Usuarios
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
      child: const LibraTrackApp(),
    ),
  );
}

/// Widget raíz de la aplicación.
/// Configura el tema, la internacionalización y el enrutamiento.
class LibraTrackApp extends StatelessWidget {
  const LibraTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos cambios en la configuración (Tema/Idioma) para reconstruir la app.
    return Consumer<SettingsService>(
      builder: (BuildContext context, SettingsService settings, Widget? child) {
        return MaterialApp(
          // Configuración Básica
          title: 'LibraTrack',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,

          // --- Internacionalización (i18n) ---
          locale: settings
              .locale, // Idioma seleccionado por el usuario (o null para sistema)
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // --- Temas ---
          themeMode: settings.themeMode, // Claro / Oscuro / Sistema
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
            ),
            appBarTheme: const AppBarTheme(centerTitle: true),
            cardTheme: const CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(centerTitle: true),
          ),

          // --- Enrutamiento ---
          // AuthWrapper decide qué pantalla mostrar al inicio (Login vs Home)
          home: const AuthWrapper(),

          // Rutas nombradas para navegación imperativa si es necesario
          routes: <String, WidgetBuilder>{
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}

/// Widget que gestiona el estado de autenticación inicial.
/// Muestra una pantalla de carga mientras verifica si hay una sesión activa,
/// y redirige al usuario a Home o Login según corresponda.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (BuildContext context, AuthService auth, Widget? child) {
        // 1. Estado de Carga (Verificando token guardado...)
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Iniciando sesión...'),
                ],
              ),
            ),
          );
        }

        // 2. Usuario Autenticado -> Ir al Home
        else if (auth.isAuthenticated) {
          return const HomeScreen();
        }

        // 3. No Autenticado -> Ir al Login
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
