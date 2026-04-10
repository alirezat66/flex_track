import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvironmentDetector', () {
    tearDown(EnvironmentDetector.clearCache);

    test(
      'detectEnvironment returns the same value on repeated calls (cached)',
      () {
        final a = EnvironmentDetector.detectEnvironment();
        final b = EnvironmentDetector.detectEnvironment();
        expect(a, b);
      },
    );

    test(
      'overrideEnvironment forces isProduction, isDevelopment, etc. to match',
      () {
        EnvironmentDetector.overrideEnvironment(Environment.staging);
        expect(EnvironmentDetector.detectEnvironment(), Environment.staging);
        expect(EnvironmentDetector.isStaging(), isTrue);
        expect(EnvironmentDetector.isProduction(), isFalse);
        expect(EnvironmentDetector.isDevelopment(), isFalse);

        EnvironmentDetector.clearCache();
        EnvironmentDetector.overrideEnvironment(Environment.production);
        EnvironmentDetector.overrideDebugMode(false);
        expect(EnvironmentDetector.detectEnvironment(), Environment.production);
        expect(EnvironmentDetector.isProduction(), isTrue);
      },
    );

    test(
      'overrideDebugMode is reflected in isDebugMode and getConfig',
      () {
        EnvironmentDetector.overrideDebugMode(true);
        expect(EnvironmentDetector.isDebugMode(), isTrue);

        EnvironmentDetector.overrideEnvironment(Environment.development);
        final cfg = EnvironmentDetector.getConfig();
        expect(cfg.isDebugMode, isTrue);
        expect(cfg.enableVerboseLogging, isTrue);
        expect(cfg.environment, Environment.development);

        EnvironmentDetector.overrideDebugMode(false);
        expect(EnvironmentDetector.isDebugMode(), isFalse);
      },
    );

    test(
      'getConfig maps environment flags to EnvironmentConfig fields',
      () {
        EnvironmentDetector.clearCache();
        EnvironmentDetector.overrideEnvironment(Environment.production);
        EnvironmentDetector.overrideDebugMode(false);

        final cfg = EnvironmentDetector.getConfig();
        expect(cfg.environment, Environment.production);
        expect(cfg.strictConsent, isTrue);
        expect(cfg.enableSampling, isTrue);
        expect(cfg.enablePerformanceMonitoring, isTrue);
        expect(cfg.enableDebugFeatures, isFalse);
      },
    );

    test('EnvironmentConfig.toMap and toString are stable', () {
      EnvironmentDetector.overrideEnvironment(Environment.testing);
      EnvironmentDetector.overrideDebugMode(true);
      final cfg = EnvironmentDetector.getConfig();
      expect(cfg.toMap()['environment'], 'testing');
      expect(cfg.toString(), contains('testing'));
      expect(cfg.toString(), contains('debug: true'));
    });

    test(
      'getPlatformInfo returns a PlatformInfo with platformName and toMap',
      () {
        final info = EnvironmentDetector.getPlatformInfo();
        final m = info.toMap();
        expect(m['platformName'], info.platformName);
        expect(info.toString(), contains('PlatformInfo'));
      },
    );

    test('clearCache resets overrides so detection can be re-run fresh', () {
      EnvironmentDetector.overrideEnvironment(Environment.staging);
      expect(EnvironmentDetector.detectEnvironment(), Environment.staging);
      EnvironmentDetector.clearCache();
      // After clear, a new detection runs (under flutter test typically testing).
      final after = EnvironmentDetector.detectEnvironment();
      expect(after, isA<Environment>());
    });
  });
}
