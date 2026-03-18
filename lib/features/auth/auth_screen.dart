import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const int _minLength = 8;
  static const int _maxLength = 256;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _formKey.currentState?.reset();
    _passwordController.clear();
    setState(() {
      _isLogin = !_isLogin;
      _isLoading = false;
    });
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Введи пароль';
    if (v.length < _minLength) return 'Минимум $_minLength символов';
    if (v.length > _maxLength) return 'Максимум $_maxLength символов';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Нужна хотя бы одна заглавная буква';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Нужна хотя бы одна строчная буква';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Нужна хотя бы одна цифра';
    if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;'
        r"'`~/]"))) {
      return 'Нужен хотя бы один спецсимвол (!@#\$%^&* и т.д.)';
    }
    return null;
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? errorMessage;
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await repo.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await repo.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      }
    } catch (e) {
      errorMessage = _friendlyError(e.toString());
    }

    _isLoading = false;
    if (mounted) {
      setState(() {});
      if (errorMessage != null) _showError(errorMessage);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    String? errorMessage;
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      errorMessage = _friendlyError(e.toString());
    }

    _isLoading = false;
    if (mounted) {
      setState(() {});
      if (errorMessage != null) _showError(errorMessage);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Введи email чтобы сбросить пароль');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Письмо для сброса пароля отправлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(_friendlyError(e.toString()));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  String _friendlyError(String error) {
    if (error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Неверный email или пароль';
    }
    if (error.contains('email-already-in-use')) {
      return 'Этот email уже используется';
    }
    if (error.contains('weak-password') ||
        error.contains('password-does-not-meet-requirements')) {
      return 'Пароль не соответствует требованиям безопасности';
    }
    if (error.contains('invalid-email')) {
      return 'Неверный формат email';
    }
    if (error.contains('Превышено время') ||
        error.contains('TimeoutException') ||
        error.contains('timed out')) {
      return 'Превышено время ожидания. Проверь подключение к интернету';
    }
    if (error.contains('network') || error.contains('socket')) {
      return 'Проблема с сетью. Проверь подключение';
    }
    if (error.contains('отменён')) {
      return 'Вход через Google отменён';
    }
    return 'Что-то пошло не так. Попробуй ещё раз';
  }

  void _showPasswordRequirements() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Требования к паролю',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequirementRow(text: 'От 8 до 256 символов'),
            _RequirementRow(text: 'Хотя бы одна заглавная буква (A–Z)'),
            _RequirementRow(text: 'Хотя бы одна строчная буква (a–z)'),
            _RequirementRow(text: 'Хотя бы одна цифра (0–9)'),
            _RequirementRow(text: 'Хотя бы один спецсимвол (!@#\$%^&* и т.д.)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Понятно',
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2E), Color(0xFF0E0E0E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.auto_awesome, size: 60, color: Colors.deepPurple),
                    const SizedBox(height: 16),
                    const Text(
                      'AI Messenger',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Войди в свой аккаунт' : 'Создай аккаунт',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    if (!_isLogin) ...[
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Имя пользователя',
                        icon: Icons.person_outline,
                        validator: (v) {
                          return (v?.trim().isEmpty ?? true) ? 'Введи имя' : null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        return (v?.contains('@') ?? false)
                            ? null
                            : 'Неверный формат email';
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Пароль',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          if (!_isLogin)
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: _showPasswordRequirements,
                              tooltip: 'Требования к паролю',
                            ),
                        ],
                      ),
                      validator: _isLogin
                          ? (v) => (v?.isEmpty ?? true) ? 'Введи пароль' : null
                          : _validatePassword,
                    ),

                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text(
                            'Забыли пароль?',
                            style: TextStyle(color: Colors.deepPurpleAccent),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitEmailAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isLogin ? 'Войти' : 'Зарегистрироваться',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[700])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'или',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.g_mobiledata,
                          color: Colors.white,
                          size: 26,
                        ),
                        label: const Text(
                          'Войти через Google',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        GestureDetector(
                          onTap: _toggleMode,
                          child: Text(
                            _isLogin ? 'Зарегистрироваться' : 'Войти',
                            style: const TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        errorMaxLines: 2,
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String text;
  const _RequirementRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.deepPurpleAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
