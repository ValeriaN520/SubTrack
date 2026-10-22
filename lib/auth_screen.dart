import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // ✅ Переменные для ошибок полей
  String? _emailError;
  String? _passwordError;
  String? _errorMessage;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _dangerColor = Color(0xFFE74C3C);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Валидация формы
  bool _validateForm() {
    bool isValid = true;

    // Валидация email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Введите email');
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Некорректный email');
      isValid = false;
    } else {
      setState(() => _emailError = null);
    }

    // Валидация пароля
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Введите пароль');
      isValid = false;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Пароль должен содержать минимум 6 символов');
      isValid = false;
    } else {
      setState(() => _passwordError = null);
    }

    return isValid;
  }

  Future<void> _login() async {
    // ✅ Сначала валидируем форму
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = 'Ошибка входа';
        if (e.message.contains('Invalid login credentials')) {
          message = 'Неверный email или пароль';
        } else if (e.message.contains('Email not confirmed')) {
          message = 'Email не подтверждён. Проверьте почту';
        } else {
          message = e.message;
        }
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Произошла ошибка. Попробуйте снова.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 48),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('SubTrack', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark)),
                        const SizedBox(height: 6),
                        const Text('Управляйте подписками и экономьте', style: TextStyle(fontSize: 15, color: _textGray)),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSegmentedControl(isLoginActive: true),
                          const SizedBox(height: 24),

                          // ✅ Поле email с подсветкой ошибки
                          _buildInputField(
                            label: 'Email',
                            controller: _emailController,
                            hintText: 'valeria@example.ru',
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                          ),
                          const SizedBox(height: 16),
                          
                          // ✅ Поле пароля с подсветкой ошибки
                          _buildPasswordField(errorText: _passwordError),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                disabledBackgroundColor: _primaryColor.withOpacity(0.6),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Войти', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(8)),
                              child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 14)),
                            ),
                          const SizedBox(height: 24),

                          const Text('Продолжая, вы соглашаетесь с условиями сервиса', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFFAEAEB2))),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({required bool isLoginActive}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE8E8ED), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                child: const Center(child: Text('Вход', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textDark))),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
              child: const Center(child: Text('Регистрация', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textGray))),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Обновлённое поле ввода с поддержкой ошибки
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: _textGray, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            border: errorText != null ? Border.all(color: _dangerColor, width: 1.5) : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, color: _textDark),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 16),
              errorText: errorText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) => setState(() {
              if (label == 'Email') _emailError = null;
            }),
          ),
        ),
      ],
    );
  }

  // ✅ Поле пароля с глазком и ошибкой
  Widget _buildPasswordField({String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Пароль', style: TextStyle(fontSize: 15, color: _textGray, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            border: errorText != null ? Border.all(color: _dangerColor, width: 1.5) : null,
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 16, color: _textDark),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 16),
              errorText: errorText,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _textGray,
                    size: 22,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) => setState(() => _passwordError = null),
          ),
        ),
      ],
    );
  }
}