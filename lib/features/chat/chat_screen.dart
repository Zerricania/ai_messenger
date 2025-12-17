import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/groq_service.dart';
import '../../core/characters_data.dart';
import 'models/message.dart';
import 'repository/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final String characterId;
  const ChatScreen({super.key, required this.characterId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isTyping = false;


  String _currentAiBuffer = '';
  final StringBuffer _stringBuffer = StringBuffer();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ChatRepository.getHistory(widget.characterId);
    if (mounted) {
      setState(() => messages.addAll(history));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || isTyping) return;

    final userMessage = Message(text: text, isUser: true);
    controller.clear();
    setState(() {
      messages.add(userMessage);
      isTyping = true;
      _currentAiBuffer = '';
    });
    await ChatRepository.saveMessage(widget.characterId, userMessage);
    _scrollToBottom();

    try {
      final character = characters.firstWhere((c) => c.id == widget.characterId);
      final systemPrompt = getSystemPromptFor(widget.characterId);
      final historyForGroq = messages.map((m) => {
        "role": m.isUser ? "user" : "assistant",
        "content": m.text,
      }).toList();

      setState(() => isTyping = true);

      final fullResponse = await GroqService.chatNoStream(
        systemPrompt: systemPrompt,
        history: historyForGroq,
      );

      if (mounted) {
        setState(() {
          messages.add(Message(text: fullResponse, isUser: false));
          isTyping = false;
        });
        await ChatRepository.saveMessage(widget.characterId, messages.last);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
        setState(() => isTyping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final character = characters.firstWhere((c) => c.id == widget.characterId);
    return Scaffold(
      appBar: AppBar(
        title: Text(character.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await ChatRepository.clearHistory(widget.characterId);
              setState(() => messages.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, top: 8, bottom: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('печатает', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          SizedBox(width: 8),
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    ),
                  );
                }

                final msg = messages[i];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.deepPurple : Colors.grey[800],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SelectableText(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),


          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    backgroundColor: Colors.deepPurple,
                    onPressed: isTyping ? null : () => _sendMessage(),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }
}