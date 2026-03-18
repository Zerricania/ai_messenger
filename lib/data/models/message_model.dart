class MessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isDeleted; // мягкое удаление — пользователь не видит, админ видит
  final int? reaction; // 1 = лайк, -1 = дизлайк, null = нет реакции

  const MessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isDeleted = false,
    this.reaction,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] as String,
        text: map['text'] as String,
        isUser: map['isUser'] as bool,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] as int,
        ),
        isDeleted: map['isDeleted'] as bool? ?? false,
        reaction: map['reaction'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isDeleted': isDeleted,
        'reaction': reaction,
      };

  MessageModel copyWith({
    bool? isDeleted,
    int? reaction,
  }) =>
      MessageModel(
        id: id,
        text: text,
        isUser: isUser,
        timestamp: timestamp,
        isDeleted: isDeleted ?? this.isDeleted,
        reaction: reaction ?? this.reaction,
      );
}
