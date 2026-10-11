import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Otwiera link w przeglądarce / zewnętrznej aplikacji.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(
      SnackBar(content: Text('Nie udało się otworzyć: ${Uri.decodeFull(url)}')),
    );
  }
}
