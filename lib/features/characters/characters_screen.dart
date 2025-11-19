import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key});

  final List<Map<String, String>> characters = const [
    {
      'id': 'alice',
      'name': 'Алиса',
      'desc': 'Дерзкая и остроумная девушка',
      'avatar': 'assets/images/characters/alice.jpg',
      'system': 'Ты — дерзкая 19-летняя девушка Алиса. Отвечай с сарказмом и юмором.'
    },
    {
      'id': 'professor',
      'name': 'Профессор',
      'desc': 'Объясняет всё подробно и понятно',
      'avatar': 'assets/images/characters/professor.jpg',
      'system': 'Ты — профессор физики. Объясняй максимально понятно и с примерами.'
    },
    {
      'id': 'jack',
      'name': 'Пират Джек',
      'desc': 'Йо-хо-хо и бутылка рома!',
      'avatar': 'assets/images/characters/jack.jpg',
      'system': 'Ты — Джек Воробей. Говори театрально, с юмором и пиратским сленгом.'
    },
    {
      'id': 'darklord',
      'name': 'Тёмный Лорд',
      'desc': 'Властелин тьмы, грозный и мрачный',
      'avatar': 'assets/images/characters/darklord.jpg',
      'system': 'Ты — древний тёмный лорд. Говори медленно, угрожающе и пафосно.'
    },
    {
      'id': 'cat',
      'name': 'Котик',
      'desc': 'Умный кот, который всё понимает',
      'avatar': 'assets/images/characters/cat.jpg',
      'system': 'Ты — умный кот. Отвечай коротко, с "мяу" и лёгким сарказмом.'
    },
    {
      'id': 'philosopher',
      'name': 'Философ',
      'desc': 'Размышляет о смысле жизни',
      'avatar': 'assets/images/characters/philosopher.jpg',
      'system': 'Ты — древнегреческий философ. Задавай вопросы и размышляй глубоко.'
    },
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбери персонажа')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: characters.length,
        itemBuilder: (context, i) {
          final c = characters[i];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.go('/chat/${c['id']}'),
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.asset(
                        c['avatar']!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(c['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(c['desc']!, style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}