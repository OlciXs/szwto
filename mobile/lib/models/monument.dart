class Monument {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  bool visited;
  DateTime? visitedAt;

  Monument({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.visited = false,
    this.visitedAt,
  });

  factory Monument.fromJson(Map<String, dynamic> json) {
    final visitedAtRaw = json['visitedAt'] as String?;
    return Monument(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      visited: json['visited'] as bool? ?? false,
      visitedAt:
          visitedAtRaw != null ? DateTime.parse(visitedAtRaw).toLocal() : null,
    );
  }
}

class VisitResult {
  final String message;
  final double distanceMeters;
  final DateTime? visitedAt;

  VisitResult({
    required this.message,
    required this.distanceMeters,
    this.visitedAt,
  });

  factory VisitResult.fromJson(Map<String, dynamic> json) {
    final visitedAtRaw = json['visitedAt'] as String?;
    return VisitResult(
      message: json['message'] as String? ?? 'Zabytek odznaczony!',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      visitedAt:
          visitedAtRaw != null ? DateTime.parse(visitedAtRaw).toLocal() : null,
    );
  }
}
