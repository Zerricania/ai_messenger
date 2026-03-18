import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/character_model.dart';
import '../../providers/app_providers.dart';

class CreateCharacterScreen extends ConsumerStatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  ConsumerState<CreateCharacterScreen> createState() =>
      _CreateCharacterScreenState();
}

class _CreateCharacterScreenState
    extends ConsumerState<CreateCharacterScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  File? _pickedImage;
  CommunicationStyle _selectedStyle = CommunicationStyle.friendly;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ─── Выбор фото ─────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  // ─── Сохранить персонажа ─────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final id = const Uuid().v4();
      String? avatarUrl;

      // Загружаем фото если выбрано
      if (_pickedImage != null) {
        avatarUrl = await ref
            .read(userRepositoryProvider)
            .uploadCharacterAvatar(user.uid, id, _pickedImage!);
      }

      final name = _nameController.text.trim();
      final description = _descController.text.trim();

      final character = CharacterModel(
        id: id,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        style: _selectedStyle,
        isBuiltIn: false,
        ownerUid: user.uid,
        systemPrompt: CharacterModel.buildSystemPrompt(
          name: name,
          description: description,
          style: _selectedStyle,
        ),
      );

      await ref
          .read(userRepositoryProvider)
          .saveCharacter(user.uid, character);

      // Обновляем провайдер персонажей
      ref.invalidate(userCharactersProvider);

      if (mounted) {
        Navigator.of(context).pop(true); // возвращаем true = создан
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый персонаж'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Создать',
                style: TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Аватарка персонажа ───────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : null,
                      child: _pickedImage == null
                          ? const Icon(Icons.person,
                              size: 48, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _pickImage,
                child: const Text(
                  'Загрузить фото',
                  style: TextStyle(color: Colors.deepPurpleAccent),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Имя ─────────────────────────────────────────────────────────
            _SectionLabel('Имя персонажа'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              maxLength: 40,
              decoration: _inputDecoration('Например: Профессор Морис'),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Введи имя персонажа' : null,
            ),
            const SizedBox(height: 20),

            // ── Описание / история ───────────────────────────────────────────
            _SectionLabel('Личность и история'),
            const SizedBox(height: 4),
            Text(
              'Расскажи кто этот персонаж, как его зовут, какой у него характер, '
              'история, особенности. Чем подробнее — тем лучше.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 6,
              maxLength: 1000,
              decoration: _inputDecoration(
                'Например: Это древний маг по имени Ариус. Он прожил 500 лет, '
                'хранит тайны мироздания и говорит загадками...',
              ),
              validator: (v) => v?.trim().isEmpty ?? true
                  ? 'Опиши персонажа хотя бы в паре слов'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Стиль общения ────────────────────────────────────────────────
            _SectionLabel('Манера общения'),
            const SizedBox(height: 4),
            Text(
              'Выбери как персонаж будет разговаривать',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...CommunicationStyle.values.map((style) {
              final selected = _selectedStyle == style;
              return GestureDetector(
                onTap: () => setState(() => _selectedStyle = style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.deepPurple.withOpacity(0.2)
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Colors.deepPurpleAccent
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.deepPurpleAccent
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              style.description,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle,
                            color: Colors.deepPurpleAccent),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        counterStyle: TextStyle(color: Colors.grey[600]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
