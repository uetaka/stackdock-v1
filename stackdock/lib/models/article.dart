class Article {
  final String id;
  final String url;
  final String title;
  final DateTime addedDate;
  final bool isRead;

  Article({
    required this.id,
    required this.url,
    required this.title,
    required this.addedDate,
    required this.isRead,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
      isRead: json['isRead'] as bool,
    );
  }
}
