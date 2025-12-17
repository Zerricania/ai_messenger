import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    String? id,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'isUser': isUser ? 1 : 0,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    text: map['text'] as String,
    isUser: (map['isUser'] as int) == 1,
    id: map['id'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
  );
}