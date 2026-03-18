import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/message_model.dart';
import '../../data/models/saved_message_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/app_providers.dart';
import 'notification_screen.dart';

// ─── Провайдеры ───────────────────────────────────────────────────────────────

final allUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) {
  return ref.read(userRepositoryProvider).getAllUsers();
});

final userChatsProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, uid) {
  return ref.read(chatRepositoryProvider).getChatIds(uid);
});

final adminChatHistoryProvider = FutureProvider.autoDispose
    .family<List<MessageModel>, ({String uid, String characterId})>(
        (ref, args) {
  return ref.read(chatRepositoryProvider).getHistory(
        args.uid,
        args.characterId,
        includeDeleted: true,
      );
});

final adminFavoritesProvider =
    FutureProvider.autoDispose.family<List<SavedMessageModel>, String>(
        (ref, uid) {
  return ref.read(chatRepositoryProvider).getSavedMessages(uid);
});

// ─── Главный экран админки ────────────────────────────────────────────────────

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Отправить уведомление',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Нет пользователей'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (_, i) => _UserTile(user: users[i]),
          );
        },
      ),
    );
  }
}

// ─── Аватарка пользователя ────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;

  const _UserAvatar({required this.user, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage:
          hasAvatar ? CachedNetworkImageProvider(user.avatarUrl!) : null,
      child: !hasAvatar
          ? Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

// ─── Плитка пользователя ─────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${user.createdAt.day.toString().padLeft(2, '0')}.${user.createdAt.month.toString().padLeft(2, '0')}.${user.createdAt.year}';

    return ListTile(
      leading: _UserAvatar(user: user),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isAdmin)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${user.email}  •  Рег: $dateStr',
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminUserScreen(user: user)),
      ),
    );
  }
}

// ─── Экран пользователя — вкладки чаты / избранное ───────────────────────────

class AdminUserScreen extends ConsumerWidget {
  final UserModel user;
  const AdminUserScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              _UserAvatar(user: user, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Чаты'),
              Tab(icon: Icon(Icons.bookmark_outline), text: 'Избранное'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Вкладка чаты ────────────────────────────────────────────
            _UserChatsTab(user: user),
            // ── Вкладка избранное ────────────────────────────────────────
            _UserFavoritesTab(user: user),
          ],
        ),
      ),
    );
  }
}

// ─── Вкладка: чаты ───────────────────────────────────────────────────────────

class _UserChatsTab extends ConsumerWidget {
  final UserModel user;
  const _UserChatsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider(user.uid));

    return chatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (chatIds) {
        if (chatIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 48, color: Colors.grey[700]),
                const SizedBox(height: 12),
                Text('Нет чатов',
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chatIds.length,
          itemBuilder: (_, i) {
            final characterId = chatIds[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                  ),
                ),
                title: Text(
                  characterId,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle:
                    const Text('Нажми чтобы посмотреть переписку'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminChatScreen(
                      user: user,
                      characterId: characterId,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Вкладка: избранное ───────────────────────────────────────────────────────

class _UserFavoritesTab extends ConsumerWidget {
  final UserModel user;
  const _UserFavoritesTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(adminFavoritesProvider(user.uid));

    return favsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (saved) {
        if (saved.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_outline,
                    size: 48, color: Colors.grey[700]),
                const SizedBox(height: 12),
                Text('Нет сохранённых сообщений',
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: saved.length,
          itemBuilder: (_, i) => _FavoriteItem(item: saved[i]),
        );
      },
    );
  }
}

// ─── Элемент избранного ───────────────────────────────────────────────────────

class _FavoriteItem extends StatelessWidget {
  final SavedMessageModel item;
  const _FavoriteItem({required this.item});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = item.isUser;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Подпись: персонаж + дата сохранения
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 13, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  item.characterName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text(
                  _formatDate(item.savedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          // Пузырь
          Align(
            alignment:
                isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? accent.withValues(alpha: 0.7) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                item.text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Экран переписки пользователя ────────────────────────────────────────────

class AdminChatScreen extends ConsumerWidget {
  final UserModel user;
  final String characterId;

  const AdminChatScreen({
    super.key,
    required this.user,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      adminChatHistoryProvider((uid: user.uid, characterId: characterId)),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _UserAvatar(user: user, radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    characterId,
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.displayName,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined,
                      size: 48, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  Text('Нет сообщений',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: messages.length,
            itemBuilder: (_, i) =>
                _AdminMessageBubble(message: messages[i]),
          );
        },
      ),
    );
  }
}

// ─── Пузырь сообщения (только для чтения) ────────────────────────────────────

class _AdminMessageBubble extends StatelessWidget {
  final MessageModel message;
  const _AdminMessageBubble({required this.message});

  String _formatTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDeleted = message.isDeleted;
    final accent = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDeleted
                  ? Colors.grey[800]
                  : isUser
                      ? accent.withValues(alpha: 0.7)
                      : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isDeleted
                  ? Border.all(color: Colors.redAccent, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDeleted)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline,
                            size: 12, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text(
                          'Удалено пользователем',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                Text(
                  message.text,
                  style: TextStyle(
                    color: isDeleted ? Colors.grey[500] : Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (message.reaction != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        message.reaction == 1
                            ? Icons.thumb_up
                            : Icons.thumb_down,
                        size: 13,
                        color: message.reaction == 1
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.reaction == 1 ? 'Лайк' : 'Дизлайк',
                        style: TextStyle(
                          fontSize: 11,
                          color: message.reaction == 1
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
