import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/character_model.dart';
import '../../providers/app_providers.dart';
import '../characters/create_character_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  bool _editingName = false;
  bool _savingName = false;
  bool _uploadingAvatar = false;
  bool _uploadingBanner = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(String uid) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await ref.read(userRepositoryProvider).updateDisplayName(uid, name);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        setState(() => _editingName = false);
        _showSnack('Имя обновлено', success: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Ошибка: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _pickAvatar(String uid) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      await ref.read(userRepositoryProvider).uploadAvatar(uid, File(picked.path));
      ref.invalidate(currentUserProvider);
      if (mounted) _showSnack('Аватарка обновлена', success: true);
    } catch (e) {
      if (mounted) _showSnack('Ошибка загрузки аватарки');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickBanner(String uid) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 400,
    );
    if (picked == null) return;
    setState(() => _uploadingBanner = true);
    try {
      await ref.read(userRepositoryProvider).uploadBanner(uid, File(picked.path));
      ref.invalidate(currentUserProvider);
      if (mounted) _showSnack('Баннер обновлён', success: true);
    } catch (e) {
      if (mounted) _showSnack('Ошибка загрузки баннера');
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
  }

  Future<void> _deleteCharacter(
      BuildContext context, String uid, CharacterModel character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить персонажа?'),
        content: Text(
            'Персонаж «${character.name}» будет удалён. Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(userRepositoryProvider)
          .deleteCharacter(uid, character.id);
      ref.invalidate(userCharactersProvider);
      if (mounted) _showSnack('Персонаж удалён', success: true);
    } catch (e) {
      if (mounted) _showSnack('Ошибка удаления');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green[700] : Colors.red[700],
    ));
  }

  Future<void> _openCreateCharacter() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
    );
    if (created == true) ref.invalidate(userCharactersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final userCharsAsync = ref.watch(userCharactersProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (userModel) {
          final uid = firebaseUser?.uid ?? '';
          final displayName = userModel?.displayName ??
              firebaseUser?.displayName ??
              'Пользователь';
          final email = userModel?.email ?? firebaseUser?.email ?? '';
          final avatarUrl = userModel?.avatarUrl;
          final bannerUrl = userModel?.bannerUrl;

          if (!_editingName && _nameController.text.isEmpty) {
            _nameController.text = displayName;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Баннер ──────────────────────────────────────────────────
                _BannerSection(
                  bannerUrl: bannerUrl,
                  uploading: _uploadingBanner,
                  onTap: () => _pickBanner(uid),
                ),

                // ── Аватарка ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Transform.translate(
                    offset: const Offset(0, -44),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _AvatarSection(
                          avatarUrl: avatarUrl,
                          displayName: displayName,
                          uploading: _uploadingAvatar,
                          onTap: () => _pickAvatar(uid),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // ── Имя ──────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: _NameSection(
                      displayName: displayName,
                      editing: _editingName,
                      saving: _savingName,
                      controller: _nameController,
                      onEditTap: () {
                        _nameController.text = displayName;
                        setState(() => _editingName = true);
                      },
                      onSaveTap: () => _saveName(uid),
                      onCancelTap: () => setState(() => _editingName = false),
                    ),
                  ),
                ),

                // ── Информация об аккаунте ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _InfoSection(
                    email: email,
                    createdAt: userModel?.createdAt,
                    isAdmin: userModel?.isAdmin ?? false,
                  ),
                ),

                // ── Мои персонажи ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: _MyCharactersSection(
                    uid: uid,
                    userCharsAsync: userCharsAsync,
                    onCharacterTap: (id) => context.push('/chat/$id'),
                    onCreateTap: _openCreateCharacter,
                    onDeleteTap: (character) =>
                        _deleteCharacter(context, uid, character),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Секция "Мои персонажи" ───────────────────────────────────────────────────

