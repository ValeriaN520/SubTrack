class Subscription {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final double price;
  final String billingPeriod;
  final int billingDate;
  final bool isTrial;
  final DateTime? trialEndDate;
  final double? trialPriceAfter;
  final String? familyGroupId;
  final DateTime createdAt;
  final int? memberCount;

  Subscription({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.price,
    required this.billingPeriod,
    required this.billingDate,
    this.isTrial = false,
    this.trialEndDate,
    this.trialPriceAfter,
    this.familyGroupId,
    required this.createdAt,
    this.memberCount,
  });

  factory Subscription.fromMap(Map<String, dynamic> map, {int? memberCount}) {
    return Subscription(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      billingPeriod: map['billing_period'] as String,
      billingDate: map['billing_date'] as int,
      isTrial: map['is_trial'] as bool? ?? false,
      trialEndDate: map['trial_end_date'] != null ? DateTime.parse(map['trial_end_date'] as String) : null,
      trialPriceAfter: map['trial_price_after'] != null ? (map['trial_price_after'] as num).toDouble() : null,
      familyGroupId: map['family_group_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      memberCount: memberCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'billing_period': billingPeriod,
      'billing_date': billingDate,
      'is_trial': isTrial,
      'trial_end_date': trialEndDate?.toIso8601String(),
      'trial_price_after': trialPriceAfter,
      'family_group_id': familyGroupId,
    };
  }

  bool get hasFamily => familyGroupId != null;

  String get periodLabel {
    switch (billingPeriod) {
      case 'week': return 'в неделю';
      case 'month': return 'в месяц';
      case '3months': return 'каждые 3 мес';
      case '6months': return 'каждые 6 мес';
      case 'year': return 'в год';
      default: return billingPeriod;
    }
  }

  String get periodWords {
    switch (billingPeriod) {
      case 'week': return 'Каждую неделю';
      case 'month': return 'Каждый месяц';
      case '3months': return 'Каждые 3 месяца';
      case '6months': return 'Каждые 6 месяцев';
      case 'year': return 'Каждый год';
      default: return billingPeriod;
    }
  }
}

class FamilyGroup {
  final String id;
  final String ownerId;
  final int members;
  FamilyGroup({required this.id, required this.ownerId, required this.members});
  factory FamilyGroup.fromMap(Map<String, dynamic> map) {
    return FamilyGroup(id: map['id'] as String, ownerId: map['owner_id'] as String, members: map['members'] as int? ?? 1);
  }
}

class FamilyMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final String status;
  String? userName;
  String? userEmail;
  FamilyMember({required this.id, required this.groupId, required this.userId, required this.role, required this.status, this.userName, this.userEmail});
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      status: map['status'] as String? ?? 'active',
      userName: map['user_name'] as String?,
      userEmail: map['user_email'] as String?, 
    );
  }
}
class AppNotification {  // ✅ Было: class Notification
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final String? relatedSubscriptionId;
  final String? relatedInvitationId;
  final String? fromUserId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({  // ✅ Было: Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.relatedSubscriptionId,
    this.relatedInvitationId,
    this.fromUserId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {  // ✅ Было: Notification.fromMap
    return AppNotification(  // ✅ Было: Notification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String?,
      relatedSubscriptionId: map['related_subscription_id'] as String?,
      relatedInvitationId: map['related_invitation_id'] as String?,
      fromUserId: map['from_user_id'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'related_subscription_id': relatedSubscriptionId,
      'related_invitation_id': relatedInvitationId,
      'from_user_id': fromUserId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Invitation {
  final String id;
  final String subscriptionId;
  final String groupId;
  final String fromUserId;
  final String toEmail;
  final String? toUserId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  Invitation({
    required this.id,
    required this.subscriptionId,
    required this.groupId,
    required this.fromUserId,
    required this.toEmail,
    this.toUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] as String,
      subscriptionId: map['subscription_id'] as String,
      groupId: map['group_id'] as String,
      fromUserId: map['from_user_id'] as String,
      toEmail: map['to_email'] as String,
      toUserId: map['to_user_id'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      respondedAt: map['responded_at'] != null ? DateTime.parse(map['responded_at'] as String) : null,
    );
  }
}