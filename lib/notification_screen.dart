import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'subscription_screen.dart';
import 'models.dart';
import 'supabase_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _reminderPeriod = '2 дня';
  List<AppNotification> _notifications = [];
  List<Invitation> _invitations = [];
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _dangerColor = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await SupabaseService.getNotifications();
      final invitations = await SupabaseService.getPendingInvitations();
      final reminders = await SupabaseService.getReminders();
      
      // ✅ Читаем настройку срока напоминаний из БД
      final savedDays = SupabaseService.client.auth.currentUser?.userMetadata?['reminder_days'] as int? ?? 2;
      String periodText;
      if (savedDays == 1) {
        periodText = '1 день';
      } else if (savedDays == 3) {
        periodText = '3 дня';
      } else {
        periodText = '2 дня';
      }
      
      // ✅ Фильтруем reminders: убираем те, где 0 дней (они уже видны в основном списке)
      final now = DateTime.now();
      final filteredReminders = reminders.where((r) {
        final remindAt = DateTime.parse(r['remind_at'] as String);
        final daysLeft = remindAt.difference(now).inDays;
        return daysLeft > 0; // ✅ Показываем только если больше 0 дней
      }).toList();
      
      if (mounted) setState(() {
        _notifications = notifications;
        _invitations = invitations;
        _reminders = filteredReminders;
        _reminderPeriod = periodText;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки уведомлений: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Очистить всё?'),
        content: const Text('Все уведомления и напоминания будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.clearNotifications();
      await SupabaseService.clearReminders();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Всё очищено'), backgroundColor: _primaryColor),
        );
      }
    }
  }

  // ✅ Переход на подписку по уведомлению о списании
  Future<void> _openSubscriptionFromReminder(Map<String, dynamic> reminder) async {
    final subscriptionId = reminder['subscription_id'] as String;
    
    try {
      final sub = await SupabaseService.getSubscriptionById(subscriptionId);
      if (sub != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubscriptionScreen(subscription: sub)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подписка не найдена'), backgroundColor: _dangerColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: _dangerColor),
        );
      }
    }
  }

  // ✅ Переход на подписку из уведомления в истории
  Future<void> _openSubscriptionFromNotification(AppNotification notification) async {
    final subscriptionId = notification.relatedSubscriptionId;
    if (subscriptionId == null) return;
    
    try {
      final sub = await SupabaseService.getSubscriptionById(subscriptionId);
      if (sub != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubscriptionScreen(subscription: sub)),
        );
      }
    } catch (e) {
      print('❌ Ошибка перехода: $e');
    }
  }

  Future<void> _acceptInvitation(Invitation invitation) async {
    try {
      await SupabaseService.acceptInvitation(invitation.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Приглашение принято! Подписка добавлена.'), backgroundColor: _primaryColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: _dangerColor),
        );
      }
    }
  }

  Future<void> _declineInvitation(Invitation invitation) async {
    try {
      await SupabaseService.declineInvitation(invitation.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Приглашение отклонено'), backgroundColor: _textGray),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: _dangerColor),
        );
      }
    }
  }

  Future<void> _saveReminderPeriod() async {
    final days = int.parse(_reminderPeriod.replaceAll(' дня', '').replaceAll(' дней', '').replaceAll(' день', ''));
    
    final metadata = SupabaseService.client.auth.currentUser?.userMetadata ?? {};
    metadata['reminder_days'] = days;
    await SupabaseService.client.auth.updateUser(
      UserAttributes(data: metadata),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Напоминания будут приходить за $days дн.'), backgroundColor: _primaryColor),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
      return '${date.day} ${months[date.month - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'billing_reminder': return Icons.credit_card;
      case 'trial_ending': return Icons.warning_amber;
      case 'invitation': return Icons.people;
      case 'invitation_accepted': return Icons.check_circle;
      case 'invitation_declined': return Icons.cancel;
      case 'family_payment_reminder': return Icons.payments;
      case 'payment_confirmed': return Icons.check_circle_outline;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'billing_reminder': return _primaryColor;
      case 'trial_ending': return const Color(0xFFFF9F43);
      case 'invitation': return const Color(0xFF10B981);
      case 'invitation_accepted': return const Color(0xFF10B981);
      case 'invitation_declined': return const Color(0xFFE74C3C);
      case 'family_payment_reminder': return const Color(0xFFFF9F43);
      case 'payment_confirmed': return const Color(0xFF10B981);
      default: return _textGray;
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
        title: const Text('Уведомления', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          if (_notifications.isNotEmpty || _invitations.isNotEmpty || _reminders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: _textGray),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Настройки напоминаний', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Напоминать о списании за:', style: TextStyle(fontSize: 14, color: _textGray)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildReminderButton('1 день')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildReminderButton('2 дня')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildReminderButton('3 дня')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_reminders.isNotEmpty) ...[
                      const Text('Запланированные напоминания', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(height: 12),
                      ..._reminders.map((r) => _buildReminderCard(r)),
                      const SizedBox(height: 24),
                    ],

                    if (_invitations.isNotEmpty) ...[
                      const Text('Приглашения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(height: 12),
                      ..._invitations.map((inv) => _buildInvitationCard(inv)),
                      const SizedBox(height: 24),
                    ],

                    const Text('История уведомлений', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 12),
                    if (_notifications.isEmpty && _reminders.isEmpty && _invitations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Text('Нет уведомлений', style: TextStyle(color: _textGray))),
                      )
                    else if (_notifications.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Column(
                          children: [
                            for (int i = 0; i < _notifications.length; i++) ...[
                              _buildNotificationCard(_notifications[i]),
                              if (i < _notifications.length - 1) const Divider(color: Color(0xFFF0F0F5), height: 1),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildReminderButton(String period) {
    final isSelected = _reminderPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() => _reminderPeriod = period);
        _saveReminderPeriod();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? _primaryColor : const Color(0xFFE8E8ED), width: 1.5),
        ),
        child: Center(
          child: Text(period, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? _primaryColor : _textDark)),
        ),
      ),
    );
  }

  // ✅ Карточка напоминания с переходом на подписку
  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final remindAt = DateTime.parse(reminder['remind_at'] as String);
    final subName = (reminder['subscriptions'] as Map?)?['name'] as String? ?? 'Подписка';
    final daysLeft = remindAt.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => _openSubscriptionFromReminder(reminder), // ✅ Переход на подписку
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.alarm, color: _primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                  const SizedBox(height: 2),
                  Text(
                    'Напоминание через $daysLeft дн.',
                    style: const TextStyle(fontSize: 12, color: _textGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textGray, size: 20), // ✅ Стрелочка перехода
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(Invitation invitation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.people, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Приглашение в семью', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                    const SizedBox(height: 2),
                    Text(_formatDate(invitation.createdAt), style: const TextStyle(fontSize: 12, color: _textGray)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineInvitation(invitation),
                  style: OutlinedButton.styleFrom(foregroundColor: _textGray, side: const BorderSide(color: _textGray), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Отклонить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptInvitation(invitation),
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  child: const Text('Принять', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Карточка уведомления в истории — кликабельна для billing_reminder
  Widget _buildNotificationCard(AppNotification notification) {
    final isClickable = notification.type == 'billing_reminder' && notification.relatedSubscriptionId != null;
    
    return GestureDetector(
      onTap: isClickable ? () => _openSubscriptionFromNotification(notification) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _getColorForType(notification.type).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(_getIconForType(notification.type), color: _getColorForType(notification.type), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                  if (notification.body != null) ...[
                    const SizedBox(height: 2),
                    Text(notification.body!, style: const TextStyle(fontSize: 12, color: _textGray)),
                  ],
                  const SizedBox(height: 2),
                  Text(_formatDate(notification.createdAt), style: const TextStyle(fontSize: 11, color: _textGray)),
                ],
              ),
            ),
            // ✅ Стрелочка только для кликабельных уведомлений
            if (isClickable)
              const Icon(Icons.chevron_right, color: _textGray, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))]),
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
          if (isActive) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)), (r) => false);
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