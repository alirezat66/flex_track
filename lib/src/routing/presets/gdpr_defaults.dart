import '../../models/routing/event_category.dart';
import '../routing_builder.dart';

/// Smart default routing configurations for common use cases
class SmartDefaults {
  /// Apply smart defaults to a routing builder
  static void apply(RoutingBuilder builder) {
    // Technical/debug events go to development trackers in debug mode only
    builder
        .routeCategory(EventCategory.technical)
        .toDevelopment()
        .onlyInDebug()
        .lightSampling()
        .withPriority(8)
        .withDescription('Technical events in debug mode')
        .and();

    // System events are essential and bypass consent
    builder
        .routeCategory(EventCategory.system)
        .toAll()
        .essential()
        .withPriority(15)
        .withDescription('Essential system events')
        .and();

    // Security events are high priority and essential
    builder
        .routeCategory(EventCategory.security)
        .toAll()
        .essential()
        .highPriority()
        .withDescription('Security events')
        .and();

    // High volume events get heavy sampling to avoid overwhelming trackers
    builder
        .routeHighVolume()
        .toAll()
        .heavySampling()
        .withPriority(5)
        .withDescription('High volume events with heavy sampling')
        .and();

    // Sensitive/PII events need special handling
    builder
        .routeCategory(EventCategory.sensitive)
        .toAll()
        .requirePIIConsent()
        .withPriority(12)
        .withDescription('Sensitive data events')
        .and();

    // Debug events (by name pattern) only in debug
    builder
        .routeMatching(RegExp(r'^debug[_-]'))
        .toDevelopment()
        .onlyInDebug()
        .noSampling()
        .skipConsent()
        .withPriority(10)
        .withDescription('Debug events by name pattern')
        .and();

    // Error events are important and should always be tracked
    builder
        .routeMatching(RegExp(r'(error|exception|crash|failure)'))
        .toAll()
        .essential()
        .withPriority(14)
        .withDescription('Error and exception events')
        .and();

    // Test events only in non-production
    builder
        .routeMatching(RegExp(r'^test[_-]'))
        .toDevelopment()
        .onlyInDebug()
        .skipConsent()
        .withPriority(6)
        .withDescription('Test events')
        .and();

    // Default rule: everything else goes to all trackers
    builder
        .routeDefault()
        .toAll()
        .withPriority(0)
        .withDescription('Default routing - all events to all trackers')
        .and();
  }

  /// Apply minimal smart defaults (less opinionated)
  static void applyMinimal(RoutingBuilder builder) {
    // Only essential rules

    // Debug events to development trackers
    builder
        .routeMatching(RegExp(r'^debug[_-]'))
        .toDevelopment()
        .onlyInDebug()
        .and();

    // High volume events get sampled
    builder.routeHighVolume().toAll().lightSampling().and();

    // Default: everything to all trackers
    builder.routeDefault().toAll().and();
  }

  /// Apply performance-focused defaults
  static void applyPerformanceFocused(RoutingBuilder builder) {
    // Aggressive sampling for high-volume events
    builder
        .routeHighVolume()
        .toAll()
        .sample(0.01) // 1% sampling
        .withDescription('Aggressive sampling for high-volume events')
        .and();

    // Sample user interaction events
    builder
        .routeMatching(RegExp(r'(click|tap|scroll|swipe|view)'))
        .toAll()
        .sample(0.05) // 5% sampling
        .withDescription('Sampled user interaction events')
        .and();

    // Heartbeat/ping events get minimal tracking
    builder
        .routeMatching(RegExp(r'(heartbeat|ping|alive|health)'))
        .toAll()
        .sample(0.001) // 0.1% sampling
        .withDescription('Minimal heartbeat tracking')
        .and();

    // Essential events always tracked
    builder.routeEssential().toAll().noSampling().highPriority().and();

    // Everything else gets moderate sampling
    builder
        .routeDefault()
        .toAll()
        .sample(0.1) // 10% sampling
        .and();
  }

  /// Apply privacy-focused defaults
  static void applyPrivacyFocused(RoutingBuilder builder) {
    // Sensitive data requires PII consent
    builder
        .routeCategory(EventCategory.sensitive)
        .toAll()
        .requirePIIConsent()
        .highPriority()
        .and();

    // Marketing events require marketing consent
    builder
        .routeCategory(EventCategory.marketing)
        .toAll()
        .requireConsent()
        .and();

    // User behavior events require analytics consent
    builder.routeCategory(EventCategory.user).toAll().requireConsent().and();

    // System events don't require consent (essential functionality)
    builder
        .routeCategory(EventCategory.system)
        .toAll()
        .skipConsent()
        .essential()
        .and();

    // Debug events don't require consent but only in debug mode
    builder
        .routeCategory(EventCategory.technical)
        .toDevelopment()
        .onlyInDebug()
        .skipConsent()
        .and();

    // Default requires consent
    builder.routeDefault().toAll().requireConsent().and();
  }

  /// Apply development-friendly defaults
  static void applyDevelopmentFriendly(RoutingBuilder builder) {
    // All debug events to console with detailed logging
    builder
        .routeMatching(RegExp(r'(debug|test|dev|trace)'))
        .toDevelopment()
        .noSampling()
        .skipConsent()
        .highPriority()
        .withDescription('Development and debug events')
        .and();

    // Technical events visible in debug
    builder
        .routeCategory(EventCategory.technical)
        .toDevelopment()
        .onlyInDebug()
        .noSampling()
        .and();

    // Errors and exceptions always tracked
    builder
        .routeMatching(RegExp(r'(error|exception|warning|fail)'))
        .toAll()
        .noSampling()
        .essential()
        .and();

    // Everything else with light sampling to avoid noise
    builder.routeDefault().toAll().lightSampling().and();
  }

  /// Get a list of all available presets
  static List<PresetInfo> getAvailablePresets() {
    return [
      PresetInfo(
        name: 'Smart Defaults',
        description: 'Comprehensive routing with common patterns',
        apply: SmartDefaults.apply,
      ),
      PresetInfo(
        name: 'Minimal',
        description: 'Basic routing with minimal rules',
        apply: SmartDefaults.applyMinimal,
      ),
      PresetInfo(
        name: 'Performance Focused',
        description: 'Aggressive sampling to optimize performance',
        apply: SmartDefaults.applyPerformanceFocused,
      ),
      PresetInfo(
        name: 'Privacy Focused',
        description: 'Strict consent requirements for GDPR compliance',
        apply: SmartDefaults.applyPrivacyFocused,
      ),
      PresetInfo(
        name: 'Development Friendly',
        description: 'Optimized for development and debugging',
        apply: SmartDefaults.applyDevelopmentFriendly,
      ),
    ];
  }
}

/// Information about a routing preset
class PresetInfo {
  final String name;
  final String description;
  final void Function(RoutingBuilder) apply;

  const PresetInfo({
    required this.name,
    required this.description,
    required this.apply,
  });

  @override
  String toString() => 'PresetInfo($name: $description)';
}
