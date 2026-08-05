import 'package:hive_flutter/hive_flutter.dart';

/// Бесплатный аккаунт: лимиты приглашений, созданий групп и кампаний в неделю.
class PremiumLimits {
  static const int freeInvitesPerWeek = 3;
  static const int freeCreatesPerWeek = 3;
  static const int freeCampaignsPerWeek = 1;
  static const int premiumPriceTenge = 1990;

  static String weekKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    final start = DateTime(date.year, date.month, date.day);
    // ISO-подобная неделя от понедельника.
    final monday = start.subtract(Duration(days: (start.weekday - 1) % 7));
    final y = monday.year;
    final w = ((monday.difference(DateTime(y, 1, 1)).inDays) / 7).floor() + 1;
    return '$y-W$w';
  }
}

class PremiumQuotaService {
  static const String _boxName = 'eventa_premium_quota';

  Future<Box<dynamic>> _open() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : Hive.openBox(_boxName);
  }

  Future<Map<String, int>> _usage(String uid) async {
    final box = await _open();
    final raw = box.get(uid);
    final week = PremiumLimits.weekKey();
    if (raw is! Map) {
      return {'invites': 0, 'creates': 0, 'campaigns': 0};
    }
    final storedWeek = raw['week']?.toString();
    if (storedWeek != week) {
      return {'invites': 0, 'creates': 0, 'campaigns': 0};
    }
    return {
      'invites': (raw['invites'] as num?)?.toInt() ?? 0,
      'creates': (raw['creates'] as num?)?.toInt() ?? 0,
      'campaigns': (raw['campaigns'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> _save(
    String uid, {
    required int invites,
    required int creates,
    required int campaigns,
  }) async {
    final box = await _open();
    await box.put(uid, {
      'week': PremiumLimits.weekKey(),
      'invites': invites,
      'creates': creates,
      'campaigns': campaigns,
    });
  }

  Future<int> invitesUsed(String uid) async =>
      (await _usage(uid))['invites'] ?? 0;

  Future<int> createsUsed(String uid) async =>
      (await _usage(uid))['creates'] ?? 0;

  Future<int> campaignsUsed(String uid) async =>
      (await _usage(uid))['campaigns'] ?? 0;

  Future<int> invitesLeft({
    required String uid,
    required bool isPremium,
  }) async {
    if (isPremium) return 999;
    final used = await invitesUsed(uid);
    return (PremiumLimits.freeInvitesPerWeek - used).clamp(
      0,
      PremiumLimits.freeInvitesPerWeek,
    );
  }

  Future<int> createsLeft({
    required String uid,
    required bool isPremium,
  }) async {
    if (isPremium) return 999;
    final used = await createsUsed(uid);
    return (PremiumLimits.freeCreatesPerWeek - used).clamp(
      0,
      PremiumLimits.freeCreatesPerWeek,
    );
  }

  Future<int> campaignsLeft({
    required String uid,
    required bool isPremium,
  }) async {
    if (isPremium) return 999;
    final used = await campaignsUsed(uid);
    return (PremiumLimits.freeCampaignsPerWeek - used).clamp(
      0,
      PremiumLimits.freeCampaignsPerWeek,
    );
  }

  Future<bool> canInvite({required String uid, required bool isPremium}) async {
    if (isPremium) return true;
    return (await invitesUsed(uid)) < PremiumLimits.freeInvitesPerWeek;
  }

  Future<bool> canCreateMeeting({
    required String uid,
    required bool isPremium,
  }) async {
    if (isPremium) return true;
    return (await createsUsed(uid)) < PremiumLimits.freeCreatesPerWeek;
  }

  Future<bool> canCreateCampaign({
    required String uid,
    required bool isPremium,
  }) async {
    if (isPremium) return true;
    return (await campaignsUsed(uid)) < PremiumLimits.freeCampaignsPerWeek;
  }

  Future<void> recordInvite(String uid) async {
    final u = await _usage(uid);
    await _save(
      uid,
      invites: (u['invites'] ?? 0) + 1,
      creates: u['creates'] ?? 0,
      campaigns: u['campaigns'] ?? 0,
    );
  }

  Future<void> recordCreate(String uid) async {
    final u = await _usage(uid);
    await _save(
      uid,
      invites: u['invites'] ?? 0,
      creates: (u['creates'] ?? 0) + 1,
      campaigns: u['campaigns'] ?? 0,
    );
  }

  Future<void> recordCampaign(String uid) async {
    final u = await _usage(uid);
    await _save(
      uid,
      invites: u['invites'] ?? 0,
      creates: u['creates'] ?? 0,
      campaigns: (u['campaigns'] ?? 0) + 1,
    );
  }
}

class PremiumQuotaExceededException implements Exception {
  const PremiumQuotaExceededException(this.kind);
  final String kind; // invite | create | campaign
  @override
  String toString() => 'premium_quota_$kind';
}
