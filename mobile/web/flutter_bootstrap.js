{{flutter_js}}
{{flutter_build_config}}

// Bez service workera Fluttera (oznaczony przez Fluttera jako przestarzały):
// cache'ował starą wersję aplikacji, więc po wdrożeniu na GitHub Pages gracze
// widzieli nieaktualną stronę (np. starą zakładkę „Kolekcja”) nawet po przelogowaniu.
// Usuwamy też rejestracje i cache z wcześniejszych wersji.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker
    .getRegistrations()
    .then((registrations) => registrations.forEach((r) => r.unregister()));
}
if (window.caches) {
  caches.keys().then((keys) => keys.forEach((key) => caches.delete(key)));
}

_flutter.loader.load();
