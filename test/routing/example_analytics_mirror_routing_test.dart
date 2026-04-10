import 'package:flex_track/src/core/event_processor.dart';
import 'package:flex_track/src/core/tracker_registry.dart';
import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/routing/event_category.dart';
import 'package:flex_track/src/models/routing/routing_config.dart';
import 'package:flex_track/src/routing/presets/gdpr_defaults.dart';
import 'package:flex_track/src/routing/routing_builder.dart';
import 'package:flex_track/src/routing/routing_engine.dart';
import 'package:flex_track/src/strategies/base_tracker_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

class _DemoFreeTier extends BaseEvent {
  @override
  String getName() => 'demo_free_tier_only';

  @override
  Map<String, Object>? getProperties() => const {'note': 'x'};

  @override
  bool get requiresConsent => false;
}

class _DemoBanner extends BaseEvent {
  @override
  String getName() => 'demo_banner_impression';

  @override
  Map<String, Object>? getProperties() => const {'slot_id': '1'};

  @override
  EventCategory get category => EventCategory.user;
}

class _StubTracker extends BaseTrackerStrategy {
  _StubTracker(String id, String name) : super(id: id, name: name);

  @override
  Future<void> doInitialize() async {}

  @override
  Future<void> doTrack(BaseEvent event) async {}
}

RoutingConfiguration _exampleLikeConfig() {
  final builder = RoutingBuilder();
  builder
      .defineGroup('free_tier', ['console', 'firebase'])
      .defineGroup('premium', ['mixpanel', 'amplitude'])
      .defineGroup('internal', ['custom_api'])
      .defineGroup('gdpr_compliant', ['firebase', 'custom_api']);

  GDPRDefaults.apply(builder, compliantTrackers: ['firebase', 'custom_api']);

  builder
      .routeExact('demo_free_tier_only')
      .to(['console', 'firebase'])
      .skipConsent()
      .noSampling()
      .withPriority(28)
      .withDescription('Demo free tier')
      .and();

  builder
      .routeExact('demo_banner_impression')
      .toGroupNamed('premium')
      .requireConsent()
      .noSampling()
      .withPriority(27)
      .withDescription('Demo banner')
      .and();

  builder
      .routeCategory(EventCategory.user)
      .toGroupNamed('premium')
      .requireConsent()
      .lightSampling()
      .withPriority(15)
      .withDescription('User behavior')
      .and();

  builder
      .routeDefault()
      .toGroupNamed('free_tier')
      .mediumSampling()
      .withPriority(0)
      .withDescription('Default free tier')
      .and();

  return builder.build();
}

void main() {
  test('mirror example: free-tier demo routes without general consent', () {
    final config = _exampleLikeConfig();
    final demoRule = config.rules
        .where((r) => r.eventNameRegex != null)
        .firstWhere((r) => r.eventNameRegex!.pattern == r'^demo_free_tier_only$');
    expect(demoRule.eventType, isNull);
    expect(
      demoRule.matches(_DemoFreeTier(), isDebugMode: config.isDebugMode),
      isTrue,
    );
    final engine = RoutingEngine(config);
    final regIds = {'console', 'firebase', 'mixpanel', 'amplitude'};
    final r = engine.routeEvent(
      _DemoFreeTier(),
      hasGeneralConsent: false,
      hasPIIConsent: false,
      availableTrackers: regIds,
    );
    expect(r.targetTrackers, unorderedEquals(['console', 'firebase']));
  });

  test('mirror example: banner needs general consent', () {
    final config = _exampleLikeConfig();
    final engine = RoutingEngine(config);
    final regIds = {'console', 'firebase', 'mixpanel', 'amplitude'};

    final noConsent = engine.routeEvent(
      _DemoBanner(),
      hasGeneralConsent: false,
      hasPIIConsent: false,
      availableTrackers: regIds,
    );
    expect(noConsent.targetTrackers, isEmpty);

    final withConsent = engine.routeEvent(
      _DemoBanner(),
      hasGeneralConsent: true,
      hasPIIConsent: true,
      availableTrackers: regIds,
    );
    expect(withConsent.targetTrackers, unorderedEquals(['mixpanel', 'amplitude']));
  });

  test('EventProcessor emits non-empty routingResult.targetTrackers', () async {
    final config = _exampleLikeConfig();
    final reg = TrackerRegistry()
      ..registerAll([
        _StubTracker('console', 'Console'),
        _StubTracker('firebase', 'Firebase'),
        _StubTracker('mixpanel', 'Mixpanel'),
        _StubTracker('amplitude', 'Amplitude'),
      ]);
    await reg.initialize();
    final proc = EventProcessor(
      trackerRegistry: reg,
      routingEngine: RoutingEngine(config),
    );
    proc.setConsent(general: true, pii: true);

    final r1 = await proc.processEvent(_DemoFreeTier());
    expect(r1.routingResult.targetTrackers, unorderedEquals(['console', 'firebase']));

    final r2 = await proc.processEvent(_DemoBanner());
    expect(r2.routingResult.targetTrackers, unorderedEquals(['mixpanel', 'amplitude']));
  });
}
