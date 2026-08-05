import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/meetings_backend_config.dart';
import 'package:eventa/src/features/meetings/data/campaign_local_storage.dart';
import 'package:eventa/src/features/meetings/domain/entities/event_meetup_campaign.dart';

/// Hive + Firestore для кампаний (нужно для push-триггера 2.4).
class CampaignRepository {
  CampaignRepository({
    CampaignLocalStorage? local,
    FirebaseFirestore? firestore,
  }) : _local = local ?? CampaignLocalStorage(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final CampaignLocalStorage _local;
  final FirebaseFirestore _firestore;

  bool get _remote => useFirestoreForMeetings && appUsesFirebaseBackend;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('eventMeetupCampaigns');

  Future<void> upsert(EventMeetupCampaign campaign) async {
    await _local.upsert(campaign);
    if (!_remote) return;
    await _col.doc(campaign.id).set({
      'eventId': campaign.eventId,
      'eventTitle': campaign.eventTitle,
      'organizerId': campaign.organizerId,
      'title': campaign.title,
      'createdAt': Timestamp.fromDate(campaign.createdAt),
      'targetGroupSize': campaign.targetGroupSize,
      'linkedMeetingIds': campaign.linkedMeetingIds,
      'status': campaign.status,
      'billingTier': campaign.billingTier,
      'promoted': campaign.promoted,
      'metrics': campaign.metrics.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<EventMeetupCampaign?> activeForEvent(String eventId) async {
    if (_remote) {
      try {
        final snap =
            await _col
                .where('eventId', isEqualTo: eventId)
                .where('status', isEqualTo: 'active')
                .limit(1)
                .get();
        if (snap.docs.isNotEmpty) {
          final remote = _fromDoc(snap.docs.first);
          await _local.upsert(remote);
          return remote;
        }
      } catch (_) {}
    }
    return _local.activeForEvent(eventId);
  }

  /// Активные продвигаемые кампании для слота в ленте.
  Future<List<EventMeetupCampaign>> readActivePromoted() async {
    if (_remote) {
      try {
        final snap =
            await _col
                .where('status', isEqualTo: 'active')
                .where('promoted', isEqualTo: true)
                .limit(50)
                .get();
        final list = snap.docs.map(_fromDoc).toList();
        for (final c in list) {
          await _local.upsert(c);
        }
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    final all = await _local.readAll();
    return all.where((c) => c.isActive && c.isPromoted).toList();
  }

  Future<List<EventMeetupCampaign>> readAll() => _local.readAll();

  Future<void> bumpMetric(
    String campaignId,
    String key, {
    int by = 1,
  }) async {
    const allowed = {
      'impressions',
      'detailOpens',
      'meetingsLinked',
      'launches',
    };
    if (!allowed.contains(key)) return;

    final all = await _local.readAll();
    final index = all.indexWhere((c) => c.id == campaignId);
    if (index < 0) return;
    final current = all[index];
    final m = current.metrics;
    final next = switch (key) {
      'impressions' => m.copyWith(impressions: m.impressions + by),
      'detailOpens' => m.copyWith(detailOpens: m.detailOpens + by),
      'meetingsLinked' => m.copyWith(meetingsLinked: m.meetingsLinked + by),
      'launches' => m.copyWith(launches: m.launches + by),
      _ => m,
    };
    final updated = current.copyWith(metrics: next);
    await _local.upsert(updated);
    if (!_remote) return;
    try {
      await _col.doc(campaignId).set({
        'metrics.$key': FieldValue.increment(by),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  EventMeetupCampaign _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data());
    data['id'] = doc.id;
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] =
          (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    return EventMeetupCampaign.fromMap(data);
  }
}
