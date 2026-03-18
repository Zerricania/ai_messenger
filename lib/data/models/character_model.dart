/// Манеры общения — пользователь выбирает из этого списка при создании персонажа
enum CommunicationStyle {
  friendly('Дружелюбный', 'Общается тепло, поддерживающе и позитивно'),
  sarcastic('Саркастичный', 'Остроумный, с иронией и лёгким сарказмом'),
  formal('Формальный', 'Официальный стиль, чёткие и структурированные ответы'),
  dramatic('Драматичный', 'Театральный, пафосный, эмоциональный стиль'),
  playful('Игривый', 'Лёгкий, шутливый, непосредственный стиль общения'),
  wise('Мудрый', 'Глубокий, философский, говорит притчами и метафорами'),
  direct('Прямой', 'Без лишних слов, коротко и по делу');

  final String label;
  final String description;

  const CommunicationStyle(this.label, this.description);
}

class CharacterModel {
  final String id;
  final String name;
  final String description; // личность, история — задаёт пользователь
  final String? avatarUrl;
  final CommunicationStyle style;
  final bool isBuiltIn; // true = встроенный персонаж, false = созданный пользователем
  final String? ownerUid; // uid создателя, null для встроенных
  final String systemPrompt; // итоговый промпт для AI

  const CharacterModel({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.style,
    this.isBuiltIn = false,
    this.ownerUid,
    required this.systemPrompt,
  });

  factory CharacterModel.fromMap(Map<String, dynamic> map) => CharacterModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        avatarUrl: map['avatarUrl'] as String?,
        style: CommunicationStyle.values.firstWhere(
          (s) => s.name == map['style'],
          orElse: () => CommunicationStyle.friendly,
        ),
        isBuiltIn: map['isBuiltIn'] as bool? ?? false,
        ownerUid: map['ownerUid'] as String?,
        systemPrompt: map['systemPrompt'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'style': style.name,
        'isBuiltIn': isBuiltIn,
        'ownerUid': ownerUid,
        'systemPrompt': systemPrompt,
      };

  /// Генерирует системный промпт на основе описания и стиля общения
  static String buildSystemPrompt({
    required String name,
    required String description,
    required CommunicationStyle style,
  }) {
    final styleInstruction = switch (style) {
      CommunicationStyle.friendly =>
        'Общайся тепло, дружелюбно и поддерживающе. Будь искренним и позитивным.',
      CommunicationStyle.sarcastic =>
        'Общайся с лёгким сарказмом и остроумием. Шути, но не обижай.',
      CommunicationStyle.formal =>
        'Общайся официально и структурированно. Избегай сленга.',
      CommunicationStyle.dramatic =>
        'Общайся театрально и пафосно. Драматизируй каждую мелочь.',
      CommunicationStyle.playful =>
        'Общайся игриво и шутливо. Будь непосредственным и весёлым.',
      CommunicationStyle.wise =>
        'Общайся мудро и философски. Используй метафоры и задавай глубокие вопросы.',
      CommunicationStyle.direct =>
        'Общайся прямо и лаконично. Никаких лишних слов.',
    };

    return '''
Ты — $name.
$description

Стиль общения: $styleInstruction

Пиши естественно, как в мессенджере. Без звёздочек, кавычек и лишнего форматирования.
Отвечай от первого лица, оставаясь в образе.
''';
  }
}
