import 'package:eventa/src/features/meetings/domain/entities/event_meetup_campaign.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CampaignLocalStorage {
  static const String _boxName = 'eventa_meetup_campaigns';
  static const String _key = 'campaigns';

  Future<Box<dynamic>> _openBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : Hive.openBox(_boxName);
  }

  Future<List<EventMeetupCampaign>> readAll() async {
    final box = await _openBox();
    final raw = box.get(_key);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              EventMeetupCampaign.fromMap(Map<dynamic, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> upsert(EventMeetupCampaign campaign) async {
    final all = await readAll();
    final index = all.indexWhere((c) => c.id == campaign.id);
    if (index >= 0) {
      all[index] = campaign;
    } else {
      all.add(campaign);
    }
    final box = await _openBox();
    await box.put(_key, all.map((e) => e.toMap()).toList());
  }

  Future<EventMeetupCampaign?> activeForEvent(String eventId) async {
    final all = await readAll();
    try {
      return all.firstWhere((c) => c.eventId == eventId && c.isActive);
    } catch (_) {
      return null;
    }
  }
}
