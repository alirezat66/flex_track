import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformanceDefaults', () {
    late RoutingBuilder builder;

    setUp(() {
      builder = RoutingBuilder();
    });

    group('apply (base performance preset)', () {
      test('adds the expected number of routing rules', () {
        PerformanceDefaults.apply(builder);
        expect(builder.build().rules, hasLength(13));
      });

      test('produces a configuration that passes validation', () {
        PerformanceDefaults.apply(builder);
        expect(builder.build().validate(), isEmpty);
      });

      test('includes a default catch-all rule with medium sampling', () {
        PerformanceDefaults.apply(builder);
        final config = builder.build();
        final defaultRule = config.rules.firstWhere((r) => r.isDefault);
        expect(defaultRule.sampleRate, 0.5);
        expect(defaultRule.priority, 0);
        expect(
          defaultRule.description,
          contains('Default performance-optimized'),
        );
      });

      test('routes high-volume events with heavy sampling and high priority',
          () {
        PerformanceDefaults.apply(builder);
        final rule = builder.build().rules.firstWhere(
              (r) => r.isHighVolume == true,
            );
        expect(rule.sampleRate, 0.01);
        expect(rule.priority, 15);
        expect(rule.description, contains('High volume'));
      });

      test('routes essential events with no sampling and top priority', () {
        PerformanceDefaults.apply(builder);
        final rule = builder.build().rules.firstWhere(
              (r) => r.isEssential == true,
            );
        expect(rule.sampleRate, 1.0);
        expect(rule.priority, 25);
      });

      test('routes security category events with no sampling', () {
        PerformanceDefaults.apply(builder);
        final rule = builder.build().rules.firstWhere(
              (r) => r.category == EventCategory.security,
            );
        expect(rule.sampleRate, 1.0);
        expect(rule.priority, 22);
      });

      test('routes critical business event names without sampling', () {
        PerformanceDefaults.apply(builder);
        final rule = builder.build().rules.firstWhere(
              (r) =>
                  r.eventNameRegex != null &&
                  r.description?.contains('Critical events') == true,
            );
        expect(rule.sampleRate, 1.0);
        expect(rule.priority, 20);
      });

      test('applies extreme sampling to animation or frame event patterns', () {
        PerformanceDefaults.apply(builder);
        final rule = builder.build().rules.firstWhere(
              (r) => r.description?.contains('Animation events') == true,
            );
        expect(rule.sampleRate, 0.0001);
        expect(rule.priority, 16);
      });

      test('sends technical category events to development with debug-only',
          () {
        PerformanceDefaults.apply(builder);
        final rule = builder.build().rules.firstWhere(
              (r) => r.category == EventCategory.technical,
            );
        expect(rule.debugOnly, isTrue);
        expect(rule.targetGroup.name, 'development');
        expect(rule.sampleRate, 0.1);
      });
    });

    group('applyMobileOptimized', () {
      test('layers mobile rules on top of base apply()', () {
        PerformanceDefaults.applyMobileOptimized(builder);
        expect(builder.build().rules, hasLength(16));
        expect(builder.build().validate(), isEmpty);
      });

      test('adds aggressive sampling for high volume on mobile', () {
        PerformanceDefaults.applyMobileOptimized(builder);
        final mobileHighVolume = builder.build().rules.firstWhere(
              (r) =>
                  r.isHighVolume == true &&
                  r.description?.contains('Mobile:') == true,
            );
        expect(mobileHighVolume.sampleRate, 0.005);
      });

      test('adds touch and gesture sampling rules for mobile', () {
        PerformanceDefaults.applyMobileOptimized(builder);
        final touchRule = builder.build().rules.firstWhere(
              (r) => r.description?.contains('Mobile: Touch') == true,
            );
        expect(touchRule.sampleRate, 0.01);
        expect(touchRule.eventNameRegex, isNotNull);
      });

      test('adds a location property rule for battery-conscious sampling', () {
        PerformanceDefaults.applyMobileOptimized(builder);
        final locRule = builder.build().rules.firstWhere(
              (r) => r.hasProperty == 'location',
            );
        expect(locRule.sampleRate, 0.1);
        expect(locRule.description, contains('Location'));
      });
    });

    group('applyWebOptimized', () {
      test('adds web navigation and DOM rules then base apply()', () {
        PerformanceDefaults.applyWebOptimized(builder);
        expect(builder.build().rules, hasLength(15));
        expect(builder.build().validate(), isEmpty);
      });

      test('includes light sampling for SPA-style navigation events', () {
        PerformanceDefaults.applyWebOptimized(builder);
        final navRule = builder.build().rules.firstWhere(
              (r) => r.description?.contains('Web: Navigation') == true,
            );
        expect(navRule.sampleRate, 0.1);
        expect(navRule.priority, 14);
      });

      test('includes moderate sampling for DOM interaction patterns', () {
        PerformanceDefaults.applyWebOptimized(builder);
        final domRule = builder.build().rules.firstWhere(
              (r) => r.description?.contains('Web: DOM') == true,
            );
        expect(domRule.sampleRate, 0.05);
      });
    });

    group('applyServerOptimized', () {
      test('adds server-specific rules before base apply()', () {
        PerformanceDefaults.applyServerOptimized(builder);
        expect(builder.build().rules, hasLength(16));
        expect(builder.build().validate(), isEmpty);
      });

      test('uses medium sampling for HTTP-style request patterns', () {
        PerformanceDefaults.applyServerOptimized(builder);
        final httpRule = builder.build().rules.firstWhere(
              (r) => r.description?.contains('Server: HTTP') == true,
            );
        expect(httpRule.sampleRate, 0.5);
      });

      test('uses light sampling for database query patterns', () {
        PerformanceDefaults.applyServerOptimized(builder);
        final dbRule = builder.build().rules.firstWhere(
              (r) => r.description?.contains('Server: Database') == true,
            );
        expect(dbRule.sampleRate, 0.1);
      });

      test('heavily samples cache-related event patterns', () {
        PerformanceDefaults.applyServerOptimized(builder);
        final cacheRule = builder.build().rules.firstWhere(
              (r) => r.description?.contains('Server: Cache') == true,
            );
        expect(cacheRule.sampleRate, 0.01);
      });
    });

    group('applyLowLatency', () {
      test('installs only three focused rules', () {
        PerformanceDefaults.applyLowLatency(builder);
        expect(builder.build().rules, hasLength(3));
        expect(builder.build().validate(), isEmpty);
      });

      test('keeps essential and critical paths unsampled', () {
        PerformanceDefaults.applyLowLatency(builder);
        final config = builder.build();
        final essential = config.rules.firstWhere((r) => r.isEssential == true);
        final critical = config.rules.firstWhere(
          (r) => r.description?.contains('Low-latency: Critical') == true,
        );
        expect(essential.sampleRate, 1.0);
        expect(critical.sampleRate, 1.0);
      });

      test('uses aggressive default sampling for everything else', () {
        PerformanceDefaults.applyLowLatency(builder);
        final defaultRule =
            builder.build().rules.firstWhere((r) => r.isDefault);
        expect(defaultRule.sampleRate, 0.01);
      });
    });

    group('applyBandwidthConscious', () {
      test('installs four bandwidth-oriented rules', () {
        PerformanceDefaults.applyBandwidthConscious(builder);
        expect(builder.build().rules, hasLength(4));
        expect(builder.build().validate(), isEmpty);
      });

      test('samples error streams lightly while keeping business events full',
          () {
        PerformanceDefaults.applyBandwidthConscious(builder);
        final config = builder.build();
        final business = config.rules.firstWhere(
          (r) => r.description?.contains('Business-critical') == true,
        );
        final errors = config.rules.firstWhere(
          (r) => r.description?.contains('Bandwidth: Error') == true,
        );
        expect(business.sampleRate, 1.0);
        expect(errors.sampleRate, 0.1);
      });

      test('uses a very low default sample rate', () {
        PerformanceDefaults.applyBandwidthConscious(builder);
        final defaultRule =
            builder.build().rules.firstWhere((r) => r.isDefault);
        expect(defaultRule.sampleRate, 0.001);
      });
    });

    group('applyHighThroughput', () {
      test('installs four rules for very high event volume', () {
        PerformanceDefaults.applyHighThroughput(builder);
        expect(builder.build().rules, hasLength(4));
        expect(builder.build().validate(), isEmpty);
      });

      test('even essential events are partially sampled', () {
        PerformanceDefaults.applyHighThroughput(builder);
        final essential =
            builder.build().rules.firstWhere((r) => r.isEssential == true);
        expect(essential.sampleRate, 0.1);
      });

      test('uses extremely low default sampling', () {
        PerformanceDefaults.applyHighThroughput(builder);
        final defaultRule =
            builder.build().rules.firstWhere((r) => r.isDefault);
        expect(defaultRule.sampleRate, 0.00001);
      });
    });

    group('Integration with FlexTrack', () {
      test('works when passed through setupWithRouting', () async {
        final mock = MockTracker();
        await FlexTrack.setupWithRouting([mock], (b) {
          PerformanceDefaults.apply(b);
          return b;
        });
        expect(FlexTrack.isSetUp, isTrue);
        await FlexTrack.reset();
      });
    });
  });
}
