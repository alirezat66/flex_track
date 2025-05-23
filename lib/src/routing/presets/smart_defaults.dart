import '../../models/routing/event_category.dart';
import '../routing_builder.dart';

/// Smart defaults for common analytics routing scenarios
class SmartDefaults {
  /// Apply smart default routing rules to a routing builder
  static void apply(RoutingBuilder builder) {
    // Technical/debug events go to development trackers in debug mode only
    builder
        .routeCategory(EventCategory.technical)
        .toDevelopment()
        .onlyInDebug()
        .lightSampling()
        .withPriority(8)
        .withDescription('Technical events for debugging')
        .and();

    // High volume events get heavy sampling to reduce load
    builder
        .routeHighVolume()
        .toAll()
        .heavySampling()
        .withPriority(5)
        .withDescription('High volume events with reduced sampling')
        .and();

    // Security events are essential - no consent required, no sampling
    builder
        .routeCategory(EventCategory.security)
        .toAll()
        .essential()
        .withPriority(15)
        .withDescription('Security events - always tracked')
        .and();

    // System events don't require consent but get light sampling
    builder
        .routeCategory(EventCategory.system)
        .toAll()
        .skipConsent()
        .lightSampling()
        .withPriority(7)
        .withDescription('System events - no consent required')
        .and();

    // Sensitive events require consent and go to all trackers
    builder
        .routeCategory(EventCategory.sensitive)
        .toAll()
        .requireConsent()
        .requirePIIConsent()
        .withPriority(12)
        .withDescription('Sensitive events requiring full consent')
        .and();

    // Events with PII flag always require PII consent
    builder
        .routePII()
        .toAll()
        .requirePIIConsent()
        .withPriority(10)
        .withDescription('PII events requiring specific consent')
        .and();

    // Essential events bypass all restrictions
    builder
        .routeEssential()
        .toAll()
        .essential()
        .withPriority(20)
        .withDescription('Essential events - bypass all restrictions')
        .and();

    // Default fallback - everything else goes everywhere with standard settings
    builder
        .routeDefault()
        .toAll()
        .withPriority(0)
        .withDescription('Default routing for unmatched events')
        .and();
  }

  /// Apply performance-focused smart defaults
  static void applyPerformanceFocused(RoutingBuilder builder) {
    // Apply base smart defaults first
    apply(builder);

    // Add additional performance optimizations
    builder
        .routeWithProperty('high_frequency')
        .toAll()
        .heavySampling()
        .withPriority(6)
        .withDescription('High frequency events with heavy sampling')
        .and();

    // Batch-friendly events
    builder
        .routeWithProperty('batchable')
        .toAll()
        .mediumSampling()
        .withPriority(4)
        .withDescription('Batchable events with medium sampling')
        .and();
  }

  /// Apply privacy-focused smart defaults
  static void applyPrivacyFocused(RoutingBuilder builder) {
    // User events require general consent
    builder
        .routeCategory(EventCategory.user)
        .toAll()
        .requireConsent()
        .withPriority(9)
        .withDescription('User events requiring consent')
        .and();

    // Marketing events require specific consent
    builder
        .routeCategory(EventCategory.marketing)
        .toAll()
        .requireConsent()
        .withPriority(11)
        .withDescription('Marketing events requiring consent')
        .and();

    // Apply base smart defaults
    apply(builder);
  }

  /// Apply development-friendly defaults
  static void applyDevelopmentFriendly(RoutingBuilder builder) {
    // All debug events go to development trackers
    builder
        .routeMatching(RegExp(r'debug_.*'))
        .toDevelopment()
        .onlyInDebug()
        .noSampling()
        .withPriority(15)
        .withDescription('Debug events for development')
        .and();

    // Test events only in non-production
    builder
        .routeMatching(RegExp(r'test_.*'))
        .toDevelopment()
        .onlyInDebug()
        .noSampling()
        .withPriority(14)
        .withDescription('Test events for development')
        .and();

    // Development events
    builder
        .routeMatching(RegExp(r'dev_.*'))
        .toDevelopment()
        .onlyInDebug()
        .noSampling()
        .withPriority(13)
        .withDescription('Development-specific events')
        .and();

    // Apply base smart defaults
    apply(builder);
  }
}
