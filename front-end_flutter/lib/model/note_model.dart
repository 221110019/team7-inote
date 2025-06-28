class NoteModel {
  final String? id;
  final String title;
  final String content;
  final String category;
  final String by;
  final DateTime timestamp;
  final bool isDeleted;

  NoteModel({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.by,
    required this.timestamp,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'note': content,
        'category': category,
        'by': by,
        'timestamp': timestamp.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory NoteModel.fromMap(Map map) => NoteModel(
        id: map['id'] != null ? map['id'].toString() : null,
        title: map['title'] ?? '',
        content: map['note'] ?? '',
        category: map['category'] ?? '',
        by: map['by'] ?? '',
        timestamp: DateTime.parse(
            map['timestamp'] ?? DateTime.now().toIso8601String()),
        isDeleted: map['isDeleted'] ?? false,
      );

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? by,
    DateTime? timestamp,
    bool? isDeleted,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      by: by ?? this.by,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
