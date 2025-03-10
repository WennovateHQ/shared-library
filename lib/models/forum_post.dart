class ForumPost {
  final String id;
  final String user;
  final String avatar;
  final String content;
  final DateTime timestamp;
  int likes;
  int comments;

  ForumPost({
    required this.id,
    required this.user,
    required this.avatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'],
      user: json['user'],
      avatar: json['avatar'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      likes: json['likes'],
      comments: json['comments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'avatar': avatar,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'comments': comments,
    };
  }
}
