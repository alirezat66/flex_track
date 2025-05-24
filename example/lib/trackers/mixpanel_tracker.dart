import 'package:flex_track/flex_track.dart';
import 'package:flex_track_example/events/business_events.dart';

/// Mock Mixpanel Tracker (replace with real Mixpanel integration)
/// This is a placeholder since we don't want to add Mixpanel dependencies
class MixpanelTracker extends BaseTrackerStrategy {
  final String token;
  final Map<String, dynamic> _userProperties = {};
  String? _userId;

  MixpanelTracker._({
    required this.token,
  }) : super(
          id: 'mixpanel',
          name: 'Mixpanel Analytics',
        );

  /// Factory method to create Mixpanel tracker
  static Future<MixpanelTracker> create(String token) async {
    final tracker = MixpanelTracker._(token: token);

    // In real implementation:
    // tracker._mixpanel = await Mixpanel.init(
    //   token,
    //   trackAutomaticEvents: true,
    // );

    return tracker;
  }

  @override
  bool get isGDPRCompliant => true; // Mixpanel supports GDPR

  @override
  bool get supportsRealTime => true;

  @override
  int get maxBatchSize => 1000; // Mixpanel can handle large batches

  @override
  Future<void> doInitialize() async {
    // In real implementation, Mixpanel is initialized in the factory
    print('🎯 Mixpanel initialized with token: ${token.substring(0, 8)}...');
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    final properties = event.getProperties() ?? {};

    // Add event metadata
    final enhancedProperties = {
      ...properties,
      'event_category': event.category?.name,
      'contains_pii': event.containsPII,
      'is_essential': event.isEssential,
      'is_high_volume': event.isHighVolume,
    };

    // In real implementation:
    // _mixpanel.track(event.getName(), properties: enhancedProperties);

    print('🎯 Mixpanel tracking: ${event.getName()} $enhancedProperties');

    // Handle special events
    if (event is PurchaseEvent) {
      await _trackRevenue(event);
    }
  }

  Future<void> _trackRevenue(PurchaseEvent event) async {
    // In real implementation:
    // _mixpanel.getPeople().trackCharge(event.amount, properties: {
    //   'product_id': event.productId,
    //   'product_name': event.productName,
    //   'currency': event.currency,
    //   'payment_method': event.paymentMethod,
    // });

    print('🎯 Mixpanel revenue: \$${event.amount} ${event.currency}');
  }

  @override
  bool supportsBatchTracking() => true;

  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    // Mixpanel doesn't have a native batch API, but we can optimize
    for (final event in events) {
      await doTrack(event);
    }

    print('🎯 Mixpanel batch: ${events.length} events');
  }

  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    _userProperties.addAll(properties);

    // In real implementation:
    // _mixpanel.getPeople().set(properties);

    print('🎯 Mixpanel user properties: $properties');
  }

  @override
  Future<void> doIdentifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    _userId = userId;

    // In real implementation:
    // _mixpanel.identify(userId);

    print('🎯 Mixpanel identify: $userId');

    if (properties != null) {
      await doSetUserProperties(properties);
    }
  }

  @override
  Future<void> doReset() async {
    _userProperties.clear();
    _userId = null;

    // In real implementation:
    // _mixpanel.reset();

    print('🎯 Mixpanel reset');
  }

  @override
  Future<void> doFlush() async {
    // In real implementation:
    // _mixpanel.flush();

    print('🎯 Mixpanel flush');
  }

  @override
  Map<String, dynamic> getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      'token': '${token.substring(0, 8)}...',
      'userId': _userId,
      'userPropertiesCount': _userProperties.length,
      'implementationType': 'mock', // Change to 'real' in actual implementation
    };
  }
}

// Import this for real Mixpanel implementation:
// import 'package:mixpanel_flutter/mixpanel_flutter.dart';
