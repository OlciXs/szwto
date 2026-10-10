import 'package:flutter/material.dart';

/// Kategorie zabytków – te same wartości co enum MonumentCategory w backendzie.
enum MonumentCategory {
  kamienica('KAMIENICA', 'Kamienice i domy', Icons.apartment),
  palac('PALAC', 'Pałace i wille', Icons.castle),
  sakralny('SAKRALNY', 'Obiekty sakralne', Icons.church),
  most('MOST', 'Mosty', Icons.water),
  pomnik('POMNIK', 'Pomniki', Icons.account_balance),
  rzezba('RZEZBA', 'Rzeźby i sztuka', Icons.palette),
  park('PARK', 'Parki i cmentarze', Icons.park),
  publiczny('PUBLICZNY', 'Budynki publiczne', Icons.location_city),
  techniczny('TECHNICZNY', 'Technika i fortyfikacje', Icons.factory),
  architektura('ARCHITEKTURA', 'Inna architektura', Icons.domain);

  const MonumentCategory(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static MonumentCategory fromApi(String? value) =>
      MonumentCategory.values.firstWhere(
        (c) => c.apiValue == value,
        orElse: () => MonumentCategory.architektura,
      );
}
