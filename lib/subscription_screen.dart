import 'package:flutter/material.dart';
import 'change_sub_screen.dart';
import 'home_screen.dart';
import 'models.dart';
import 'supabase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final Subscription subscription;
  const SubscriptionScreen({super.key, required this.subscription});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _emailController = TextEditingController();
  late Subscription _sub;
  List<FamilyMember> _members = [];
  FamilyGroup? _familyGroup;
  bool _isLoadingMembers = true;
  String? _emailError;
  bool _isOwner = false; // ✅ Флаг владельца

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _dangerColor = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _sub = widget.subscription;
    if (_sub.hasFamily) _loadFamilyData();
  }

  Future<void> _reloadSubscription() async {
    final updated = await SupabaseService.getSubscriptionById(_sub.id);
    if (updated != null && mounted) {
      setState(() => _sub = updated);
    }
  }

  Future<void> _loadFamilyData() async {
    try {
      final group = await SupabaseService.getFamilyGroup(_sub.familyGroupId!);
      final members = await SupabaseService.getFamilyMembers(_sub.familyGroupId!);
      
      // ✅ Проверяем, является ли текущий пользователь владельцем
      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      final isOwner = group?.ownerId == currentUserId;

      if (mounted) setState(() {
        _familyGroup = group;
        _members = members;
        _isOwner = isOwner;
        _isLoadingMembers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  bool get _isFamily => _sub.hasFamily;
  bool get _isTrial => _sub.isTrial;
  int get _membersCount => _familyGroup?.members ?? 1;
  double get _sharePerMember => _membersCount <= 0 ? _sub.price : _sub.price / _membersCount;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    setState(() => _emailError = null);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Вы не ввели email');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Некорректный email');
      return;
    }
    if (_members.length >= _membersCount) {
      setState(() => _emailError = 'Достигнут лимит участников. Отредактируйте подписку.');
      return;
    }

    final invitation = await SupabaseService.createInvitation(_sub.id, _sub.familyGroupId!, email);
    if (invitation == null) {
      setState(() => _emailError = 'Пользователь с таким email не существует');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Приглашение отправлено!'), backgroundColor: _primaryColor),
      );
      _emailController.clear();
    }
  }

    // ✅ Выход из семейной подписки (для участника)
  Future<void> _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Выйти из семейной подписки?'),
        content: const Text('Вы перестанете быть участником этой подписки.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.leaveFamilyGroup(_sub.id, _sub.familyGroupId!);
        if (mounted) {
          // ✅ Показываем уведомление
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы вышли из семейной подписки'), backgroundColor: _primaryColor),
          );
          
          // ✅ Возвращаемся на главный экран
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)),
            (route) => false,
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
  }

  String _formatDate(DateTime date) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _textDark), onPressed: () => Navigator.pop(context)),
        title: Text(_sub.name, style: const TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          if (_isFamily)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people_outline, size: 14, color: _primaryColor),
                const SizedBox(width: 4),
                Text('$_membersCount чел', style: const TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isTrial)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9F43), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9F43), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Это пробный период. Окончание: ${_sub.trialEndDate != null ? _formatDate(_sub.trialEndDate!) : 'скоро'}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isFamily) ...[
                    _buildFamilyCard(),
                    const SizedBox(height: 24),
                    _buildInfoField('${_sub.billingDate} число', Icons.calendar_today_outlined, label: 'Дата списания'),
                    const SizedBox(height: 24),
                    
                    // ✅ Блок "Вы владелец" только для владельца
                    if (_isOwner) ...[
                      const Text('Вы владелец', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 12),
                      _buildInviteBlock(),
                      const SizedBox(height: 24),
                    ],
                    
                    const Text('Участники', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)),
                    const SizedBox(height: 12),
                    _buildMembersList(),
                    const SizedBox(height: 40),
                  ] else ...[
                    _buildRegularCard(),
                    const SizedBox(height: 24),
                    _buildFieldRow('Категория', _sub.category),
                    const SizedBox(height: 16),
                    _buildFieldRow('Стоимость', '${_sub.price.toStringAsFixed(0)} ₽'),
                    const SizedBox(height: 16),
                    _buildFieldRow('Период списания', _sub.periodWords),
                    const SizedBox(height: 16),
                    _buildFieldRow('Дата списания', '${_sub.billingDate} число', icon: Icons.calendar_today_outlined),
                    const SizedBox(height: 40),
                  ],

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(16)),
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
                              Text(_isFamily
                                  ? 'Показываем, кто присоединился к вашей семье'
                                  : 'Списание происходит автоматически в указанную дату. Вы можете отменить подписку в любой момент.',
                                  style: const TextStyle(fontSize: 13, color: _textGray)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ✅ Кнопка "Редактировать" только для владельца
                if (_isOwner || !_isFamily)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeSubScreen(subscription: _sub))).then((_) async {
                        await _reloadSubscription();
                        if (_isFamily) await _loadFamilyData();
                      }),
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text('Редактировать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                const SizedBox(height: 12),
                
                // ✅ Кнопка "Выйти из семьи" для участника
                if (_isFamily && !_isOwner)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _leaveFamily,
                      style: OutlinedButton.styleFrom(foregroundColor: _dangerColor, side: const BorderSide(color: _dangerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Выйти из семейной подписки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                
                // ✅ Кнопка "Удалить" только для владельца или обычной подписки
                if (_isOwner || !_isFamily)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _showDeleteDialog(),
                      style: OutlinedButton.styleFrom(foregroundColor: _dangerColor, side: const BorderSide(color: _dangerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(_isFamily ? 'Удалить семейную подписку' : 'Удалить подписку', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFamilyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: _getColorForCategory(_sub.category), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(_sub.name.isNotEmpty ? _sub.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_sub.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)), const SizedBox(height: 2), Text(_sub.category, style: TextStyle(fontSize: 13, color: _textGray))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text('${_sub.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)), const SizedBox(width: 3), const Text('₽', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark))]),
            const SizedBox(height: 2),
            Text(_sub.periodLabel, style: TextStyle(fontSize: 11, color: _textGray)),
          ]),
        ],
      ),
    );
  }

  Widget _buildRegularCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: _getColorForCategory(_sub.category), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(_sub.name.isNotEmpty ? _sub.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)))),
          const SizedBox(width: 14),
          Expanded(child: Text(_sub.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark))),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _textGray)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          alignment: Alignment.centerLeft,
          child: Row(children: [Expanded(child: Text(value, style: const TextStyle(fontSize: 15, color: _textDark))), if (icon != null) Icon(icon, color: _textGray, size: 18)]),
        ),
      ],
    );
  }

  Widget _buildInfoField(String text, IconData icon, {String? label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: const TextStyle(fontSize: 14, color: _textGray)),
          const SizedBox(height: 8),
        ],
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Row(children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: _textDark))), Icon(icon, color: _textGray, size: 18)]),
        ),
      ],
    );
  }

  Widget _buildInviteBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: _emailError != null ? Border.all(color: _dangerColor, width: 1.5) : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: _textGray),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'email', hintStyle: TextStyle(fontSize: 14, color: _textGray), border: InputBorder.none),
                        onChanged: (_) => setState(() => _emailError = null),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _handleInvite,
                child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('Пригласить', style: TextStyle(fontSize: 14, color: _primaryColor, fontWeight: FontWeight.w600)))),
              ),
            ],
          ),
          if (_emailError != null) ...[
            const SizedBox(height: 8),
            Text(_emailError!, style: const TextStyle(color: _dangerColor, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_isLoadingMembers) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));

    final currentUserId = SupabaseService.client.auth.currentUser?.id;

    // ✅ Ищем владельца в списке
    FamilyMember? dbOwner;
    for (var m in _members) {
      if (m.role == 'owner') {
        dbOwner = m;
        break;
      }
    }

    // ✅ Fallback на данные текущего пользователя если RPC не вернул
    final owner = FamilyMember(
      id: dbOwner?.id ?? 'owner',
      groupId: _sub.familyGroupId ?? '',
      userId: dbOwner?.userId ?? currentUserId ?? '',
      role: 'owner',
      status: 'active',
      userName: dbOwner?.userName ?? SupabaseService.userName,
      userEmail: dbOwner?.userEmail ?? SupabaseService.userEmail,
    );

    final otherMembers = _members.where((m) => m.role != 'owner').toList();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(10)), child: const Center(child: Icon(Icons.star, color: _primaryColor, size: 20))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(owner.userName ?? 'Владелец', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                  const SizedBox(height: 2),
                  Text(owner.userEmail ?? '', style: const TextStyle(fontSize: 12, color: _textGray)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${_sharePerMember.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(width: 2), const Text('₽', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                  ]),
                  const SizedBox(height: 2), const Text('в месяц', style: TextStyle(fontSize: 11, color: _textGray)),
                ]),
              ],
            ),
          ),
          if (otherMembers.isNotEmpty) const Divider(color: Color(0xFFF0F0F5), height: 1),

          for (int i = 0; i < otherMembers.length; i++) ...[
            // ✅ Свайп для удаления работает только у владельца
            Dismissible(
              key: Key(otherMembers[i].id),
              direction: _isOwner ? DismissDirection.endToStart : DismissDirection.none,
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: const BoxDecoration(color: Color(0xFFE74C3C), borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16))), child: const Icon(Icons.delete_outline, color: Colors.white, size: 24)),
              confirmDismiss: _isOwner ? (_) => _showDeleteMemberDialog(otherMembers[i]) : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: i == otherMembers.length - 1 ? 16 : 12),
                child: Row(
                  children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: _getColorForIndex(i), borderRadius: BorderRadius.circular(10)), child: Center(child: Text((otherMembers[i].userName ?? otherMembers[i].userEmail ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(otherMembers[i].userName ?? 'Пользователь', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 2),
                      Text(otherMembers[i].userEmail ?? '', style: const TextStyle(fontSize: 12, color: _textGray)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text('${_sharePerMember.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                        const SizedBox(width: 2), const Text('₽', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                      ]),
                      const SizedBox(height: 2), const Text('в месяц', style: TextStyle(fontSize: 11, color: _textGray)),
                    ]),
                  ],
                ),
              ),
            ),
            if (i < otherMembers.length - 1) const Divider(color: Color(0xFFF0F0F5), height: 1),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteMemberDialog(FamilyMember member) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить участника?'),
        content: Text('Вы уверены, что хотите удалить "${member.userName ?? 'участника'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.removeFamilyMember(member.id);
              await SupabaseService.updateFamilyGroupMembers(_sub.familyGroupId!, _membersCount - 1);
              if (mounted) {
                Navigator.pop(context, true);
                await _loadFamilyData();
                await _reloadSubscription();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить подписку?'),
        content: const Text('Это действие нельзя отменить. Все данные подписки будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.deleteSubscription(_sub.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Удалить'),
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

  Color _getColorForIndex(int i) {
    const colors = [Color(0xFFFFE5B4), Color(0xFFE8E8ED), Color(0xFFE0E7FF), Color(0xFFD1FAE5), Color(0xFFFFF3E0)];
    return colors[i % colors.length];
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.credit_card_outlined, 'Подписки', 0, isActive: true),
          _buildNavItem(Icons.build_outlined, 'Инструменты', 1),
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