class _MyCharactersSection extends StatelessWidget {
  final String uid;
  final AsyncValue<List<CharacterModel>> userCharsAsync;
  final void Function(String id) onCharacterTap;
  final VoidCallback onCreateTap;
  final void Function(CharacterModel character) onDeleteTap;

  const _MyCharactersSection({
    required this.uid,
    required this.userCharsAsync,
    required this.onCharacterTap,
    required this.onCreateTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          children: [
            Text(
              'Мои персонажи',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onCreateTap,
              icon: Icon(Icons.add, size: 16, color: accent),
              label: Text('Создать',
                  style: TextStyle(color: accent, fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        userCharsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const SizedBox(),
          data: (chars) {
            if (chars.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Здесь будут появляться созданные вами персонажи',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: chars.length,
              itemBuilder: (_, i) {
                final c = chars[i];
                return _CharacterCard(
                  character: c,
                  onTap: () => onCharacterTap(c.id),
                  onDelete: () => onDeleteTap(c),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ─── Карточка персонажа с кнопкой удаления ───────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final CharacterModel character;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Основной контент
            Column(
              children: [
                Expanded(
                  child: character.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: character.avatarUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[800]),
                          errorWidget: (_, __, ___) =>
                              _defaultAvatar(character.name),
                        )
                      : _defaultAvatar(character.name),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Text(
                    character.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            // Кнопка удаления — в правом верхнем углу
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 32, color: Colors.white54),
        ),
      ),
    );
  }
}

// ─── Баннер ───────────────────────────────────────────────────────────────────

class _BannerSection extends StatelessWidget {
  final String? bannerUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _BannerSection({
    required this.bannerUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
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
            child: bannerUrl != null
                ? CachedNetworkImage(
                    imageUrl: bannerUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(),
                    errorWidget: (_, __, ___) => const SizedBox(),
                  )
                : null,
          ),
          Positioned(
            bottom: 10,
            right: 12,
            child: _EditChip(
              label: uploading ? 'Загрузка...' : 'Изменить баннер',
              icon: uploading ? null : Icons.camera_alt_outlined,
              loading: uploading,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Аватарка ─────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final bool uploading;
  final VoidCallback onTap;

  const _AvatarSection({
    required this.avatarUrl,
    required this.displayName,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 4,
              ),
            ),
            child: CircleAvatar(
              radius: 44,
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
                          fontSize: 32, color: Colors.white),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: uploading
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt,
                      size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Имя ─────────────────────────────────────────────────────────────────────

class _NameSection extends StatelessWidget {
  final String displayName;
  final bool editing;
  final bool saving;
  final TextEditingController controller;
  final VoidCallback onEditTap;
  final VoidCallback onSaveTap;
  final VoidCallback onCancelTap;

  const _NameSection({
    required this.displayName,
    required this.editing,
    required this.saving,
    required this.controller,
    required this.onEditTap,
    required this.onSaveTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Введи имя',
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => onSaveTap(),
            ),
          ),
          const SizedBox(width: 8),
          if (saving)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onSaveTap,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: onCancelTap,
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            displayName,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: Colors.grey,
          onPressed: onEditTap,
        ),
      ],
    );
  }
}

// ─── Информация об аккаунте ───────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String email;
  final DateTime? createdAt;
  final bool isAdmin;

  const _InfoSection({
    required this.email,
    this.createdAt,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = createdAt != null
        ? '${createdAt!.day.toString().padLeft(2, '0')}.'
            '${createdAt!.month.toString().padLeft(2, '0')}.'
            '${createdAt!.year}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Информация об аккаунте',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(
            icon: Icons.email_outlined, label: 'Email', value: email),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Дата регистрации',
          value: dateStr,
        ),
        if (isAdmin) ...[
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Роль',
            value: 'Администратор',
            valueColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text('$label: ',
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Чип редактирования ───────────────────────────────────────────────────────

class _EditChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;

  const _EditChip({required this.label, this.icon, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          else if (icon != null)
            Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
