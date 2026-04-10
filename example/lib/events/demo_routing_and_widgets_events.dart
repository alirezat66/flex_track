import 'package:flex_track/flex_track.dart';

/// Fires from [FlexImpressionTrack] when a promo card is sufficiently visible.
class DemoBannerImpressionEvent extends BaseEvent {
  DemoBannerImpressionEvent({required this.slotId});

  final String slotId;

  @override
  String getName() => 'demo_banner_impression';

  @override
  Map<String, Object>? getProperties() => {
        'slot_id': slotId,
        'surface': 'home_demo_scroll',
      };

  @override
  EventCategory get category => EventCategory.user;

  @override
  bool get isHighVolume => true;
}

/// Routed only to `console` + `firebase` (see [AnalyticsSetup] rules).
class DemoFreeTierOnlyEvent extends BaseEvent {
  @override
  String getName() => 'demo_free_tier_only';

  @override
  Map<String, Object>? getProperties() => const {
        'note': 'premium trackers intentionally excluded',
      };

  @override
  bool get requiresConsent => false;
}

/// Routed only to `mixpanel` + `amplitude` when consent allows.
class DemoPremiumOnlyEvent extends BaseEvent {
  @override
  String getName() => 'demo_premium_only';

  @override
  Map<String, Object>? getProperties() => const {
        'note': 'free-tier-only trackers excluded',
      };
}
