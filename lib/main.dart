import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ACTIVAR EDGE-TO-EDGE
  // Solo le decimos al sistema "ocupa toda la pantalla", pero no definimos colores todavía.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
    return Consumer<SettingsService>(
      builder: (BuildContext context, SettingsService settings, Widget? child) {
        return MaterialApp(
          title: 'LibraTrack',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,

          // --- Configuración de Idioma y Tema (Igual que tenías) ---
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          themeMode: settings.themeMode,

          // Tema Claro
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            appBarTheme: const AppBarTheme(centerTitle: true),
            cardTheme: const CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),

          // Tema Oscuro
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(centerTitle: true),
          ),

          // El builder envuelve todas las pantallas. Usamos 'context' para saber el brillo actual.
          builder: (context, child) {
            // Detectamos si el tema resultante es oscuro o claro
            final bool isDark = Theme.of(context).brightness == Brightness.dark;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                // Hacemos las barras transparentes
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,

                // Iconos de la Barra de Estado (Arriba)
                // Android: Brightness.light pone iconos BLANCOS (para fondo oscuro)
                // Android: Brightness.dark pone iconos NEGROS (para fondo claro)
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,

                // iOS: Funciona al revés por razones históricas
                // Brightness.dark pone texto BLANCO
                // Brightness.light pone texto NEGRO
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,

                // Iconos de la Barra de Navegación (Abajo - Android)
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
              child:
                  child!, // Renderizamos la pantalla correspondiente (Login, Home, etc.)
            );
          },

          home: const AuthWrapper(),

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
