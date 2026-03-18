import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final themeSettings = ref.watch(themeProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final userModel = userAsync.asData?.value;
    final displayName =
        userModel?.displayName ?? firebaseUser?.displayName ?? 'Пользователь';
    final email = userModel?.email ?? firebaseUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // ── Аккаунт ──────────────────────────────────────────────────────
          _SectionHeader('Аккаунт'),
          _InfoTile(
            icon: Icons.person_outline,
            label: 'Имя пользователя',
            value: displayName,
          ),
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          _ActionTile(
            icon: Icons.lock_outline,
            label: 'Сменить пароль',
            onTap: () => _showChangePassword(context, ref),
          ),

          // ── Оформление ───────────────────────────────────────────────────
          _SectionHeader('Оформление'),
          SwitchListTile(
            secondary: Icon(
              themeSettings.isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            title: const Text('Тёмная тема'),
            subtitle: Text(themeSettings.isDark ? 'Включена' : 'Выключена'),
            value: themeSettings.isDark,
            onChanged: (v) => ref.read(themeProvider.notifier).setDark(v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.palette_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 16),
                const Text('Акцентный цвет', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 4, 16, 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(accentColors.length, (i) {
                final ac = accentColors[i];
                final selected = themeSettings.accentIndex == i;
                return GestureDetector(
                  onTap: () => ref.read(themeProvider.notifier).setAccent(i),
                  child: Tooltip(
                    message: ac.label,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ac.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: ac.color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Уведомления ──────────────────────────────────────────────────
          _SectionHeader('Уведомления'),
          _SwitchPrefTile(
            icon: Icons.notifications_outlined,
            label: 'Push-уведомления',
            subtitle: 'Скоро',
            value: false,
            onChanged: null,
          ),

          // ── О приложении ─────────────────────────────────────────────────
          _SectionHeader('О приложении'),
          _InfoTile(
            icon: Icons.info_outline,
            label: 'Версия',
            value: '1.0.0',
          ),
          _ActionTile(
            icon: Icons.logout,
            label: 'Выйти из аккаунта',
            color: Colors.redAccent,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Выйти?'),
                  content:
                      const Text('Вы уверены что хотите выйти из аккаунта?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Выйти',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

// ─── Лист смены пароля ────────────────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Состояние валидации полей
  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _currentController.addListener(_validate);
    _newController.addListener(_validate);
    _confirmController.addListener(_validate);
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Проверяем можно ли активировать кнопку
  bool get _canSubmit {
    return _currentController.text.isNotEmpty &&
        _newController.text.length >= 8 &&
        _newError == null &&
        _confirmController.text == _newController.text &&
        !_loading;
  }

  void _validate() {
    setState(() {
      // Валидация нового пароля (только если не пустой)
      final newVal = _newController.text;
      if (newVal.isEmpty) {
        _newError = null;
      } else if (newVal.length < 8) {
        _newError = 'Минимум 8 символов';
      } else if (!newVal.contains(RegExp(r'[A-Z]'))) {
        _newError = 'Нужна заглавная буква';
      } else if (!newVal.contains(RegExp(r'[a-z]'))) {
        _newError = 'Нужна строчная буква';
      } else if (!newVal.contains(RegExp(r'[0-9]'))) {
        _newError = 'Нужна цифра';
      } else if (!newVal.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;'
          r"'`~/]"))) {
        _newError = 'Нужен спецсимвол';
      } else {
        _newError = null;
      }

      // Валидация подтверждения
      final confirmVal = _confirmController.text;
      if (confirmVal.isEmpty) {
        _confirmError = null;
      } else if (confirmVal != newVal) {
        _confirmError = 'Пароли не совпадают';
      } else {
        _confirmError = null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Нет пользователя');

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentController.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newController.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Пароль успешно изменён'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _currentError = 'Неверный пароль';
        } else if (e.code == 'weak-password') {
          _newError = 'Пароль слишком простой';
        } else if (e.code == 'requires-recent-login') {
          _currentError = 'Войдите заново и попробуйте снова';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(user!.email!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Письмо для сброса пароля отправлено на ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[200]!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Text(
                'Сменить пароль',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Текущий пароль
          _PasswordField(
            controller: _currentController,
            label: 'Текущий пароль',
            obscure: _obscureCurrent,
            onToggle: () =>
                setState(() => _obscureCurrent = !_obscureCurrent),
            errorText: _currentError,
            fillColor: fillColor,
          ),
          const SizedBox(height: 12),

          // Новый пароль
          _PasswordField(
            controller: _newController,
            label: 'Новый пароль',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            errorText: _newError,
            fillColor: fillColor,
          ),
          const SizedBox(height: 12),

          // Подтверждение
          _PasswordField(
            controller: _confirmController,
            label: 'Повтори новый пароль',
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            errorText: _confirmError,
            fillColor: fillColor,
            // Зелёная галочка если совпадает
            suffixExtra: _confirmController.text.isNotEmpty &&
                    _confirmController.text == _newController.text
                ? const Icon(Icons.check_circle,
                    color: Colors.green, size: 20)
                : null,
          ),
          const SizedBox(height: 20),

          // Кнопка сохранить
          SizedBox(
            width: double.infinity,
            height: 48,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit ? accent : Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Сохранить',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Забыли пароль?
          Center(
            child: TextButton(
              onPressed: _resetPassword,
              child: Text(
                'Забыли пароль? Сбросить на email',
                style: TextStyle(color: accent, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Поле пароля ─────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? errorText;
  final Color fillColor;
  final Widget? suffixExtra;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.fillColor,
    this.errorText,
    this.suffixExtra,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: errorText != null
              ? const BorderSide(color: Colors.redAccent, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: errorText != null
                ? Colors.redAccent
                : Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        // Ошибка под полем
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suffixExtra != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: suffixExtra!,
              ),
            IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c)),
      trailing: Icon(Icons.chevron_right, color: c),
      onTap: onTap,
    );
  }
}

class _SwitchPrefTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool)? onChanged;

  const _SwitchPrefTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
