import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.loadSession();
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
      home: ApiService.instance.isLoggedIn
          ? const MapScreen()
          : const LoginScreen(),
    );
  }
}
