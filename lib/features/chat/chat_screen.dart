import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String characterId;

  const ChatScreen({super.key, required this.characterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чат с $characterId')),
      body: const Center(
        child: Text(
          'Чат с Groq скоро будет здесь!\nСейчас просто заглушка :)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}