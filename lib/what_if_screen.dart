import 'package:flutter/material.dart';
import 'models.dart';

class WhatIfScreen extends StatefulWidget {
  final Subscription subscription;
  const WhatIfScreen({super.key, required this.subscription});

  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  String _selectedPeriod = '6 месяцев';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 180));

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _greenColor = Color(0xFF10B981);

  double _calculateSavings() {
    final sub = widget.subscription;
    final price = sub.price;
    final now = DateTime.now();
    final billingDate = sub.billingDate;

    DateTime endDate;
    if (_selectedPeriod == 'Навсегда') {
      endDate = DateTime(now.year, 12, 31);
    } else if (_selectedPeriod == 'До даты') {
      endDate = _selectedDate;
    } else if (_selectedPeriod == '1 месяц') {
      endDate = DateTime(now.year, now.month + 1, now.day);
    } else if (_selectedPeriod == '3 месяца') {
      endDate = DateTime(now.year, now.month + 3, now.day);
    } else if (_selectedPeriod == '6 месяцев') {
      endDate = DateTime(now.year, now.month + 6, now.day);
    } else if (_selectedPeriod == 'Год') {
      endDate = DateTime(now.year + 1, now.month, now.day);
    } else {
      endDate = now;
    }

    int fullMonths = 0;
    DateTime currentDate = DateTime(now.year, now.month, billingDate);
    
    if (now.day > billingDate) {
      currentDate = DateTime(currentDate.year, currentDate.month + 1, billingDate);
    }

    while (currentDate.isBefore(endDate)) {
      fullMonths++;
      currentDate = DateTime(currentDate.year, currentDate.month + 1, billingDate);
    }

    if (fullMonths <= 0) return 0;

    switch (sub.billingPeriod) {
      case 'week': return price * 4.33 * fullMonths;
      case 'month': return price * fullMonths;
      case '3months': return (price / 3) * fullMonths;
      case '6months': return (price / 6) * fullMonths;
      case 'year': return (price / 12) * fullMonths;
      default: return price * fullMonths;
    }
  }

  // ✅ Исправленный метод получения текста периода
  String _getPeriodText() {
    if (_selectedPeriod == 'Навсегда') {
      return 'до 31 декабря ${DateTime.now().year} года';
    } else if (_selectedPeriod == 'До даты') {
      const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
      return 'до ${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
    } else {
      return 'за $_selectedPeriod';
    }
  }

  String _formatDate(DateTime date) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Кино': return const Color(0xFFFFE5E5);
      case 'Книги': return const Color(0xFFFED7AA);
      case 'Музыка': return const Color(0xFFE0E7FF);
      case 'Образование': return const Color(0xFFD1FAE5);
      case 'Работа': return const Color(0xFFE8E8ED);
      case 'Развлечения': return const Color(0xFFFFE5B4);
      case 'Связь': return const Color(0xFFC4B5FD);
      case 'Спорт': return const Color(0xFFB2F5EA);
      default: return const Color(0xFFE8E8ED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final savings = _calculateSavings();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _textDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Что если отменить?', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Row(
                children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: _getColorForCategory(sub.category), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(sub.name.isNotEmpty ? sub.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sub.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)), const SizedBox(height: 2), Text(sub.category, style: const TextStyle(fontSize: 13, color: _textGray))])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${sub.price.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)), const SizedBox(height: 2), Text(sub.periodLabel, style: const TextStyle(fontSize: 11, color: _textGray))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('На какой срок отменить?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 12),
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFE8E8ED), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedPeriod = 'Навсегда'),
                      child: Container(
                        decoration: BoxDecoration(color: _selectedPeriod == 'Навсегда' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: _selectedPeriod == 'Навсегда' ? [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 8, offset: const Offset(0, 2))] : null),
                        child: const Center(child: Text('Навсегда', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedPeriod = 'До даты'),
                      child: Container(
                        decoration: BoxDecoration(color: _selectedPeriod == 'До даты' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: _selectedPeriod == 'До даты' ? [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 8, offset: const Offset(0, 2))] : null),
                        child: const Center(child: Text('До даты', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedPeriod != 'Навсегда') ...[
              Row(children: [Expanded(child: _buildPeriodButton('1 месяц')), const SizedBox(width: 12), Expanded(child: _buildPeriodButton('3 месяца'))]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: _buildPeriodButton('6 месяцев')), const SizedBox(width: 12), Expanded(child: _buildPeriodButton('Год'))]),
              const SizedBox(height: 20),
              const Text('Или выберите дату', style: TextStyle(fontSize: 14, color: _textGray)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _primaryColor)), child: child!),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _selectedPeriod = 'До даты';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: 15, color: _textDark)),
                      const Icon(Icons.calendar_today_outlined, size: 18, color: _textGray),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFE8F8F0), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.eco, color: _greenColor, size: 20), const SizedBox(width: 8), const Text('Экономия', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _greenColor))]),
                  const SizedBox(height: 8),
                  Text('${savings.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _greenColor)),
                  const SizedBox(height: 4),
                  // ✅ Исправлено: вызов метода, а не передача функции
                  Text('Без списаний ${_getPeriodText()}', style: const TextStyle(fontSize: 13, color: _greenColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _textGray, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Как это работает', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                        const SizedBox(height: 4),
                        const Text('Показываем, сколько денег останется у вас, если приостановить эту подписку на выбранный срок.', style: TextStyle(fontSize: 13, color: _textGray)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Понятно', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFEDE9FE) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _primaryColor : const Color(0xFFE8E8ED), width: 1.5)),
        child: Center(child: Text(period, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? _primaryColor : _textDark))),
      ),
    );
  }
}