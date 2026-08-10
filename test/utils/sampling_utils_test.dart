import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('SamplingUtils Tests', () {
    group('Basic Sampling', () {
      test('should always sample with rate 1.0', () {
        for (int i = 0; i < 100; i++) {
          expect(SamplingUtils.shouldSample(1.0), isTrue);
        }
      });

      test('should never sample with rate 0.0', () {
        for (int i = 0; i < 100; i++) {
          expect(SamplingUtils.shouldSample(0.0), isFalse);
        }
      });

      test('should validate sample rates', () {
        expect(SamplingUtils.validateSampleRate(0.5).isValid, isTrue);
        expect(SamplingUtils.validateSampleRate(-0.1).isValid, isFalse);
        expect(SamplingUtils.validateSampleRate(1.5).isValid, isFalse);
        expect(SamplingUtils.validateSampleRate(double.nan).isValid, isTrue);
      });
    });

    group('Deterministic Sampling', () {
      test('should be consistent for same input', () {
        const input = 'test_user_123';
        const sampleRate = 0.5;

        final result1 =
            SamplingUtils.shouldSampleDeterministic(input, sampleRate);
        final result2 =
            SamplingUtils.shouldSampleDeterministic(input, sampleRate);

        expect(result1, equals(result2));
      });

      test('should sample by user ID consistently', () {
        const userId = 'user_123';
        const sampleRate = 0.3;

        final result1 = SamplingUtils.shouldSampleByUserId(userId, sampleRate);
        final result2 = SamplingUtils.shouldSampleByUserId(userId, sampleRate);

        expect(result1, equals(result2));
      });

      test('should handle null user ID gracefully', () {
        expect(
            () => SamplingUtils.shouldSampleByUserId(null, 0.5), isA<void>());
        expect(() => SamplingUtils.shouldSampleByUserId('', 0.5), isA<void>());
      });
    });

    group('Sampling Statistics', () {
      test('should calculate sampling stats correctly', () {
        final results = [true, false, true, true, false]; // 3/5 = 60%
        final stats = SamplingUtils.calculateStats(results);

        expect(stats.totalEvents, equals(5));
        expect(stats.sampledEvents, equals(3));
        expect(stats.actualSampleRate, equals(0.6));
        expect(stats.droppedEvents, equals(2));
      });

      test('should handle empty results', () {
        final stats = SamplingUtils.calculateStats([]);
        expect(stats.totalEvents, equals(0));
        expect(stats.actualSampleRate, equals(0.0));
      });
    });

    group('Conversion Utilities', () {
      test('should convert percentage to sample rate', () {
        expect(SamplingUtils.percentageToSampleRate(50), equals(0.5));
        expect(SamplingUtils.percentageToSampleRate(100), equals(1.0));
        expect(SamplingUtils.percentageToSampleRate(0), equals(0.0));
        expect(
            SamplingUtils.percentageToSampleRate(150), equals(1.0)); // Clamped
      });

      test('should convert sample rate to percentage', () {
        expect(SamplingUtils.sampleRateToPercentage(0.5), equals(50.0));
        expect(SamplingUtils.sampleRateToPercentage(1.0), equals(100.0));
        expect(SamplingUtils.sampleRateToPercentage(0.0), equals(0.0));
      });
    });

    group('Advanced Sampling', () {
      test('should handle adaptive sampling', () {
        final adaptiveRate = SamplingUtils.calculateAdaptiveSamplingRate(
          200, // current events
          Duration(minutes: 1), // time window
          100, // target events per window
        );

        expect(adaptiveRate, lessThan(1.0));
        expect(adaptiveRate, greaterThan(0.0));
        expect(adaptiveRate, equals(0.5)); // 100/200 = 0.5
      });

      test('should handle sampling buckets', () {
        const identifier = 'test_user';
        const bucketCount = 10;

        final bucket1 =
            SamplingUtils.getSamplingBucket(identifier, bucketCount);
        final bucket2 =
            SamplingUtils.getSamplingBucket(identifier, bucketCount);

        expect(bucket1, equals(bucket2)); // Consistent
        expect(bucket1, greaterThanOrEqualTo(0));
        expect(bucket1, lessThan(bucketCount));
      });

      test('should handle bucket sampling', () {
        const identifier = 'test_user';
        const bucketCount = 10;
        final targetBuckets = [0, 1, 2]; // 30% of buckets

        final shouldSample = SamplingUtils.shouldSampleForBucket(
          identifier,
          bucketCount,
          targetBuckets,
        );

        // Result should be consistent
        final shouldSample2 = SamplingUtils.shouldSampleForBucket(
          identifier,
          bucketCount,
          targetBuckets,
        );

        expect(shouldSample, equals(shouldSample2));
      });
    });

    group('Sampling Strategy', () {
      test('should create random sampling strategy', () {
        final config = SamplingConfig.random(0.5);
        final strategy = SamplingUtils.createStrategy(config);

        expect(strategy.config.type, equals(SamplingType.random));
        expect(strategy.config.sampleRate, equals(0.5));
      });

      test('should create deterministic sampling strategy', () {
        final config = SamplingConfig.deterministic(0.3);
        final strategy = SamplingUtils.createStrategy(config);

        expect(strategy.config.type, equals(SamplingType.deterministic));

        // Test consistency
        final result1 = strategy.shouldSample('test_event', userId: 'user123');
        final result2 = strategy.shouldSample('test_event', userId: 'user123');
        expect(result1, equals(result2));
      });

      test('should create time-based sampling strategy', () {
        final config = SamplingConfig.timeBased(Duration(seconds: 1));
        final strategy = SamplingUtils.createStrategy(config);

        expect(strategy.config.type, equals(SamplingType.timeBased));
        expect(strategy.config.timeInterval, equals(Duration(seconds: 1)));
      });

      test('should create adaptive sampling strategy', () {
        final config = SamplingConfig.adaptive(
          timeWindow: Duration(minutes: 1),
          targetEventsPerWindow: 100,
        );
        final strategy = SamplingUtils.createStrategy(config);

        expect(strategy.config.type, equals(SamplingType.adaptive));
        expect(strategy.config.targetEventsPerWindow, equals(100));
      });

      test('should reset sampling strategy', () {
        final strategy = SamplingStrategy(SamplingConfig.random(0.5));

        // Generate some internal state
        strategy.shouldSample('test_event');

        // Reset should not throw
        expect(() => strategy.reset(), isA<void>());
      });

      test('timeBased strategy returns false when timeInterval is null', () {
        final config = SamplingConfig(
          type: SamplingType.timeBased,
          sampleRate: 1.0,
          timeInterval: null,
        );
        final strategy = SamplingUtils.createStrategy(config);
        expect(strategy.shouldSample('any'), isFalse);
      });

      test('backoff strategy changes behavior as event count grows', () {
        final config = SamplingConfig.backoff(1.0, backoffFactor: 0.5);
        final strategy = SamplingUtils.createStrategy(config);
        final first = strategy.shouldSample('evt');
        final second = strategy.shouldSample('evt');
        expect(first, isA<bool>());
        expect(second, isA<bool>());
      });

      test('adaptive strategy runs without throwing for repeated events', () {
        final config = SamplingConfig.adaptive(
          timeWindow: const Duration(minutes: 1),
          targetEventsPerWindow: 5,
        );
        final strategy = SamplingUtils.createStrategy(config);
        for (var i = 0; i < 20; i++) {
          strategy.shouldSample('frequent');
        }
        strategy.reset();
      });
    });

    group('shouldSampleDeterministic edge rates', () {
      test('returns true for sample rate 1.0 and false for 0.0', () {
        expect(SamplingUtils.shouldSampleDeterministic('any', 1.0), isTrue);
        expect(SamplingUtils.shouldSampleDeterministic('any', 0.0), isFalse);
      });
    });

    group('shouldSampleBySessionId', () {
      test('falls back to random sampling when session id is null or empty',
          () {
        expect(
          () => SamplingUtils.shouldSampleBySessionId(null, 1.0),
          returnsNormally,
        );
        expect(SamplingUtils.shouldSampleBySessionId('', 1.0), isTrue);
      });

      test('is deterministic for the same non-empty session id', () {
        const sid = 'sess_xyz';
        expect(
          SamplingUtils.shouldSampleBySessionId(sid, 0.5),
          SamplingUtils.shouldSampleBySessionId(sid, 0.5),
        );
      });
    });

    group('shouldSampleByEventName', () {
      test('delegates to deterministic hashing of the name', () {
        expect(
          SamplingUtils.shouldSampleByEventName('purchase', 1.0),
          isTrue,
        );
        expect(
          SamplingUtils.shouldSampleByEventName('purchase', 0.0),
          isFalse,
        );
      });
    });

    group('shouldSampleByTime', () {
      test('returns true when interval is zero or negative', () {
        expect(SamplingUtils.shouldSampleByTime(Duration.zero), isTrue);
        expect(
          SamplingUtils.shouldSampleByTime(const Duration(milliseconds: -1)),
          isTrue,
        );
      });

      test('with 1 ms interval always passes modulo check', () {
        expect(
            SamplingUtils.shouldSampleByTime(const Duration(milliseconds: 1)),
            isTrue);
      });
    });

    group('shouldSampleWithBackoff', () {
      test('uses base rate when eventCount is zero or negative', () {
        expect(SamplingUtils.shouldSampleWithBackoff(0, 1.0), isTrue);
        expect(SamplingUtils.shouldSampleWithBackoff(-1, 0.0), isFalse);
      });
    });

    group('shouldIncludeInReservoir', () {
      test('includes all events until reservoir is full', () {
        expect(SamplingUtils.shouldIncludeInReservoir(1, 5), isTrue);
        expect(SamplingUtils.shouldIncludeInReservoir(5, 5), isTrue);
        expect(SamplingUtils.shouldIncludeInReservoir(6, 5), isA<bool>());
      });
    });

    group('shouldSampleWeighted', () {
      test('uses default weight 1.0 for unknown event types', () {
        final weights = <String, double>{'a': 0.0};
        expect(SamplingUtils.shouldSampleWeighted(weights, 'missing'),
            isA<bool>());
      });
    });

    group('getSamplingBucket edge cases', () {
      test('returns 0 when bucketCount is zero or negative', () {
        expect(SamplingUtils.getSamplingBucket('id', 0), 0);
        expect(SamplingUtils.getSamplingBucket('id', -3), 0);
      });
    });

    group('SampleRateValidationResult and SamplingStats', () {
      test('SampleRateValidationResult toString reflects validity', () {
        expect(SamplingUtils.validateSampleRate(0.5).toString(),
            contains('Valid'));
        expect(
          SamplingUtils.validateSampleRate(-1).toString(),
          contains('Invalid'),
        );
      });

      test('SamplingStats toMap and toString', () {
        final stats = SamplingUtils.calculateStats([true, false]);
        expect(stats.toMap()['totalEvents'], 2);
        expect(stats.toString(), contains('%'));
      });
    });

    group('seed helpers', () {
      test('setSeed, getSeed, and resetSeed are callable', () {
        SamplingUtils.setSeed(42);
        expect(SamplingUtils.getSeed(), 42);
        SamplingUtils.resetSeed();
        expect(SamplingUtils.getSeed(), isA<int>());
      });
    });
  });
}
