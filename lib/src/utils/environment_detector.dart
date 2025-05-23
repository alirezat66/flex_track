import '../models/context/tracking_context.dart';

/// Utility class for detecting the current runtime environment
class EnvironmentDetector {
  static Environment? _cachedEnvironment;
  static bool? _cachedDebugMode;

  /// Detect the current environment based on various indicators
  static Environment detectEnvironment() {
    if (_cachedEnvironment != null) {
      return _cachedEnvironment!;
    }

    // Check debug mode first
    final isDebug = isDebugMode();

    // Check for explicit environment variables or configuration
    const env = String.fromEnvironment('ENV', defaultValue: '');
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: '');
    const mode = String.fromEnvironment('MODE', defaultValue: '');

    // Check common environment indicators
    if (_isProduction(env, flavor, mode, isDebug)) {
      _cachedEnvironment = Environment.production;
    } else if (_isTesting(env, flavor, mode)) {
      _cachedEnvironment = Environment.testing;
    } else if (_isStaging(env, flavor, mode)) {
      _cachedEnvironment = Environment.staging;
    } else if (isDebug) {
      _cachedEnvironment = Environment.development;
    } else {
      // Default to production if uncertain
      _cachedEnvironment = Environment.production;
    }

    return _cachedEnvironment!;
  }

  /// Check if the app is running in debug mode
  static bool isDebugMode() {
    if (_cachedDebugMode != null) {
      return _cachedDebugMode!;
    }

    // In Dart/Flutter, debug mode can be detected using assertions
    bool debugMode = false;
    assert(() {
      debugMode = true;
      return true;
    }());

    _cachedDebugMode = debugMode;
    return debugMode;
  }

  /// Check if running in production environment
  static bool isProduction() {
    return detectEnvironment() == Environment.production;
  }

  /// Check if running in development environment
  static bool isDevelopment() {
    return detectEnvironment() == Environment.development;
  }

  /// Check if running in testing environment
  static bool isTesting() {
    return detectEnvironment() == Environment.testing;
  }

  /// Check if running in staging environment
  static bool isStaging() {
    return detectEnvironment() == Environment.staging;
  }

  /// Get environment-specific configuration
  static EnvironmentConfig getConfig() {
    final env = detectEnvironment();
    final isDebug = isDebugMode();

    return EnvironmentConfig(
      environment: env,
      isDebugMode: isDebug,
      enableSampling: env.enableSampling,
      enableDebugFeatures: env.enableDebug,
      strictConsent: env.strictConsent,
      enableVerboseLogging: isDebug,
      enablePerformanceMonitoring:
          env == Environment.production || env == Environment.staging,
    );
  }

  /// Override the detected environment (useful for testing)
  static void overrideEnvironment(Environment environment) {
    _cachedEnvironment = environment;
  }

  /// Override debug mode detection (useful for testing)
  static void overrideDebugMode(bool isDebug) {
    _cachedDebugMode = isDebug;
  }

  /// Clear cached values (useful for testing)
  static void clearCache() {
    _cachedEnvironment = null;
    _cachedDebugMode = null;
  }

  /// Check for production indicators
  static bool _isProduction(
      String env, String flavor, String mode, bool isDebug) {
    // Not production if in debug mode
    if (isDebug) return false;

    // Check explicit production indicators
    final prodIndicators = ['prod', 'production', 'release'];
    return prodIndicators.contains(env.toLowerCase()) ||
        prodIndicators.contains(flavor.toLowerCase()) ||
        prodIndicators.contains(mode.toLowerCase());
  }

  /// Check for testing indicators
  static bool _isTesting(String env, String flavor, String mode) {
    final testIndicators = ['test', 'testing', 'unittest'];
    return testIndicators.contains(env.toLowerCase()) ||
        testIndicators.contains(flavor.toLowerCase()) ||
        testIndicators.contains(mode.toLowerCase()) ||
        _isRunningTests();
  }

  /// Check for staging indicators
  static bool _isStaging(String env, String flavor, String mode) {
    final stagingIndicators = ['staging', 'stage', 'uat', 'beta'];
    return stagingIndicators.contains(env.toLowerCase()) ||
        stagingIndicators.contains(flavor.toLowerCase()) ||
        stagingIndicators.contains(mode.toLowerCase());
  }

  /// Detect if we're running in a test environment
  static bool _isRunningTests() {
    // This is a heuristic - may not work in all test environments
    try {
      // In Flutter tests, this package is usually available
      return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  /// Get platform-specific information
  static PlatformInfo getPlatformInfo() {
    // Note: This is a basic implementation
    // In a real app, you might use dart:io or platform-specific detection
    return PlatformInfo(
      isWeb: _isWeb(),
      isAndroid: _isAndroid(),
      isIOS: _isIOS(),
      isDesktop: _isDesktop(),
      isMobile: _isMobile(),
    );
  }

  // Platform detection helpers (basic implementation)
  static bool _isWeb() {
    return identical(0, 0.0); // Web-specific behavior
  }

  static bool _isAndroid() {
    // In a real implementation, you'd use dart:io Platform.isAndroid
    // This is just a placeholder
    return false;
  }

  static bool _isIOS() {
    // In a real implementation, you'd use dart:io Platform.isIOS
    return false;
  }

  static bool _isDesktop() {
    // Desktop platforms: Windows, macOS, Linux
    return false;
  }

  static bool _isMobile() {
    return _isAndroid() || _isIOS();
  }
}

/// Configuration based on detected environment
class EnvironmentConfig {
  final Environment environment;
  final bool isDebugMode;
  final bool enableSampling;
  final bool enableDebugFeatures;
  final bool strictConsent;
  final bool enableVerboseLogging;
  final bool enablePerformanceMonitoring;

  const EnvironmentConfig({
    required this.environment,
    required this.isDebugMode,
    required this.enableSampling,
    required this.enableDebugFeatures,
    required this.strictConsent,
    required this.enableVerboseLogging,
    required this.enablePerformanceMonitoring,
  });

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'environment': environment.name,
      'isDebugMode': isDebugMode,
      'enableSampling': enableSampling,
      'enableDebugFeatures': enableDebugFeatures,
      'strictConsent': strictConsent,
      'enableVerboseLogging': enableVerboseLogging,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
    };
  }

  @override
  String toString() {
    return 'EnvironmentConfig(${environment.name}, debug: $isDebugMode)';
  }
}

/// Platform information
class PlatformInfo {
  final bool isWeb;
  final bool isAndroid;
  final bool isIOS;
  final bool isDesktop;
  final bool isMobile;

  const PlatformInfo({
    required this.isWeb,
    required this.isAndroid,
    required this.isIOS,
    required this.isDesktop,
    required this.isMobile,
  });

  /// Get platform name
  String get platformName {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isDesktop) return 'desktop';
    return 'unknown';
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'isWeb': isWeb,
      'isAndroid': isAndroid,
      'isIOS': isIOS,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'platformName': platformName,
    };
  }

  @override
  String toString() => 'PlatformInfo($platformName)';
}
