import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Акцентные цвета ──────────────────────────────────────────────────────────

class AccentColor {
  final String label;
  final Color color;
  const AccentColor(this.label, this.color);
}

const accentColors = [
  AccentColor('Фиолетовый', Color(0xFF7C3AED)),
  AccentColor('Синий', Color(0xFF2563EB)),
  AccentColor('Розовый', Color(0xFFDB2777)),
  AccentColor('Зелёный', Color(0xFF059669)),
  AccentColor('Оранжевый', Color(0xFFD97706)),
  AccentColor('Красный', Color(0xFFDC2626)),
  AccentColor('Голубой', Color(0xFF0891B2)),
];

// ─── Модель настроек темы ─────────────────────────────────────────────────────

class ThemeSettings {
  final bool isDark;
  final int accentIndex;

  const ThemeSettings({
    this.isDark = true,
    this.accentIndex = 0,
  });

  // Всегда насыщенный цвет из палитры — не разбавляется Material 3
  Color get accent => accentColors[accentIndex].color;

  ThemeSettings copyWith({bool? isDark, int? accentIndex}) => ThemeSettings(
        isDark: isDark ?? this.isDark,
        accentIndex: accentIndex ?? this.accentIndex,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ThemeNotifier extends Notifier<ThemeSettings> {
  static const _keyDark = 'theme_is_dark';
  static const _keyAccent = 'theme_accent_index';

  @override
  ThemeSettings build() {
    _load();
    return const ThemeSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_keyDark) ?? true;
    final accentIndex = prefs.getInt(_keyAccent) ?? 0;
    state = ThemeSettings(isDark: isDark, accentIndex: accentIndex);
  }

  Future<void> setDark(bool value) async {
    state = state.copyWith(isDark: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDark, value);
  }

  Future<void> setAccent(int index) async {
    state = state.copyWith(accentIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccent, index);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeSettings>(
  ThemeNotifier.new,
);

// ─── Утилита: получить насыщенный акцентный цвет из контекста ────────────────

/// Возвращает оригинальный насыщенный цвет из палитры.
/// В отличие от Theme.of(context).colorScheme.primary,
/// этот цвет не разбавляется алгоритмом Material 3.
Color getAccentColor(BuildContext context, WidgetRef ref) {
  return ref.watch(themeProvider).accent;
}

// ─── Генератор ThemeData ──────────────────────────────────────────────────────

ThemeData buildTheme(ThemeSettings settings) {
  final accent = settings.accent;
  final isDark = settings.isDark;

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: isDark ? Colors.white : Colors.black87,
    ),
    cardTheme: CardThemeData(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      shadowColor: Colors.black45,
      clipBehavior: Clip.hardEdge,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: accent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? accent : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accent.withValues(alpha: 0.4)
            : null,
      ),
    ),
  );
}
