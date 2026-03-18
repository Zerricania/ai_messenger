import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Экран рассылки уведомлений.
///
/// FCM V1 API требует OAuth2 токен из Service Account —
/// его нельзя безопасно хранить в APK.
/// Поэтому рассылка происходит через Firebase Console вручную.
/// Этот экран содержит инструкцию и быстрый доступ к нужным данным.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label скопировано'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[200]!;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рассылка уведомлений'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Инфо-блок ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Как отправить уведомление',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'FCM V1 API требует серверную авторизацию — '
                    'ключ нельзя хранить в приложении.\n\n'
                    'Отправляй уведомления через Firebase Console:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Шаги ─────────────────────────────────────────────────────
            _SectionLabel('Инструкция'),
            const SizedBox(height: 12),

            _StepCard(
              number: '1',
              title: 'Открой Firebase Console',
              subtitle: 'console.firebase.google.com → твой проект',
              color: cardColor,
            ),
            _StepCard(
              number: '2',
              title: 'Перейди в Messaging',
              subtitle: 'Левое меню → Engage → Messaging',
              color: cardColor,
            ),
            _StepCard(
              number: '3',
              title: 'Создай уведомление',
              subtitle:
                  'New campaign → Firebase Notification messages → заполни заголовок и текст',
              color: cardColor,
            ),
            _StepCard(
              number: '4',
              title: 'Выбери аудиторию',
              subtitle:
                  'Target → App → выбери ai_messenger (Android) → отправь всем или конкретному токену',
              color: cardColor,
            ),
            _StepCard(
              number: '5',
              title: 'Отправь',
              subtitle:
                  'Next → Next → Publish. Уведомление придёт всем у кого установлено приложение.',
              color: cardColor,
            ),

            const SizedBox(height: 24),

            // ── Подготовь текст заранее ───────────────────────────────────
            _SectionLabel('Подготовь текст заранее'),
            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Заголовок уведомления',
                hintText: 'Например: Новый персонаж!',
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle:
                    TextStyle(color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _bodyController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: 'Текст уведомления',
                hintText:
                    'Например: Познакомься с новым персонажем — Детективом Адамом!',
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle:
                    TextStyle(color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 12),

            // Кнопки копирования
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(
                        _titleController.text, 'Заголовок'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: accent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Копировать заголовок'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _copyToClipboard(_bodyController.text, 'Текст'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: accent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Копировать текст'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Ссылка на консоль ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.open_in_new, color: accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(
                        'https://console.firebase.google.com',
                        'Ссылка',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Firebase Console',
                            style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'console.firebase.google.com',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: accent),
                    onPressed: () => _copyToClipboard(
                      'https://console.firebase.google.com',
                      'Ссылка',
                    ),
                    tooltip: 'Копировать ссылку',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;

  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
