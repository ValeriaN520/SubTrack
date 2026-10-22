import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static SupabaseClient get client => _client;

  static String? get userName => _client.auth.currentUser?.userMetadata?['name'] as String? ?? 'Пользователь';
  static String? get userEmail => _client.auth.currentUser?.email;
  static int get salaryDate => _client.auth.currentUser?.userMetadata?['reminder_days'] as int? ?? 2;
  static DateTime? get userCreatedAt {
    final createdAt = _client.auth.currentUser?.createdAt;
    return createdAt != null ? DateTime.parse(createdAt) : null;
  }

  static Future<void> updateProfile({String? name, int? reminderDays}) async {
    final metadata = _client.auth.currentUser?.userMetadata ?? {};
    if (name != null) metadata['name'] = name;
    if (reminderDays != null) metadata['reminder_days'] = reminderDays;
    await _client.auth.updateUser(UserAttributes(data: metadata));
  }

  // ============================================================
  // ПОДПИСКИ
  // ============================================================

  static Future<List<Subscription>> getSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client.from('subscriptions').select().eq('owner_id', userId).order('created_at', ascending: false);
    List<Subscription> subs = [];
    for (var item in response) {
      int? memberCount;
      if (item['family_group_id'] != null) {
        final group = await _client.from('family_groups').select('members').eq('id', item['family_group_id']).maybeSingle();
        memberCount = group?['members'] as int?;
      }
      subs.add(Subscription.fromMap(item, memberCount: memberCount));
    }
    return subs;
  }

  static Future<Subscription?> getSubscriptionById(String id) async {
    final response = await _client.from('subscriptions').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    int? memberCount;
    if (response['family_group_id'] != null) {
      final group = await _client.from('family_groups').select('members').eq('id', response['family_group_id']).maybeSingle();
      memberCount = group?['members'] as int?;
    }
    return Subscription.fromMap(response, memberCount: memberCount);
  }

  static Future<Subscription> createSubscription(Subscription sub) async {
    final userId = _client.auth.currentUser!.id;
    final data = sub.toMap()..['owner_id'] = userId;
    final response = await _client.from('subscriptions').insert(data).select().single();
    int? memberCount;
    if (response['family_group_id'] != null) {
      final group = await _client.from('family_groups').select('members').eq('id', response['family_group_id']).maybeSingle();
      memberCount = group?['members'] as int?;
    }
    return Subscription.fromMap(response, memberCount: memberCount);
  }

  static Future<void> updateSubscription(Subscription sub) async {
    await _client.from('subscriptions').update(sub.toMap()).eq('id', sub.id);
  }

  static Future<void> deleteSubscription(String id) async {
    await _client.from('subscriptions').delete().eq('id', id);
  }

  // ============================================================
  // СЕМЕЙНЫЕ ГРУППЫ
  // ============================================================

  static Future<FamilyGroup> createFamilyGroup(String ownerId, int members) async {
    final response = await _client.from('family_groups').insert({'owner_id': ownerId, 'members': members}).select().single();
    return FamilyGroup.fromMap(response);
  }

  static Future<FamilyGroup?> getFamilyGroup(String groupId) async {
    final response = await _client.from('family_groups').select().eq('id', groupId).maybeSingle();
    return response != null ? FamilyGroup.fromMap(response) : null;
  }

  static Future<void> updateFamilyGroupMembers(String groupId, int members) async {
    await _client.from('family_groups').update({'members': members}).eq('id', groupId);
  }

  static Future<List<FamilyMember>> getFamilyMembers(String groupId) async {
    final response = await _client
        .from('family_members')
        .select()
        .eq('group_id', groupId)
        .eq('status', 'active');

    final membersList = (response as List).map((e) => FamilyMember.fromMap(e)).toList();
    
    if (membersList.isEmpty) return membersList;

    // ✅ Получаем все user_id участников
    final userIds = membersList.map((m) => m.userId).toSet().toList();

    // ✅ Один запрос к RPC-функции — получаем имена и email всех участников
    try {
      final usersInfo = await _client.rpc('get_users_info', params: {'user_ids': userIds});
      
      if (usersInfo != null) {
        for (var userInfo in usersInfo as List) {
          final userId = userInfo['user_id'] as String;
          final userName = userInfo['user_name'] as String?;
          final userEmail = userInfo['user_email'] as String?;
          
          // ✅ Находим участника и заполняем его данные
          final member = membersList.firstWhere(
            (m) => m.userId == userId,
            orElse: () => FamilyMember(id: '', groupId: '', userId: '', role: 'member', status: 'active'),
          );
          if (member.id.isNotEmpty) {
            member.userName = userName;
            member.userEmail = userEmail;
          }
        }
      }
    } catch (e) {
      print('❌ Ошибка получения информации о пользователях: $e');
    }

    return membersList;
  }

   // ✅ Добавление участника в группу (используется при создании семейной подписки)
  static Future<void> addFamilyMember(String groupId, String userId, String role) async {
    await _client.from('family_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'status': 'active',
    });
  }

  static Future<void> removeFamilyMember(String memberId) async {
    await _client.from('family_members').delete().eq('id', memberId);
  }

  // ============================================================
  // АНАЛИТИКА
  // ============================================================

  static double getEffectivePrice(Subscription sub) {
    if (sub.hasFamily && sub.memberCount != null && sub.memberCount! > 0) {
      return sub.price / sub.memberCount!;
    }
    return sub.price;
  }

  static double calculateMonthlyPrice(Subscription sub) {
    final effectivePrice = getEffectivePrice(sub);
    switch (sub.billingPeriod) {
      case 'week': return effectivePrice * 4.33;
      case 'month': return effectivePrice;
      case '3months': return effectivePrice / 3;
      case '6months': return effectivePrice / 6;
      case 'year': return effectivePrice / 12;
      default: return effectivePrice;
    }
  }

  static double calculateActualSpent(Subscription sub, DateTime startDate, DateTime endDate) {
    if (sub.createdAt.isAfter(endDate)) return 0;
    
    final billingDate = sub.billingDate;
    double total = 0;
    final monthlyPrice = calculateMonthlyPrice(sub);
    
    DateTime currentDate = sub.createdAt.isAfter(startDate) ? sub.createdAt : startDate;
    
    if (currentDate.day < billingDate) {
      currentDate = DateTime(currentDate.year, currentDate.month, billingDate);
    } else if (currentDate.day > billingDate) {
      currentDate = DateTime(currentDate.year, currentDate.month + 1, billingDate);
    }
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      total += monthlyPrice;
      currentDate = _addPeriod(currentDate, sub.billingPeriod);
    }
    
    return total;
  }

  static DateTime _addPeriod(DateTime date, String period) {
    switch (period) {
      case 'week': return date.add(const Duration(days: 7));
      case 'month': return DateTime(date.year, date.month + 1, date.day);
      case '3months': return DateTime(date.year, date.month + 3, date.day);
      case '6months': return DateTime(date.year, date.month + 6, date.day);
      case 'year': return DateTime(date.year + 1, date.month, date.day);
      default: return DateTime(date.year, date.month + 1, date.day);
    }
  }

