import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'core/api_client.dart';
import 'core/demo_mode.dart';
import 'core/routes.dart';
import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Próba wczytania sesji przed uruchomieniem aplikacji
  try {
    await ApiClient.instance.loadSession();
    await DemoMode.instance.load();
  } catch (e) {
    debugPrint('Błąd ładowania sesji: $e');
  }

  // Wygasła sesja w dowolnym miejscu aplikacji -> ekran logowania
  ApiClient.instance.onUnauthorized = () => navigatorKey.currentState
      ?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);

  runApp(const ZabytkiApp());
}

class ZabytkiApp extends StatelessWidget {
  const ZabytkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odkrywca Zabytków',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      // Zawsze jedna trasa startowa (initialRoute "/login" dokładałby pod spód "/",
      // a na webie adres z paska przeglądarki tworzyłby dodatkowe ekrany).
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute(
          settings: RouteSettings(
            name: ApiClient.instance.isLoggedIn
                ? AppRoutes.home
                : AppRoutes.login,
          ),
          builder: (_) => ApiClient.instance.isLoggedIn
              ? const AppShell()
              : const LoginScreen(),
        ),
      ],
      routes: {
        AppRoutes.home: (_) => const AppShell(),
        AppRoutes.login: (_) => const LoginScreen(),
      },
    );
  }
}
