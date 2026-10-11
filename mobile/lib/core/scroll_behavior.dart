import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Przewijanie list przeciąganiem także myszą i touchpadem.
/// Domyślnie Flutter Web przewija przeciąganiem tylko na ekranie dotykowym,
/// przez co poziome listy (filtry, gablotka) były nieprzewijalne w przeglądarce.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
