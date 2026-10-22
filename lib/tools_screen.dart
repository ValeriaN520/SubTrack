import 'package:flutter/material.dart';
import 'notification_screen.dart';
import 'recomendator_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const Color _primaryColor = Color(0xFF6C47FF);
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
            // ✅ Возвращаем оригинальный подзаголовок
            const Text('Помощники для экономии и защиты', style: TextStyle(fontSize: 15, color: _textGray)),
            const SizedBox(height: 20),

            _buildToolRow(
              icon: Icons.auto_awesome_outlined,
              iconBg: const Color(0xFFEDE9FE),
              iconColor: _primaryColor,
              title: 'Рекомендатор дат',
              subtitle: 'Подберём удобные даты для новых подписок',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecomendatorScreen())),
            ),
            const SizedBox(height: 12),

            // ✅ Кнопка "Уведомления" вместо "Отчет"
            _buildToolRow(
              icon: Icons.notifications_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFFF9F43),
              title: 'Уведомления',
              subtitle: 'Напоминания и приглашения',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildToolRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: _textGray)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: _textGray),
          ],
        ),
      ),
    );
  }
}