import 'package:eventa/src/features/meetings/domain/entities/event_meetup_campaign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('campaign billingTier and promoted defaults', () {
    final free = EventMeetupCampaign(
      id: 'c1',
      eventId: 'e1',
      eventTitle: 'Fest',
      organizerId: 'u1',
      title: 'Сбор',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    expect(free.isPaid, isFalse);
    expect(free.isPromoted, isFalse);
    expect(free.billingLabelRu, 'Бесплатно');

    final paid = free.copyWith(billingTier: 'paid', promoted: true);
    expect(paid.isPaid, isTrue);
    expect(paid.isPromoted, isTrue);
    expect(paid.billingLabelRu, 'Premium / оплачено');

    final restored = EventMeetupCampaign.fromMap(paid.toMap());
    expect(restored.billingTier, 'paid');
    expect(restored.promoted, isTrue);
  });

  test('campaign metrics round-trip', () {
    final campaign = EventMeetupCampaign(
      id: 'c3',
      eventId: 'e1',
      eventTitle: 'Fest',
      organizerId: 'u1',
      title: 'Сбор',
      createdAt: DateTime.utc(2026, 8, 1),
      billingTier: 'paid',
      promoted: true,
      metrics: const CampaignMetrics(
        impressions: 10,
        detailOpens: 3,
        meetingsLinked: 2,
        launches: 1,
      ),
    );
    final restored = EventMeetupCampaign.fromMap(campaign.toMap());
    expect(restored.metrics.impressions, 10);
    expect(restored.metrics.detailOpens, 3);
    expect(restored.metrics.meetingsLinked, 2);
    expect(restored.metrics.launches, 1);
  });

  test('legacy campaign maps without billing fields stay free', () {
    final restored = EventMeetupCampaign.fromMap({
      'id': 'c2',
      'eventId': 'e1',
      'eventTitle': 'Fest',
      'organizerId': 'u1',
      'title': 'Сбор',
      'createdAt': DateTime.utc(2026, 8, 1).toIso8601String(),
      'status': 'active',
    });
    expect(restored.billingTier, 'free');
    expect(restored.promoted, isFalse);
  });
}