static Future<Map<String, dynamic>> getAnalyticsData({required bool isYear}) async {
  // ✅ Получаем и свои подписки, и подписки, где пользователь участник
  final ownedSubs = await getSubscriptions();
  final memberSubs = await getMemberSubscriptions();
  
  // Объединяем без дубликатов
  final allSubIds = ownedSubs.map((s) => s.id).toSet();
  final subs = [...ownedSubs];
  for (var sub in memberSubs) {
    if (!allSubIds.contains(sub.id)) {
      subs.add(sub);
    }
  }
  
  final now = DateTime.now();
  final userCreated = userCreatedAt ?? now;
    
    DateTime endDate;
    String periodLabel;
    
    if (isYear) {
      endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      periodLabel = 'год';
    } else {
      if (now.month <= 6) {
        endDate = DateTime(now.year, 6, 30, 23, 59, 59);
      } else {
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      }
      periodLabel = 'полгода';
    }
    
    if (userCreated.isAfter(endDate)) {
      return {
        'totalSpent': 0.0, 'periodLabel': periodLabel, 'categoryTotals': <String, double>{},
        'serviceTotals': <String, double>{}, 'mostExpensive': null, 'cheapest': null,
        'avgPerDay': 0.0, 'yearlyForecast': 0.0, 'totalSubs': subs.length,
      };
    }

    double totalSpent = 0;
    Map<String, double> categoryTotals = {};
    Map<String, double> serviceTotals = {};
    Subscription? mostExpensive;
    Subscription? cheapest;
    double maxMonthly = 0;
    double minMonthly = double.infinity;

    for (var sub in subs) {
      final spent = calculateActualSpent(sub, userCreated, endDate);
      totalSpent += spent;

      if (spent > 0) {
        categoryTotals[sub.category] = (categoryTotals[sub.category] ?? 0) + spent;
        serviceTotals[sub.name] = (serviceTotals[sub.name] ?? 0) + spent;

        final monthly = calculateMonthlyPrice(sub);
        if (monthly > maxMonthly) { maxMonthly = monthly; mostExpensive = sub; }
        if (monthly < minMonthly) { minMonthly = monthly; cheapest = sub; }
      }
    }

    final daysInPeriod = endDate.difference(userCreated).inDays;
    final avgPerDay = daysInPeriod > 0 ? totalSpent / daysInPeriod : 0;
    final yearlyForecast = totalSpent * (365 / daysInPeriod.clamp(1, 365));

    return {
      'totalSpent': totalSpent, 'periodLabel': periodLabel, 'categoryTotals': categoryTotals,
      'serviceTotals': serviceTotals, 'mostExpensive': mostExpensive, 'cheapest': cheapest,
      'avgPerDay': avgPerDay, 'yearlyForecast': yearlyForecast, 'totalSubs': subs.length,
    };
  }

  static String calculateSeniority() {
    final createdAt = userCreatedAt;
    if (createdAt == null) return '0 месяцев';
    final now = DateTime.now();
    final days = now.difference(createdAt).inDays;
    if (days < 30) return '$days ${days == 1 ? 'день' : days < 5 ? 'дня' : 'дней'}';
    final months = days ~/ 30;
    if (months == 1) return '1 месяц';
    if (months >= 2 && months <= 4) return '$months месяца';
    return '$months месяцев';
  }

  // ============================================================
  // НАПОМИНАНИЯ (reminders)
  // ============================================================

  static Future<void> createBillingReminder(String subscriptionId, int daysBefore) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final sub = await _client.from('subscriptions').select().eq('id', subscriptionId).maybeSingle();
    if (sub == null) return;

    final billingDay = sub['billing_date'] as int;
    final now = DateTime.now();
    var nextBilling = DateTime(now.year, now.month, billingDay);
    
    if (nextBilling.isBefore(now)) {
      nextBilling = DateTime(now.year, now.month + 1, billingDay);
    }

    final remindAt = nextBilling.subtract(Duration(days: daysBefore));

    await _client.from('reminders').insert({
      'subscription_id': subscriptionId,
      'user_id': userId,
      'remind_at': remindAt.toIso8601String(),
      'is_sent': false,
    });

    await createNotification(
      userId: userId,
      type: 'billing_reminder',
      title: 'Напоминание о списании',
      body: 'Через $daysBefore дн. списание по подписке ${sub['name']}',
      relatedSubscriptionId: subscriptionId,
    );
  }

  static Future<List<Map<String, dynamic>>> getReminders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('reminders')
        .select('*, subscriptions(name, billing_date)')
        .eq('user_id', userId)
        .eq('is_sent', false)
        .order('remind_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> markReminderSent(String reminderId) async {
    await _client.from('reminders').update({'is_sent': true}).eq('id', reminderId);
  }

  static Future<void> clearReminders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('reminders').delete().eq('user_id', userId);
  }

  // ✅ Создать reminders для всех существующих подписок
  static Future<void> createRemindersForAllSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final subs = await getSubscriptions();
    final reminderDays = _client.auth.currentUser?.userMetadata?['reminder_days'] as int? ?? 2;

    for (var sub in subs) {
      final existingReminders = await _client
          .from('reminders')
          .select()
          .eq('subscription_id', sub.id)
          .eq('user_id', userId);

      if ((existingReminders as List).isEmpty) {
        final billingDay = sub.billingDate;
        final now = DateTime.now();
        var nextBilling = DateTime(now.year, now.month, billingDay);
        
        if (nextBilling.isBefore(now)) {
          nextBilling = DateTime(now.year, now.month + 1, billingDay);
        }

        final remindAt = nextBilling.subtract(Duration(days: reminderDays));

        await _client.from('reminders').insert({
          'subscription_id': sub.id,
          'user_id': userId,
          'remind_at': remindAt.toIso8601String(),
          'is_sent': false,
        });

        print('✅ Создан reminder для ${sub.name} на ${remindAt.toIso8601String()}');
      }
    }
  }

  // ✅ Обновить reminder при изменении даты списания
  static Future<void> updateReminder(String subscriptionId, int newBillingDate) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final reminderDays = _client.auth.currentUser?.userMetadata?['reminder_days'] as int? ?? 2;

    // Удаляем старые reminders
    await _client
        .from('reminders')
        .delete()
        .eq('subscription_id', subscriptionId)
        .eq('user_id', userId);

    // Создаём новый reminder
    final now = DateTime.now();
    var nextBilling = DateTime(now.year, now.month, newBillingDate);
    
    if (nextBilling.isBefore(now)) {
      nextBilling = DateTime(now.year, now.month + 1, newBillingDate);
    }

    final remindAt = nextBilling.subtract(Duration(days: reminderDays));

    await _client.from('reminders').insert({
      'subscription_id': subscriptionId,
      'user_id': userId,
      'remind_at': remindAt.toIso8601String(),
      'is_sent': false,
    });

    print('✅ Reminder обновлён для подписки $subscriptionId на $remindAt');
  }

  // ============================================================
  // УВЕДОМЛЕНИЯ (notifications)
  // ============================================================

  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    String? body,
    String? relatedSubscriptionId,
    String? relatedInvitationId,
    String? fromUserId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'related_subscription_id': relatedSubscriptionId,
      'related_invitation_id': relatedInvitationId,
      'from_user_id': fromUserId,
      'is_read': false,
    });
  }

  static Future<List<AppNotification>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => AppNotification.fromMap(e)).toList();
  }

  static Future<void> clearNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('notifications').delete().eq('user_id', userId);
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  // ============================================================
  // ПРИГЛАШЕНИЯ (invitations)
  // ============================================================

  static Future<bool> userExistsByEmail(String email) async {
    try {
      final result = await _client.rpc('get_user_id_by_email', params: {'email_to_check': email});
      return result != null;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserIdByEmail(String email) async {
    try {
      final result = await _client.rpc('get_user_id_by_email', params: {'email_to_check': email});
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<Invitation?> createInvitation(String subscriptionId, String groupId, String toEmail) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final toUserId = await getUserIdByEmail(toEmail);
    if (toUserId == null) return null;

    final response = await _client.from('invitations').insert({
      'subscription_id': subscriptionId,
      'group_id': groupId,
      'from_user_id': userId,
      'to_email': toEmail,
      'to_user_id': toUserId,
      'status': 'pending',
    }).select().single();

    await createNotification(
      userId: toUserId,
      type: 'invitation',
      title: 'Приглашение в семью',
      body: 'Вас пригласили в семейную подписку',
      relatedInvitationId: response['id'] as String,
      relatedSubscriptionId: subscriptionId,
      fromUserId: userId,
    );

    return Invitation.fromMap(response);
  }

  static Future<List<Invitation>> getPendingInvitations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('invitations')
        .select()
        .eq('to_user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Invitation.fromMap(e)).toList();
  }

  static Future<void> acceptInvitation(String invitationId) async {
    final invitation = await _client.from('invitations').select().eq('id', invitationId).single();
    final inv = Invitation.fromMap(invitation);

    await _client.from('invitations').update({
      'status': 'accepted',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', invitationId);

    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      // ✅ Добавляем только user_id — имя и email подтянутся через RPC при загрузке
      await _client.from('family_members').insert({
        'group_id': inv.groupId,
        'user_id': userId,
        'role': 'member',
        'status': 'active',
      });

      // Увеличиваем количество участников
      final group = await getFamilyGroup(inv.groupId);
      if (group != null) {
        await updateFamilyGroupMembers(inv.groupId, group.members + 1);
      }

      // Уведомление владельцу
      await createNotification(
        userId: inv.fromUserId,
        type: 'invitation_accepted',
        title: 'Приглашение принято',
        body: 'Пользователь присоединился к вашей семье',
        relatedSubscriptionId: inv.subscriptionId,
        fromUserId: userId,
      );
    }
  }

  static Future<void> declineInvitation(String invitationId) async {
    final invitation = await _client.from('invitations').select().eq('id', invitationId).single();
    final inv = Invitation.fromMap(invitation);

    await _client.from('invitations').update({
      'status': 'declined',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', invitationId);

    await createNotification(
      userId: inv.fromUserId,
      type: 'invitation_declined',
      title: 'Приглашение отклонено',
      body: 'Пользователь отклонил приглашение в семью',
      relatedSubscriptionId: inv.subscriptionId,
      fromUserId: _client.auth.currentUser?.id,
    );
  }

  // ============================================================
  // "Я СКИНУЛ"
  // ============================================================

  static Future<void> markPaymentSent(String subscriptionId, String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final group = await getFamilyGroup(groupId);
    if (group == null) return;

    await createNotification(
      userId: group.ownerId,
      type: 'payment_confirmed',
      title: 'Участник перевёл долю',
      body: 'Участник подтвердил перевод своей доли за подписку',
      relatedSubscriptionId: subscriptionId,
      fromUserId: userId,
    );

    final reminders = await _client
        .from('reminders')
        .select()
        .eq('subscription_id', subscriptionId)
        .eq('user_id', userId)
        .eq('is_sent', false);

    for (var r in reminders) {
      await _client.from('reminders').update({'is_sent': true}).eq('id', r['id']);
    }
  }

  // ============================================================
  // ПОДПИСКИ УЧАСТНИКА
  // ============================================================

  static Future<List<Subscription>> getMemberSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('family_members')
        .select('group_id')
        .eq('user_id', userId)
        .eq('status', 'active');

    final groupIds = (response as List).map((e) => e['group_id'] as String).toList();
    if (groupIds.isEmpty) return [];

    final subsResponse = await _client
        .from('subscriptions')
        .select()
        .inFilter('family_group_id', groupIds);

    List<Subscription> subs = [];
    for (var item in subsResponse) {
      int? memberCount;
      if (item['family_group_id'] != null) {
        final group = await _client.from('family_groups').select('members').eq('id', item['family_group_id']).maybeSingle();
        memberCount = group?['members'] as int?;
      }
      subs.add(Subscription.fromMap(item, memberCount: memberCount));
    }
    return subs;
  }

  // ============================================================
  // ВЫХОД ИЗ СЕМЕЙНОЙ ГРУППЫ
  // ============================================================

  // ✅ Выход участника из семейной подписки
   static Future<void> leaveFamilyGroup(String subscriptionId, String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // ✅ Сначала получаем группу, чтобы знать ownerId для уведомления
    final group = await getFamilyGroup(groupId);
    if (group == null) return;

    final ownerId = group.ownerId;

    final memberResponse = await _client
        .from('family_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .eq('role', 'member')
        .maybeSingle();

    if (memberResponse != null) {
      await _client.from('family_members').delete().eq('id', memberResponse['id']);

      if (group.members > 1) {
        await updateFamilyGroupMembers(groupId, group.members - 1);
      }

      final subscription = await getSubscriptionById(subscriptionId);
      if (subscription != null) {
        await createNotification(
          userId: ownerId,  // ✅ Теперь ownerId точно не null
          type: 'system',
          title: 'Участник вышел из семьи',
          body: 'Участник покинул семейную подписку "${subscription.name}"',
          relatedSubscriptionId: subscriptionId,
          fromUserId: userId,
        );
      }
    }
  }

  // ✅ Проверка, является ли текущий пользователь владельцем группы
  static Future<bool> isGroupOwner(String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final group = await getFamilyGroup(groupId);
    return group?.ownerId == userId;
  }
}