import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'analytics_screen.dart';
import 'change_profile.dart';
import 'notification_screen.dart';
import 'models.dart';
import 'supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subs = await SupabaseService.getSubscriptions();
      if (mounted) setState(() {
        _subscriptions = subs;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Унифицированный расчёт (та же формула, что и на главной)
  double get _monthlyTotal {
    return _subscriptions.fold<double>(0, (sum, s) {
      if (s.isTrial) return sum;
      return sum + SupabaseService.calculateMonthlyPrice(s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Профиль', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(SupabaseService.userName ?? 'Пользователь', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
                                    const SizedBox(height: 4),
                                    Text(SupabaseService.userEmail ?? '', style: const TextStyle(fontSize: 14, color: _textGray)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeProfileScreen())).then((_) => _loadData()),
                                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_outlined, color: _textDark, size: 20)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFF0F0F5)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: _textGray),
                              const SizedBox(width: 8),
                              Text('Дата зарплаты: ${SupabaseService.salaryDate}-е число', style: const TextStyle(fontSize: 14, color: _textDark)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Статистика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('${_subscriptions.length}', 'Подписок')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('${_monthlyTotal.toStringAsFixed(0)} ₽', 'В месяц')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('Инструменты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 12),

                    _buildToolRow(Icons.notifications_outlined, const Color(0xFFE0E7FF), const Color(0xFF4F46E5), 'Уведомления', 'Настройки напоминаний', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
                    const SizedBox(height: 12),
                    _buildToolRow(Icons.bar_chart_outlined, const Color(0xFFD1FAE5), const Color(0xFF10B981), 'Отчёт', 'Расходы за год', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen(showAppBar: true)))),
                    const SizedBox(height: 12),
                    // ✅ Стаж без стрелочки, считаем с регистрации
                    _buildToolRowNoArrow(Icons.emoji_events_outlined, const Color(0xFFFFF3E0), const Color(0xFFFF9F43), 'Стаж', 'С SubTrack ${SupabaseService.calculateSeniority()}'),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (r) => false);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _textDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE8E8ED))), elevation: 0),
                        child: const Text('Выйти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _primaryColor)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: _textGray)),
      ]),
    );
  }

  Widget _buildToolRow(IconData icon, Color iconBg, Color iconColor, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: _textGray))])),
            const Icon(Icons.arrow_forward_ios, size: 16, color: _textGray),
          ],
        ),
      ),
    );
  }

  // ✅ Без стрелочки
  Widget _buildToolRowNoArrow(IconData icon, Color iconBg, Color iconColor, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: _textGray))])),
        ],
      ),
    );
  }
}