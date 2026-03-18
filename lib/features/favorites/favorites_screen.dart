import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/saved_message_model.dart';
import '../../providers/app_providers.dart';

// Провайдер для избранных сообщений
final favoritesProvider =
    FutureProvider.autoDispose<List<SavedMessageModel>>((ref) async {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return [];
  return ref.read(chatRepositoryProvider).getSavedMessages(user.uid);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: favAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_outline,
                      size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'Здесь будут сохранённые сообщения',
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Удерживай сообщение в чате и выбери «В избранное»',
                    style:
                        TextStyle(color: Colors.grey[700], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final msg = messages[i];
              return _FavoriteItem(
                message: msg,
                onDelete: () async {
                  final user =
                      ref.read(currentUserProvider).asData?.value;
                  if (user == null) return;
                  await ref
                      .read(chatRepositoryProvider)
                      .removeFromFavorites(user.uid, msg.id);
                  ref.invalidate(favoritesProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Элемент списка ───────────────────────────────────────────────────────────

class _FavoriteItem extends StatelessWidget {
  final SavedMessageModel message;
  final VoidCallback onDelete;

  const _FavoriteItem({required this.message, required this.onDelete});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return 'Сегодня, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Вчера, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Подпись: персонаж и дата сохранения
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 13, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  message.characterName,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text(
                  _formatDate(message.savedAt),
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          // Пузырь сообщения
          Align(
            alignment:
                isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: () => _showActions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.deepPurple
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading:
                const Icon(Icons.copy_outlined, color: Colors.white),
            title: const Text('Копировать'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скопировано')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: Colors.redAccent),
            title: const Text('Удалить из избранного',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
