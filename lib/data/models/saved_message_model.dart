class SavedMessageModel {
  final String id;
  final String messageId;
  final String characterId;
  final String characterName;
  final String text;
  final bool isUser;
  final DateTime savedAt;
  final DateTime originalTimestamp;

  const SavedMessageModel({
    required this.id,
    required this.messageId,
    required this.characterId,
    required this.characterName,
    required this.text,
    required this.isUser,
    required this.savedAt,
    required this.originalTimestamp,
  });

  factory SavedMessageModel.fromMap(Map<String, dynamic> map) =>
      SavedMessageModel(
        id: map['id'] as String,
        messageId: map['messageId'] as String,
        characterId: map['characterId'] as String,
        characterName: map['characterName'] as String,
        text: map['text'] as String,
        isUser: map['isUser'] as bool,
        savedAt: DateTime.fromMillisecondsSinceEpoch(map['savedAt'] as int),
        originalTimestamp: DateTime.fromMillisecondsSinceEpoch(
          map['originalTimestamp'] as int,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'messageId': messageId,
        'characterId': characterId,
        'characterName': characterName,
        'text': text,
        'isUser': isUser,
        'savedAt': savedAt.millisecondsSinceEpoch,
        'originalTimestamp': originalTimestamp.millisecondsSinceEpoch,
      };
}
