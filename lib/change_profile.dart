import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChangeProfileScreen extends StatefulWidget {
  const ChangeProfileScreen({super.key});

  @override
  State<ChangeProfileScreen> createState() => _ChangeProfileScreenState();
}

class _ChangeProfileScreenState extends State<ChangeProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: '••••••••');

  String _selectedSalaryDate = '10 число';
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _dangerColor = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    // ✅ Загружаем текущие данные из Supabase Auth metadata
    _nameController.text = SupabaseService.userName ?? '';
    _emailController.text = SupabaseService.userEmail ?? '';
    _selectedSalaryDate = '${SupabaseService.salaryDate} число';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите имя'), backgroundColor: _dangerColor));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ Сохраняем в user_metadata через SupabaseService
      await SupabaseService.updateProfile(
        name: _nameController.text.trim(),
        reminderDays: int.parse(_selectedSalaryDate.replaceAll(' число', '')),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сохранён!'), backgroundColor: _primaryColor));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: _dangerColor));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить профиль?'),
        content: const Text('Это действие нельзя отменить. Все ваши данные будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _textDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Редактирование профиля', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Имя', style: TextStyle(fontSize: 14, color: _textGray)),
            const SizedBox(height: 8),
            _buildTextField(_nameController),
            const SizedBox(height: 20),

            const Text('Дата зарплаты', style: TextStyle(fontSize: 14, color: _textGray)),
            const SizedBox(height: 8),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSalaryDate,
                  isExpanded: true,
                  items: List.generate(31, (i) => DropdownMenuItem(value: '${i + 1} число', child: Text('${i + 1} число', style: const TextStyle(fontSize: 15, color: _textDark)))).toList(),
                  onChanged: (value) => setState(() => _selectedSalaryDate = value!),
                  icon: const Icon(Icons.keyboard_arrow_down, color: _textGray),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Email', style: TextStyle(fontSize: 14, color: _textGray)),
            const SizedBox(height: 8),
            _buildTextField(_emailController, keyboardType: TextInputType.emailAddress, readOnly: true),
            const SizedBox(height: 20),

            const Text('Пароль', style: TextStyle(fontSize: 14, color: _textGray)),
            const SizedBox(height: 8),
            _buildTextField(_passwordController, obscureText: _obscurePassword, suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Text(_obscurePassword ? 'Показать' : 'Скрыть', style: TextStyle(fontSize: 14, color: _textGray)),
            )),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _deleteProfile,
                style: OutlinedButton.styleFrom(foregroundColor: _dangerColor, side: const BorderSide(color: _dangerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Удалить профиль', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool obscureText = false, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon, bool readOnly = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 15, color: _textDark),
        decoration: InputDecoration(
          suffixIcon: suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 16), child: suffixIcon) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.credit_card_outlined, 'Подписки', 0),
          _buildNavItem(Icons.build_outlined, 'Инструменты', 1),
          _buildNavItem(Icons.bar_chart_outlined, 'Аналитика', 2),
          _buildNavItem(Icons.person_outline, 'Профиль', 3, isActive: true),
        ],
      ),
    );
  }

    Widget _buildNavItem(IconData icon, String label, int index, {bool isActive = false}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // ✅ Всегда переходим на нужную вкладку, даже если она активна
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)),
            (r) => false,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? _primaryColor : _textGray, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? _primaryColor : _textGray)),
          ],
        ),
      ),
    );
  }
}