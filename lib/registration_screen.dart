import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _salaryDayController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);

  @override
  void dispose() {
    _nameController.dispose();
    _salaryDayController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Валидация по ТЗ
  String? _validateName(String name) {
    if (name.trim().isEmpty) return 'Введите имя';
    if (name.trim().length < 2) return 'Имя должно содержать минимум 2 символа';
    return null;
  }

  String? _validateSalaryDay(String day) {
    if (day.trim().isEmpty) return 'Введите дату зарплаты';
    final d = int.tryParse(day.trim());
    if (d == null || d < 1 || d > 31) return 'Дата должна быть от 1 до 31';
    return null;
  }

  String? _validateEmail(String email) {
    if (email.trim().isEmpty) return 'Введите email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return 'Некорректный email';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Введите пароль';
    if (password.length < 6) return 'Пароль должен содержать минимум 6 символов';
    return null;
  }

  Future<void> _register() async {
    final nameError = _validateName(_nameController.text);
    final salaryError = _validateSalaryDay(_salaryDayController.text);
    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);

    final error = nameError ?? salaryError ?? emailError ?? passwordError;
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'name': _nameController.text.trim(),
          'salary_date': int.parse(_salaryDayController.text.trim()),
        },
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
        String message = 'Ошибка регистрации';
        if (e.message.contains('already registered')) {
          message = 'Пользователь с таким email уже существует';
        } else if (e.message.contains('Password should be at least')) {
          message = 'Пароль слишком короткий';
        } else {
          message = e.message;
        }
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      print('❌ ОШИБКА РЕГИСТРАЦИИ: $e');
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
                        const SizedBox(height: 32),
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
                          _buildSegmentedControl(isLoginActive: false),
                          const SizedBox(height: 24),

                          _buildInputField(label: 'Имя', controller: _nameController, hintText: 'Валерия'),
                          const SizedBox(height: 16),
                          _buildInputField(
                            label: 'Дата зарплаты',
                            controller: _salaryDayController,
                            hintText: '10 число',
                            keyboardType: TextInputType.number,
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: _textGray),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(label: 'Email', controller: _emailController, hintText: 'valeria@example.ru', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                disabledBackgroundColor: _primaryColor.withValues(alpha:0.6),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Зарегистрироваться', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Center(child: Text('Вход', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textGray))),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                child: const Center(child: Text('Регистрация', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textDark))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required String hintText, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: _textGray, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, color: _textDark),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 16),
              suffixIcon: suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 16), child: suffixIcon) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Пароль', style: TextStyle(fontSize: 15, color: _textGray, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(fontSize: 16, color: _textDark),
            decoration: const InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: Color(0xFFAEAEB2), fontSize: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}