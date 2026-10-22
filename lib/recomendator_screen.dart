import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'supabase_service.dart';

class RecomendatorScreen extends StatefulWidget {
  const RecomendatorScreen({super.key});

  @override
  State<RecomendatorScreen> createState() => _RecomendatorScreenState();
}

class _RecomendatorScreenState extends State<RecomendatorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  String _selectedPeriod = 'Месяц';
  bool _showRecommendations = false;
  bool _isLoading = false;

  // ✅ Переменные для ошибок валидации
  String? _nameError;
  String? _costError;

  int _recSalaryDate = 10;
  int _recClusterDate = 15;
  int _recEmptyDate = 22;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _dangerColor = Color(0xFFE74C3C);

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  // ✅ Валидация формы
  bool _validateForm() {
    bool isValid = true;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Введите название сервиса');
      isValid = false;
    } else {
      setState(() => _nameError = null);
    }

    final costText = _costController.text.trim();
    if (costText.isEmpty) {
      setState(() => _costError = 'Введите стоимость');
      isValid = false;
    } else if (!RegExp(r'^\d+([,.]\d+)?$').hasMatch(costText)) {
      setState(() => _costError = 'Некорректная сумма');
      isValid = false;
    } else {
      final cost = double.tryParse(costText.replaceAll(',', '.'));
      if (cost == null || cost <= 0) {
        setState(() => _costError = 'Сумма должна быть больше 0');
        isValid = false;
      } else {
        setState(() => _costError = null);
      }
    }

    return isValid;
  }

  Future<void> _analyzeAndRecommend() async {
    if (!_validateForm()) return; // ✅ Проверка перед анализом

    setState(() => _isLoading = true);

    try {
      final salaryDate = SupabaseService.salaryDate;
      final subs = await SupabaseService.getSubscriptions();

      _recSalaryDate = salaryDate;

      Map<int, int> dateCounts = {};
      for (var sub in subs) {
        dateCounts[sub.billingDate] = (dateCounts[sub.billingDate] ?? 0) + 1;
      }

      if (dateCounts.isEmpty) {
        _recClusterDate = (salaryDate + 5) > 31 ? 31 : salaryDate + 5;
      } else {
        int maxCount = 0;
        int bestDate = salaryDate;
        dateCounts.forEach((date, count) {
          if (count > maxCount) {
            maxCount = count;
            bestDate = date;
          }
        });
        _recClusterDate = bestDate;
      }

      Set<int> usedDates = dateCounts.keys.toSet();
      usedDates.add(salaryDate);

      _recEmptyDate = 1;
      for (int i = 1; i <= 31; i++) {
        if (!usedDates.contains(i)) {
          _recEmptyDate = i;
          break;
        }
      }
      
      if (usedDates.length == 31) {
        _recEmptyDate = 31;
      }

      setState(() {
        _showRecommendations = true;
        _isLoading = false;
      });
    } catch (e) {
      print(' Ошибка аналитики дат: $e');
      setState(() => _isLoading = false);
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
        title: const Text('Рекомендатор дат', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Введите данные — приложение проанализирует ваши расходы и подскажет 3 удобные даты', style: TextStyle(fontSize: 13, color: _primaryColor.withValues(alpha: 0.8)))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Название сервиса', style: TextStyle(fontSize: 14, color: _textGray)),
            const SizedBox(height: 8),
            // ✅ Поле с подсветкой ошибки
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                border: _nameError != null ? Border.all(color: _dangerColor, width: 1.5) : null,
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 15, color: _textDark),
                decoration: InputDecoration(
                  hintText: 'Например, Яндекс Музыка',
                  hintStyle: TextStyle(color: _textGray),
                  errorText: _nameError,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() => _nameError = null),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Стоимость', style: TextStyle(fontSize: 14, color: _textGray)),
                      const SizedBox(height: 8),
                      // ✅ Поле с подсветкой ошибки
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          border: _costError != null ? Border.all(color: _dangerColor, width: 1.5) : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _costController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 15, color: _textDark),
                                decoration: InputDecoration(
                                  errorText: _costError,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onChanged: (_) => setState(() => _costError = null),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text('₽', style: TextStyle(fontSize: 15, color: _textGray)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Период списания', style: TextStyle(fontSize: 14, color: _textGray)),
                      const SizedBox(height: 8),
                      _buildDropdownField(_selectedPeriod, ['Месяц', 'Год', 'Неделя'], (value) => setState(() => _selectedPeriod = value!)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _analyzeAndRecommend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Подобрать даты', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_showRecommendations && !_isLoading) ...[
              _buildRecommendationCard(
                icon: Icons.account_balance_wallet,
                iconColor: _primaryColor,
                title: 'День зарплаты',
                subtitle: '$_recSalaryDate-го числа',
                description: 'Деньги уже на счёте — списание пройдёт максимально комфортно для бюджета.',
              ),
              const SizedBox(height: 12),
              _buildRecommendationCard(
                icon: Icons.layers_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'День скопления подписок',
                subtitle: '$_recClusterDate-го числа',
                description: 'В этот день у вас уже есть другие платежи. Объедините их, чтобы проще контролировать расходы.',
              ),
              const SizedBox(height: 12),
              _buildRecommendationCard(
                icon: Icons.event_available_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: 'Пустой день месяца',
                subtitle: '$_recEmptyDate-го числа',
                description: 'В этот день у вас нет других регулярных списаний, что снизит финансовую нагрузку.',
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDropdownField(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 15, color: _textDark)))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: _textGray),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textDark)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: _textGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.credit_card_outlined, 'Подписки', 0),
          _buildNavItem(Icons.build_outlined, 'Инструменты', 1, isActive: true),
          _buildNavItem(Icons.bar_chart_outlined, 'Аналитика', 2),
          _buildNavItem(Icons.person_outline, 'Профиль', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isActive = false}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isActive) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomeScreen(initialIndex: index)), (route) => false);
          }
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