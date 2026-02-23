class JournalEntry {
  final DateTime date;
  final DateTime? updatedAt;
  final String content;

  JournalEntry({required this.date, required this.content, this.updatedAt});

  // OBJET -> MAP
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'content': content,
    };
  }

  // MAP -> OBJET
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      date: DateTime.parse(map['date']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      content: map['content'],
    );
  }

  JournalEntry copyWith({
    DateTime? date,
    String? content,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      date: date ?? this.date,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
