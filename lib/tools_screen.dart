import 'package:flutter/material.dart';
import 'analytics_screen.dart';
import 'recomendator_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Инструменты', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 6),
            const Text('Помощники для экономии и защиты', style: TextStyle(fontSize: 15, color: _textGray)),
            const SizedBox(height: 28),
            // ✅ Пункт 5: Убрана карточка "Защита пробного периода"
            _buildToolCard(
              icon: Icons.calendar_month_outlined,
              iconBg: const Color(0xFFE0E7FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'Рекомендатор дат',
              subtitle: 'Подобрать день для новой подписки',
              link: 'Учитывает зарплату и списания',
              linkColor: const Color(0xFF4F46E5),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RecomendatorScreen()));
              },
            ),
            const SizedBox(height: 16),
            _buildToolCard(
              icon: Icons.trending_up_outlined,
              iconBg: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF10B981),
              title: 'Отчёт по тратам',
              subtitle: 'Сколько потрачено за период',
              link: 'Доступен отчёт за год',
              linkColor: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen(showAppBar: true)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle, required String link, required Color linkColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 13, color: _textGray)), const SizedBox(height: 6), Text(link, style: TextStyle(fontSize: 12, color: linkColor, fontWeight: FontWeight.w500))])),
            Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0F0F5), shape: BoxShape.circle), child: const Icon(Icons.arrow_forward, color: _textGray, size: 18)),
          ],
        ),
      ),
    );
  }
}