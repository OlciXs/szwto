import 'package:flutter/material.dart';

import 'api_client.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/';
}

/// Globalny navigator – pozwala przejść do logowania z dowolnego miejsca
/// (np. po wygaśnięciu sesji w ApiClient).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> logoutAndShowLogin() async {
  await ApiClient.instance.clearSession();
  navigatorKey.currentState
      ?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
}
