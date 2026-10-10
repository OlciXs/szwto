import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Próba wczytania sesji przed uruchomieniem aplikacji
  try {
    await ApiService.instance.loadSession();
  } catch (e) {
    debugPrint('Błąd ładowania sesji: $e');
  }

  runApp(const ZabytkiApp());
}

class ZabytkiApp extends StatelessWidget {
  const ZabytkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odkrywca Zabytków',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      // Dynamiczne przełączanie ekranu w zależności od stanu zalogowania
      home: ApiService.instance.isLoggedIn
          ? const MapScreen()
          : const LoginScreen(),
    );
  }
}