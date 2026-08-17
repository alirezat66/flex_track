import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

class PurchaseEvent extends BaseEvent {
  @override
  String get name => 'purchase';

  @override
  Map<String, Object>? get properties => null;
}

class SubscriptionPurchaseEvent extends PurchaseEvent {}

void main() {
  group('routing identity', () {
    late RoutingEngine engine;

    setUp(() {
      final configuration = (RoutingBuilder()
            ..route<PurchaseEvent>().to(['billing']).withPriority(10).and()
            ..routeDefault().to(['other']).and())
          .build();

      engine = RoutingEngine(configuration);
    });

    test('a type route matches subclasses', () {
      final result = engine.routeEvent(
        SubscriptionPurchaseEvent(),
        availableTrackers: {'billing', 'other'},
      );

      expect(result.targetTrackers, ['billing']);
    });

    test('an enriched event preserves its original type route', () {
      final result = engine.routeEvent(
        EnrichedEvent(PurchaseEvent(), {'app_version': '2.1.0'}),
        availableTrackers: {'billing', 'other'},
      );

      expect(result.targetTrackers, ['billing']);
    });

    test('nested enrichment preserves the deepest original type route', () {
      final result = engine.routeEvent(
        EnrichedEvent(
          EnrichedEvent(SubscriptionPurchaseEvent(), {'session': 'one'}),
          {'app_version': '2.1.0'},
        ),
        availableTrackers: {'billing', 'other'},
      );

      expect(result.targetTrackers, ['billing']);
    });

    test('transformed properties remain visible to property routes', () {
      final propertyConfiguration = (RoutingBuilder()
            ..routeWithProperty('app_version')
                .to(['versioned'])
                .withPriority(10)
                .and()
            ..routeDefault().to(['other']).and())
          .build();
      final propertyEngine = RoutingEngine(propertyConfiguration);

      final result = propertyEngine.routeEvent(
        EnrichedEvent(PurchaseEvent(), {'app_version': '2.1.0'}),
        availableTrackers: {'versioned', 'other'},
      );

      expect(result.targetTrackers, ['versioned']);
    });

    test('debug output uses the same routing identity semantics', () {
      final event = EnrichedEvent(SubscriptionPurchaseEvent(), const {});

      final debug = engine.debugEvent(
        event,
        availableTrackers: {'billing', 'other'},
      );

      expect(debug.routingResult.targetTrackers, ['billing']);
      expect(
        debug.matchingRules.where(
          (rule) => rule.eventType == PurchaseEvent,
        ),
        hasLength(1),
      );
      expect(
        debug.nonMatchingRules.where(
          (entry) => entry.rule.eventType == PurchaseEvent,
        ),
        isEmpty,
      );
    });
  });
}
