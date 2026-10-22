import 'package:flutter/material.dart';
import 'tools_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'new_sub.dart';
import 'subscription_screen.dart';
import 'what_if_screen.dart';
import 'models.dart';
import 'supabase_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadData();
  }

    Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Создаём reminders для всех подписок, если их нет
      await SupabaseService.createRemindersForAllSubscriptions();
      
      // Проверяем и отправляем просроченные напоминания
      await _checkAndSendReminders();

      final ownedSubs = await SupabaseService.getSubscriptions();
      final memberSubs = await SupabaseService.getMemberSubscriptions();

      final allSubs = [...ownedSubs];
      for (var sub in memberSubs) {
        if (!allSubs.any((s) => s.id == sub.id)) {
          allSubs.add(sub);
        }
      }

      if (mounted) setState(() {
        _subscriptions = allSubs;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки данных: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Проверка и отправка напоминаний
  Future<void> _checkAndSendReminders() async {
    try {
      final reminders = await SupabaseService.getReminders();
      final now = DateTime.now();
      int sentCount = 0;

      for (var reminder in reminders) {
        final remindAt = DateTime.parse(reminder['remind_at'] as String);

        // Если время напоминания наступило и оно ещё не отправлено
        if (remindAt.isBefore(now) && reminder['is_sent'] == false) {
          final subName = (reminder['subscriptions'] as Map?)?['name'] as String? ?? 'подписке';

          // Создаём уведомление
          await SupabaseService.createNotification(
            userId: reminder['user_id'] as String,
            type: 'billing_reminder',
            title: 'Напоминание о списании',
            body: 'Скоро списание по подписке "$subName"',
            relatedSubscriptionId: reminder['subscription_id'] as String,
          );

          // Отмечаем как отправленное
          await SupabaseService.markReminderSent(reminder['id'] as String);
          sentCount++;
        }
      }

      if (sentCount > 0) {
        print('✅ Отправлено $sentCount напоминаний');
      }
    } catch (e) {
      print('❌ Ошибка проверки напоминаний: $e');
    }
  }

  List<Subscription> get _trialSubs => _subscriptions.where((s) => s.isTrial).toList();
  List<Subscription> get _activeSubs => _subscriptions.where((s) => !s.isTrial).toList();

  double get _totalMonthPrice {
    return _subscriptions.fold<double>(0, (sum, s) {
      if (s.isTrial) return sum;
      return sum + SupabaseService.calculateMonthlyPrice(s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildSubscriptionsPage(), const ToolsScreen(), const AnalyticsScreen(), const ProfileScreen()];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSubscriptionsPage() {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Доброе утро,', style: TextStyle(fontSize: 14, color: _textGray)),
                            const SizedBox(height: 2),
                            Text(SupabaseService.userName ?? 'Пользователь', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textDark)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSubScreen())).then((_) => _loadData()),
                          child: Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    if (_subscriptions.isEmpty) ...[
                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.credit_card_outlined, size: 64, color: _textGray.withValues(alpha:0.4)),
                            const SizedBox(height: 16),
                            const Text('Подписки отсутствуют', style: TextStyle(fontSize: 18, color: _textGray, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text('Нажмите +, чтобы добавить первую', style: TextStyle(fontSize: 14, color: _textGray.withValues(alpha:0.7))),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text('Всего в месяц', style: TextStyle(fontSize: 14, color: _textGray)),
                      const SizedBox(height: 4),
                      Text('${_totalMonthPrice.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('${(_totalMonthPrice * 12).toStringAsFixed(0)} ₽ в год', style: TextStyle(fontSize: 13, color: _textGray)),
                      ),
                      const SizedBox(height: 28),

                      if (_trialSubs.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Пробные периоды под защитой',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
                              child: Text('${_trialSubs.length} активных', style: const TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _trialSubs.map((s) => _buildTrialCard(s)).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_activeSubs.isNotEmpty) ...[
                        const Text('Активные подписки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                        const SizedBox(height: 12),
                        ..._activeSubs.map((sub) => _buildSwipeableCard(sub)),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTrialCard(Subscription sub) {
    final daysLeft = sub.trialEndDate?.difference(DateTime.now()).inDays ?? 0;
    final isUrgent = daysLeft <= 1;
    final timeText = daysLeft > 0 ? '$daysLeft дн' : 'Сегодня';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen(subscription: sub))).then((_) => _loadData()),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isUrgent ? Border.all(color: const Color(0xFFFF4444), width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sub.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(8)),
                    child: const Text('СРОЧНО', style: TextStyle(fontSize: 10, color: Color(0xFFFF4444), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time_filled, size: 14, color: isUrgent ? const Color(0xFFFF4444) : _primaryColor),
                const SizedBox(width: 4),
                Text(timeText, style: TextStyle(fontSize: 13, color: isUrgent ? const Color(0xFFFF4444) : _primaryColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableCard(Subscription sub) {
    return _SwipeableCard(
      subscription: sub,
      onWhatIf: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WhatIfScreen(subscription: sub))),
      onDelete: () async {
        final confirmed = await _showDismissDialog(sub.name);
        if (confirmed == true) {
          await SupabaseService.deleteSubscription(sub.id);
          await _loadData();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${sub.name} удалена'), backgroundColor: const Color(0xFFE74C3C)));
        }
      },
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen(subscription: sub))).then((_) => _loadData()),
    );
  }

  Future<bool?> _showDismissDialog(String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить подписку?'),
        content: Text('Вы уверены, что хотите удалить "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.credit_card_outlined, 'Подписки', 0),
          _buildNavItem(Icons.build_outlined, 'Инструменты', 1),
          _buildNavItem(Icons.bar_chart_outlined, 'Аналитика', 2),
          _buildNavItem(Icons.person_outline, 'Профиль', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
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

// ============================================================
// Свайпаемая карточка
// ============================================================
class _SwipeableCard extends StatefulWidget {
  final Subscription subscription;
  final VoidCallback onWhatIf;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SwipeableCard({required this.subscription, required this.onWhatIf, required this.onDelete, required this.onTap});

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard> {
  bool _showButtons = false;
  double _offsetX = 0;

  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _primaryColor = Color(0xFF6C47FF);

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offsetX += details.primaryDelta!;
      _offsetX = _offsetX.clamp(-300.0, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      if (!_showButtons) {
        if (_offsetX < -100) {
          _showButtons = true;
          _offsetX = -300;
        } else {
          _offsetX = 0;
        }
      } else {
        if (_offsetX > -200) {
          _showButtons = false;
          _offsetX = 0;
        } else {
          _offsetX = -300;
        }
      }
    });
  }

  void _resetToCard() {
    setState(() {
      _showButtons = false;
      _offsetX = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final isFamily = sub.hasFamily;
    final memberCount = sub.memberCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          if (_showButtons)
            Row(
              children: [
                const Spacer(),
                Expanded(
                  child: GestureDetector(
                    onTap: () { _resetToCard(); widget.onWhatIf(); },
                    onHorizontalDragUpdate: _onHorizontalDragUpdate,
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: Container(
                      height: 88,
                      decoration: const BoxDecoration(color: Color(0xFFFF9F43), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lightbulb_outline, color: Colors.white, size: 32), SizedBox(height: 8), Text('Что если', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))]),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () { _resetToCard(); widget.onDelete(); },
                    onHorizontalDragUpdate: _onHorizontalDragUpdate,
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: Container(
                      height: 88,
                      decoration: const BoxDecoration(color: Color(0xFFE74C3C), borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16))),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_outline, color: Colors.white, size: 32), SizedBox(height: 8), Text('Удалить', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))]),
                    ),
                  ),
                ),
              ],
            ),
          GestureDetector(
            onTap: widget.onTap,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: Transform.translate(
              offset: Offset(_offsetX, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: _getColorForCategory(sub.category), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(sub.name.isNotEmpty ? sub.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(sub.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('${sub.category} · ${sub.periodLabel}', style: TextStyle(fontSize: 12, color: _textGray)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6, runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: sub.billingDate <= 3 ? const Color(0xFFFFE5E5) : const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_filled, size: 12, color: sub.billingDate <= 3 ? const Color(0xFFFF4444) : _textGray),
                                    const SizedBox(width: 3),
                                    Text('${sub.billingDate} число', style: TextStyle(fontSize: 11, color: sub.billingDate <= 3 ? const Color(0xFFFF4444) : _textGray)),
                                  ],
                                ),
                              ),
                              if (isFamily && memberCount != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people, size: 16, color: _primaryColor),
                                      const SizedBox(width: 4),
                                      Text('$memberCount', style: const TextStyle(fontSize: 14, color: _primaryColor, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${sub.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                            const SizedBox(width: 3),
                            const Text('₽', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(sub.periodLabel, style: TextStyle(fontSize: 11, color: _textGray)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
}