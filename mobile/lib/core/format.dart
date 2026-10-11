String formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}

/// „przed chwilą”, „5 min temu”, „2 godz. temu”, „3 dni temu”, potem data.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'przed chwilą';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
  if (diff.inHours < 24) return '${diff.inHours} godz. temu';
  if (diff.inDays == 1) return 'wczoraj';
  if (diff.inDays < 7) return '${diff.inDays} dni temu';
  return formatDate(date);
}

String formatDistance(double meters) {
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
  return '${meters.round()} m';
}
