import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'src/core/l10n/app_localizations.dart';
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
import 'src/features/auth/login_screen.dart';
import 'src/features/home/home_screen.dart';
import 'src/core/utils/api_client.dart';

void main() {
  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        Provider<ApiClient>(
          create: (BuildContext context) => ApiClient(
            context.read<FlutterSecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<SettingsService>(
          create: (_) => SettingsService(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (BuildContext context) => AuthService(
            context.read<ApiClient>(),
            context.read<FlutterSecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<AdminService>(
          create: (BuildContext context) =>
              AdminService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<CatalogService>(
          create: (BuildContext context) =>
              CatalogService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ElementoService>(
          create: (BuildContext context) =>
              ElementoService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<GeneroService>(
          create: (BuildContext context) =>
              GeneroService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ModeracionService>(
          create: (BuildContext context) =>
              ModeracionService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<PropuestaService>(
          create: (BuildContext context) =>
              PropuestaService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ResenaService>(
          create: (BuildContext context) =>
              ResenaService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<TipoService>(
          create: (BuildContext context) =>
              TipoService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<UserService>(
          create: (BuildContext context) =>
              UserService(context.read<ApiClient>()),
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
    return Consumer<SettingsService>(
      builder: (BuildContext context, SettingsService settings, Widget? child) {
        return MaterialApp(
          title: 'LibraTrack',
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          localizationsDelegates: const <LocalizationsDelegate>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const <Locale>[
            Locale('en', ''),
            Locale('es', ''),
          ],
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
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (BuildContext context, AuthService auth, Widget? child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (auth.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
