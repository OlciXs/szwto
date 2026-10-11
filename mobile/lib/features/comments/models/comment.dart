/// Komentarz pod zabytkiem (GET /monuments/:id/comments).
class MonumentComment {
  final int id;
  final String body;
  final DateTime createdAt;
  final bool isMine;
  final CommentAuthor author;

  MonumentComment({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.isMine,
    required this.author,
  });

  factory MonumentComment.fromJson(Map<String, dynamic> json) => MonumentComment(
        id: json['id'] as int,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        isMine: json['isMine'] as bool? ?? false,
        author: CommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
      );
}

class CommentAuthor {
  final int id;
  final String displayName;
  final int level;
  final int rankIndex;
  final String rankName;

  CommentAuthor({
    required this.id,
    required this.displayName,
    required this.level,
    required this.rankIndex,
    required this.rankName,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) => CommentAuthor(
        id: json['id'] as int,
        displayName: json['displayName'] as String,
        level: json['level'] as int? ?? 1,
        rankIndex: json['rankIndex'] as int? ?? 0,
        rankName: json['rankName'] as String? ?? 'Turysta',
      );
}

class CommentsPage {
  final int total;

  /// Czy oglądający odwiedził zabytek (warunek 1 z 2 – drugi to bycie na miejscu).
  final bool visited;
  final int visitRadius;
  final bool hasMore;
  final List<MonumentComment> comments;

  CommentsPage({
    required this.total,
    required this.visited,
    required this.visitRadius,
    required this.hasMore,
    required this.comments,
  });

  factory CommentsPage.fromJson(Map<String, dynamic> json) => CommentsPage(
        total: json['total'] as int? ?? 0,
        visited: json['visited'] as bool? ?? false,
        visitRadius: json['visitRadius'] as int? ?? 50,
        hasMore: json['hasMore'] as bool? ?? false,
        comments: (json['comments'] as List<dynamic>? ?? const [])
            .map((c) => MonumentComment.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
