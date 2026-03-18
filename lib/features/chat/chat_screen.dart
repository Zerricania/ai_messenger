import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/characters_data.dart';
import '../../core/theme.dart';
import '../../data/models/message_model.dart';
import '../../data/models/saved_message_model.dart';
import '../../data/services/ai_service.dart';
import '../../providers/app_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String characterId;
  const ChatScreen({super.key, required this.characterId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<MessageModel> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _isTyping = false;
  bool _historyLoaded = false;
  String? _uid;
  String? _selectedMessageId;

  String _characterName = '';
  String _systemPrompt = '';
  String? _characterAvatarAsset;
  String? _characterAvatarUrl;

  @override
  void initState() {
    super.initState();
    _initCharacterAndHistory();
  }

  Future<void> _initCharacterAndHistory() async {
    final builtIn = characters.where((c) => c.id == widget.characterId);
    if (builtIn.isNotEmpty) {
      final c = builtIn.first;
      _characterName = c.name;
      _systemPrompt = c.systemPrompt;
      _characterAvatarAsset = c.avatar;
    }

    final user = ref.read(currentUserProvider).asData?.value;
    _uid = user?.uid;

    if (_uid != null) {
      if (builtIn.isEmpty) {
        try {
          final userChars = await ref
              .read(userRepositoryProvider)
              .getUserCharacters(_uid!);
          final found = userChars.where((c) => c.id == widget.characterId);
          if (found.isNotEmpty) {
            final c = found.first;
            _characterName = c.name;
            _systemPrompt = c.systemPrompt;
            _characterAvatarUrl = c.avatarUrl;
          }
        } catch (_) {}
      }

      if (!_historyLoaded) {
        _historyLoaded = true;
        final history = await ref
            .read(chatRepositoryProvider)
            .getHistory(_uid!, widget.characterId);
        if (mounted) {
          setState(() => _messages.addAll(history));
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    }

    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;
    if (_uid == null) return;

    setState(() => _selectedMessageId = null);

    final userMessage = MessageModel(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _controller.clear();
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    await ref
        .read(chatRepositoryProvider)
        .saveMessage(_uid!, widget.characterId, userMessage);
    _scrollToBottom();

    try {
      final history = _messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final response = await AiService.sendMessage(
        systemPrompt: _systemPrompt,
        history: history,
      );

      if (mounted) {
        final aiMessage = MessageModel(
          id: const Uuid().v4(),
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(aiMessage);
          _isTyping = false;
        });
        await ref
            .read(chatRepositoryProvider)
            .saveMessage(_uid!, widget.characterId, aiMessage);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
        setState(() => _isTyping = false);
      }
    }
  }

  void _toggleActions(String messageId) {
    setState(() {
      _selectedMessageId =
          _selectedMessageId == messageId ? null : messageId;
    });
  }

  Future<void> _saveToFavorites(MessageModel message) async {
    if (_uid == null) return;
    final saved = SavedMessageModel(
      id: const Uuid().v4(),
      messageId: message.id,
      characterId: widget.characterId,
      characterName: _characterName,
      text: message.text,
      isUser: message.isUser,
      savedAt: DateTime.now(),
      originalTimestamp: message.timestamp,
    );
    await ref.read(chatRepositoryProvider).saveToFavorites(_uid!, saved);
    if (mounted) {
      setState(() => _selectedMessageId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавлено в избранное'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _setReaction(MessageModel message, int reaction) async {
    if (_uid == null) return;
    await ref
        .read(chatRepositoryProvider)
        .setReaction(_uid!, widget.characterId, message.id, reaction);
    if (mounted) {
      setState(() => _selectedMessageId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reaction == 1
              ? 'Спасибо за отклик! 👍'
              : 'Спасибо за отклик! 👎'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearHistory() async {
    if (_uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Все сообщения будут скрыты.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Очистить',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(chatRepositoryProvider)
          .clearHistory(_uid!, widget.characterId);
      if (mounted) setState(() => _messages.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Берём насыщенный акцентный цвет напрямую из провайдера
    final accentColor = ref.watch(themeProvider).accent;

    return GestureDetector(
      onTap: () => setState(() => _selectedMessageId = null),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.go('/characters'),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[800],
                backgroundImage: _characterAvatarAsset != null
                    ? AssetImage(_characterAvatarAsset!) as ImageProvider
                    : _characterAvatarUrl != null
                        ? CachedNetworkImageProvider(_characterAvatarUrl!)
                        : null,
                child: _characterAvatarAsset == null &&
                        _characterAvatarUrl == null
                    ? Text(
                        _characterName.isNotEmpty
                            ? _characterName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(_characterName.isNotEmpty ? _characterName : '...'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: _TypingIndicator(),
                      ),
                    );
                  }
                  final msg = _messages[i];
                  final isSelected = _selectedMessageId == msg.id;
                  return _MessageItem(
                    message: msg,
                    isSelected: isSelected,
                    accentColor: accentColor, // передаём насыщенный цвет
                    onTap: () => _toggleActions(msg.id),
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      setState(() => _selectedMessageId = null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Скопировано')),
                      );
                    },
                    onSave: () => _saveToFavorites(msg),
                    onLike: () => _setReaction(msg, 1),
                    onDislike: () => _setReaction(msg, -1),
                  );
                },
              ),
            ),
            _InputBar(
              controller: _controller,
              isTyping: _isTyping,
              onSend: _sendMessage,
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ─── Сообщение с inline-иконками ─────────────────────────────────────────────

class _MessageItem extends StatelessWidget {
  final MessageModel message;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _MessageItem({
    required this.message,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.onCopy,
    required this.onSave,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Пузырь пользователя — насыщенный акцентный цвет (не разбавленный Material 3)
    final userBubbleColor = accentColor;
    // Текст пользователя — всегда белый, т.к. все акцентные цвета тёмные/насыщенные
    const userTextColor = Colors.white;

    // Пузырь AI — нейтральный фон адаптированный к теме
    final aiBubbleColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[300]!;
    final aiTextColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? userTextColor : aiTextColor,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Inline иконки
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: isSelected
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionIcon(
                            icon: Icons.copy_outlined,
                            tooltip: 'Копировать',
                            onTap: onCopy,
                          ),
                          _ActionIcon(
                            icon: Icons.bookmark_outline,
                            tooltip: 'В избранное',
                            color: Colors.amber,
                            onTap: onSave,
                          ),
                          _ActionIcon(
                            icon: Icons.thumb_up_outlined,
                            tooltip: 'Нравится',
                            color: Colors.green,
                            onTap: onLike,
                          ),
                          _ActionIcon(
                            icon: Icons.thumb_down_outlined,
                            tooltip: 'Не нравится',
                            color: Colors.redAccent,
                            onTap: onDislike,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Icon(
            icon,
            size: 20,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── Анимация загрузки ────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -7).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Поле ввода ───────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;
  final Color accentColor;

  const _InputBar({
    required this.controller,
    required this.isTyping,
    required this.onSend,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0E0E) : Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isTyping
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: accentColor,
                          ),
                        ),
                      ),
                    )
                  : Material(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(24),
                      elevation: 2,
                      child: InkWell(
                        onTap: onSend,
                        borderRadius: BorderRadius.circular(24),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
