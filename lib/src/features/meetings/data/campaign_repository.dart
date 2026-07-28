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
          final data = Map<String, dynamic>.from(snap.docs.first.data());
          data['id'] = snap.docs.first.id;
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] =
                (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          final remote = EventMeetupCampaign.fromMap(data);
          await _local.upsert(remote);
          return remote;
        }
      } catch (_) {}
    }
    return _local.activeForEvent(eventId);
  }

  Future<List<EventMeetupCampaign>> readAll() => _local.readAll();
}
