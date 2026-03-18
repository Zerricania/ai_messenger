import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/characters_data.dart';
import '../../data/models/character_model.dart';
import '../../providers/app_providers.dart';
import 'create_character_screen.dart';

class CharactersScreen extends ConsumerWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userCharsAsync = ref.watch(userCharactersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Персонажи'),
      ),
      drawer: _AppDrawer(userAsync: userAsync),
      body: userCharsAsync.when(
        loading: () => _buildGrid(context, ref, []),
        error: (_, __) => _buildGrid(context, ref, []),
        data: (userChars) => _buildGrid(context, ref, userChars),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateCharacter(context, ref),
        tooltip: 'Создать персонажа',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCreateCharacter(
      BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
    );
    if (created == true) ref.invalidate(userCharactersProvider);
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<CharacterModel> userChars,
  ) {
    final builtInItems = characters
        .map((c) => _CharacterItem(
              id: c.id,
              name: c.name,
              desc: c.desc,
              assetAvatar: c.avatar,
              networkAvatar: null,
            ))
        .toList();

    final userItems = userChars
        .map((c) => _CharacterItem(
              id: c.id,
              name: c.name,
              desc: c.description,
              assetAvatar: null,
              networkAvatar: c.avatarUrl,
            ))
        .toList();

    final allItems = [...builtInItems, ...userItems];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, i) {
        final item = allItems[i];
        return _CharacterCard(
          item: item,
          onTap: () => context.push('/chat/${item.id}'),
        );
      },
    );
  }
}

// ─── Модель для отображения ───────────────────────────────────────────────────

class _CharacterItem {
  final String id;
  final String name;
  final String desc;
  final String? assetAvatar;
  final String? networkAvatar;

  const _CharacterItem({
    required this.id,
    required this.name,
    required this.desc,
    this.assetAvatar,
    this.networkAvatar,
  });
}

// ─── Карточка персонажа ───────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final _CharacterItem item;
  final VoidCallback onTap;

  const _CharacterCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Используем цвета из темы — автоматически адаптируются к светлой/тёмной
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: _buildAvatar(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface, // читаемо в обеих темах
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.desc,
                    style: TextStyle(
                      color: onSurfaceVariant, // читаемо в обеих темах
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (item.assetAvatar != null) {
      return Image.asset(item.assetAvatar!,
          fit: BoxFit.cover, width: double.infinity);
    }
    if (item.networkAvatar != null) {
      return CachedNetworkImage(
        imageUrl: item.networkAvatar!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Container(color: Colors.grey[800]),
        errorWidget: (_, __, ___) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Text(
          item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 40, color: Colors.white54),
        ),
      ),
    );
  }
}

// ─── Боковое меню ─────────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final AsyncValue userAsync;

  const _AppDrawer({required this.userAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userModel = userAsync.asData?.value;

    final displayName =
        userModel?.displayName ?? user?.displayName ?? 'Пользователь';
    final email = userModel?.email ?? user?.email ?? '';
    final avatarUrl = userModel?.avatarUrl;
    final bannerUrl = userModel?.bannerUrl;
    final isAdmin = userModel?.isAdmin ?? false;

    return Drawer(
      child: Column(
        children: [
          _DrawerHeader(
            displayName: displayName,
            email: email,
            avatarUrl: avatarUrl,
            bannerUrl: bannerUrl,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.person_outline,
                  title: 'Мой профиль',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/profile');
                  },
                ),
                _DrawerItem(
                  icon: Icons.add_circle_outline,
                  title: 'Создать персонажа',
                  onTap: () {
                    Navigator.of(context).pop();
                    _openCreateCharacter(context, ref);
                  },
                ),
                _DrawerItem(
                  icon: Icons.bookmark_outline,
                  title: 'Избранное',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/favorites');
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Настройки',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/settings');
                  },
                ),
                if (isAdmin) ...[
                  const Divider(height: 1),
                  _DrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Админ-панель',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/admin');
                    },
                  ),
                ],
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.logout,
                  title: 'Выйти',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateCharacter(
      BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
    );
    if (created == true) ref.invalidate(userCharactersProvider);
  }
}

// ─── Шапка Drawer ─────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? bannerUrl;

  const _DrawerHeader({
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.bannerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: bannerUrl != null
                ? CachedNetworkImage(
                    imageUrl: bannerUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _defaultBanner(),
                    errorWidget: (_, __, ___) => _defaultBanner(),
                  )
                : _defaultBanner(),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 24, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: SizedBox()),
          ),
        ],
      ),
    );
  }

  Widget _defaultBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
    );
  }
}

// ─── Пункт меню ───────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(title, style: TextStyle(color: effectiveColor)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}
