import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'home_screen.dart'; 

class AnalyticsScreen extends StatefulWidget {
  final bool showAppBar;
  const AnalyticsScreen({super.key, this.showAppBar = false});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isYear = true;
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getAnalyticsData(isYear: _isYear);
      if (mounted) setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5F7),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: _textDark), onPressed: () => Navigator.pop(context)),
          title: const Text('Отчёт по тратам', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: false,
        ),
        body: _buildContent(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }
    return _buildContent();
  }

  Widget _buildContent() {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Отчёт по тратам', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 6),
                    const Text('Сколько потрачено за период', style: TextStyle(fontSize: 15, color: _textGray)),
                    const SizedBox(height: 20),

                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFE8E8ED), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() => _isYear = false);
                                _loadAnalytics();
                              },
                              child: Container(
                                decoration: BoxDecoration(color: !_isYear ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: !_isYear ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))] : null),
                                child: const Center(child: Text('Полгода', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark))),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() => _isYear = true);
                                _loadAnalytics();
                              },
                              child: Container(
                                decoration: BoxDecoration(color: _isYear ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: _isYear ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))] : null),
                                child: const Center(child: Text('Год', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('За ${_isYear ? "год" : "полгода"} вы потратили', style: TextStyle(fontSize: 14, color: _textGray)),
                          const SizedBox(height: 8),
                          Text('${(_analyticsData?['totalSpent'] ?? 0).toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _textDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Разбивка по категориям', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Column(
                        children: [
                          ...(_analyticsData?['categoryTotals'] as Map<String, double>? ?? {}).entries.map((entry) => _buildCategoryRow(entry.key, entry.value, _analyticsData?['totalSpent'] ?? 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Разбивка по сервисам', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Column(
                        children: [
                          ...(_analyticsData?['serviceTotals'] as Map<String, double>? ?? {}).entries.map((entry) => _buildServiceRow(entry.key, entry.value)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Интересные факты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildFact(Icons.trending_down, 'Вы сэкономили ${(_analyticsData?['totalSpent'] ?? 0 * 0.1).toStringAsFixed(0)} ₽ благодаря паузам'),
                          const SizedBox(height: 12),
                          _buildFact(Icons.calendar_month, 'Средний расход в день: ${(_analyticsData?['avgPerDay'] ?? 0).toStringAsFixed(0)} ₽'),
                          const SizedBox(height: 12),
                          _buildFact(Icons.people_outline, 'Всего подписок: ${_analyticsData?['totalSubs'] ?? 0}'),
                          const SizedBox(height: 12),
                          _buildFact(Icons.emoji_events, 'Годовой прогноз: ${(_analyticsData?['yearlyForecast'] ?? 0).toStringAsFixed(0)} ₽'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryRow(String name, double amount, double total) {
    final percent = total > 0 ? ((amount / total) * 100).toStringAsFixed(0) : '0';
    final color = _getCategoryColor(name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14, color: _textDark))),
          Text('${amount.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
          const SizedBox(width: 16),
          Text('$percent%', style: TextStyle(fontSize: 13, color: _textGray)),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String name, double amount) {
  // ✅ Находим категорию сервиса по имени (берём из подписок)
  final category = _getServiceCategory(name);
  final color = _getColorForCategory(category);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2), // ✅ Цветной фон по категории
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), // ✅ Цветная буква
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 14, color: _textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text('${amount.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
      ],
    ),
  );
}

// ✅ Метод для получения категории сервиса по имени
String _getServiceCategory(String serviceName) {
  // Ищем в данных аналитики — берём из сервиса
  // Для простоты используем маппинг по популярным сервисам
  final nameLower = serviceName.toLowerCase();
  
  if (nameLower.contains('кинопоиск') || nameLower.contains('wink') || nameLower.contains('okko') || nameLower.contains('ivi')) return 'Кино';
  if (nameLower.contains('музык') || nameLower.contains('spotify') || nameLower.contains('яндекс музыка')) return 'Музыка';
  if (nameLower.contains('litres') || nameLower.contains('книг') || nameLower.contains('bookmate')) return 'Книги';
  if (nameLower.contains('coursera') || nameLower.contains('skillbox') || nameLower.contains('stepik')) return 'Образование';
  if (nameLower.contains('notion') || nameLower.contains('trello') || nameLower.contains('figma')) return 'Работа';
  if (nameLower.contains('yandex') || nameLower.contains('яндекс') || nameLower.contains('plus')) return 'Развлечения';
  if (nameLower.contains('мтс') || nameLower.contains('билайн') || nameLower.contains('tele2')) return 'Связь';
  if (nameLower.contains('fit') || nameLower.contains('спорт') || nameLower.contains('gym')) return 'Спорт';
  
  return 'Другое';
}

// ✅ Метод получения цвета по категории (такой же как в home_screen)
    Color _getColorForCategory(String category) {
      switch (category) {
        case 'Кино': return const Color(0xFFFF4444);
        case 'Книги': return const Color(0xFFFF9F43);
        case 'Музыка': return const Color(0xFF6C47FF);
        case 'Образование': return const Color(0xFF10B981);
        case 'Работа': return const Color(0xFF6B6B6B);
        case 'Развлечения': return const Color(0xFFFFB800);
        case 'Связь': return const Color(0xFF9C27B0);
        case 'Спорт': return const Color(0xFF14B8A6);
        default: return const Color(0xFF6B6B6B);
      }
    }
  Widget _buildFact(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _textDark))),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Развлечения': return const Color(0xFF6C47FF);
      case 'Работа': return const Color(0xFF4F46E5);
      case 'Кино': return const Color(0xFFE74C3C);
      case 'Музыка': return const Color(0xFF9C27B0);
      case 'Образование': return const Color(0xFF10B981);
      case 'Спорт': return const Color(0xFF14B8A6);
      case 'Связь': return const Color(0xFF8B5CF6);
      case 'Книги': return const Color(0xFFFF9F43);
      default: return const Color(0xFF6B6B6B);
    }
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
          _buildNavItem(Icons.bar_chart_outlined, 'Аналитика', 2, isActive: true),
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
          if (isActive) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)), (r) => false);
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