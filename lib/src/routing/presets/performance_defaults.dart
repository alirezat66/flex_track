import '../../models/routing/event_category.dart';
import '../routing_builder.dart';

/// Performance-optimized routing defaults to reduce overhead and improve app performance
class PerformanceDefaults {
  /// Apply performance-optimized routing rules
  static void apply(RoutingBuilder builder) {
    // High volume events get aggressive sampling
    builder
        .routeHighVolume()
        .toAll()
        .heavySampling() // 1% sampling
        .withPriority(15)
        .withDescription('High volume events - aggressive sampling')
        .and();

    // UI interaction events are typically high volume
    builder
        .routeMatching(RegExp(r'(click|tap|scroll|swipe|gesture)_.*'))
        .toAll()
        .heavySampling() // 1% sampling for UI events
        .withPriority(12)
        .withDescription('UI interaction events - heavy sampling')
        .and();

    // Mouse and pointer events (very high volume)
    builder
        .routeMatching(RegExp(r'(mouse|pointer|hover)_.*'))
        .toAll()
        .sample(0.001) // 0.1% sampling - extremely aggressive
        .withPriority(14)
        .withDescription('Mouse/pointer events - extreme sampling')
        .and();

    // Scroll events (high frequency)
    builder
        .routeMatching(RegExp(r'scroll_.*'))
        .toAll()
        .sample(0.01) // 1% sampling
        .withPriority(13)
        .withDescription('Scroll events - heavy sampling')
        .and();

    // Heartbeat/ping events
    builder
        .routeMatching(RegExp(r'(heartbeat|ping|alive)_.*'))
        .toAll()
        .sample(0.05) // 5% sampling
        .withPriority(11)
        .withDescription('Heartbeat events - moderate sampling')
        .and();

    // Performance monitoring events
    builder
        .routeCategory(EventCategory.technical)
        .toDevelopment()
        .onlyInDebug()
        .lightSampling() // 10% sampling in debug
        .withPriority(8)
        .withDescription('Performance events - debug only')
        .and();

    // Network/API call events (can be high volume)
    builder
        .routeMatching(RegExp(r'(api|network|http|request)_.*'))
        .toAll()
        .lightSampling() // 10% sampling
        .withPriority(9)
        .withDescription('Network events - light sampling')
        .and();

    // Timer/interval events
    builder
        .routeMatching(RegExp(r'(timer|interval|periodic)_.*'))
        .toAll()
        .sample(0.02) // 2% sampling
        .withPriority(10)
        .withDescription('Timer events - heavy sampling')
        .and();

    // Animation frame events (extremely high volume)
    builder
        .routeMatching(RegExp(r'(frame|animation|render)_.*'))
        .toAll()
        .sample(0.0001) // 0.01% sampling
        .withPriority(16)
        .withDescription('Animation events - minimal sampling')
        .and();

    // Critical business events - no sampling
    builder
        .routeMatching(RegExp(r'(purchase|payment|transaction|error)_.*'))
        .toAll()
        .noSampling()
        .withPriority(20)
        .withDescription('Critical events - no sampling')
        .and();

    // Essential events - no sampling
    builder
        .routeEssential()
        .toAll()
        .noSampling()
        .withPriority(25)
        .withDescription('Essential events - no sampling')
        .and();

    // Security events - no sampling
    builder
        .routeCategory(EventCategory.security)
        .toAll()
        .noSampling()
        .withPriority(22)
        .withDescription('Security events - no sampling')
        .and();

    // Default sampling for everything else
    builder
        .routeDefault()
        .toAll()
        .mediumSampling() // 50% sampling
        .withPriority(0)
        .withDescription('Default performance-optimized routing')
        .and();
  }

  /// Apply mobile-optimized performance settings (more aggressive)
  static void applyMobileOptimized(RoutingBuilder builder) {
    // Mobile devices need more aggressive optimization

    // Even more aggressive sampling for high-volume events
    builder
        .routeHighVolume()
        .toAll()
        .sample(0.005) // 0.5% sampling
        .withPriority(15)
        .withDescription('Mobile: Ultra-aggressive sampling for high volume')
        .and();

    // UI events - mobile apps generate lots of these
    builder
        .routeMatching(RegExp(r'(touch|swipe|pinch|rotate|shake)_.*'))
        .toAll()
        .sample(0.01) // 1% sampling
        .withPriority(12)
        .withDescription('Mobile: Touch events with heavy sampling')
        .and();

    // Location events (battery intensive)
    builder
        .routeWithProperty('location')
        .toAll()
        .sample(0.1) // 10% sampling
        .withPriority(13)
        .withDescription('Mobile: Location events - battery conscious')
        .and();

    // Apply base performance defaults
    apply(builder);
  }

  /// Apply web-optimized performance settings
  static void applyWebOptimized(RoutingBuilder builder) {
    // Web-specific optimizations

    // Page view events are important but can be frequent with SPAs
    builder
        .routeMatching(RegExp(r'(page_view|route_change|navigation)_.*'))
        .toAll()
        .lightSampling() // 10% sampling
        .withPriority(14)
        .withDescription('Web: Navigation events with light sampling')
        .and();

    // DOM interaction events
    builder
        .routeMatching(RegExp(r'(focus|blur|resize|load)_.*'))
        .toAll()
        .sample(0.05) // 5% sampling
        .withPriority(11)
        .withDescription('Web: DOM events with moderate sampling')
        .and();

    // Apply base performance defaults
    apply(builder);
  }

  /// Apply server/backend optimized settings
  static void applyServerOptimized(RoutingBuilder builder) {
    // Server environments can handle more events but need to be mindful of storage

    // Request/response events - important for monitoring but high volume
    builder
        .routeMatching(RegExp(r'(request|response|endpoint)_.*'))
        .toAll()
        .mediumSampling() // 50% sampling
        .withPriority(12)
        .withDescription('Server: HTTP events with medium sampling')
        .and();

    // Database query events
    builder
        .routeMatching(RegExp(r'(query|database|sql)_.*'))
        .toAll()
        .lightSampling() // 10% sampling
        .withPriority(11)
        .withDescription('Server: Database events with light sampling')
        .and();

    // Cache events (very high volume)
    builder
        .routeMatching(RegExp(r'(cache|redis|memcached)_.*'))
        .toAll()
        .sample(0.01) // 1% sampling
        .withPriority(10)
        .withDescription('Server: Cache events with heavy sampling')
        .and();

    // Apply base performance defaults
    apply(builder);
  }

  /// Apply low-latency optimized settings (minimal processing overhead)
  static void applyLowLatency(RoutingBuilder builder) {
    // Minimize routing complexity for low-latency requirements

    // Only essential events get tracked
    builder
        .routeEssential()
        .toAll()
        .noSampling()
        .withPriority(20)
        .withDescription('Low-latency: Essential events only')
        .and();

    // Critical business events
    builder
        .routeMatching(RegExp(r'(error|failure|critical)_.*'))
        .toAll()
        .noSampling()
        .withPriority(18)
        .withDescription('Low-latency: Critical events only')
        .and();

    // Everything else gets aggressive sampling
    builder
        .routeDefault()
        .toAll()
        .sample(0.01) // 1% sampling
        .withPriority(0)
        .withDescription('Low-latency: Minimal default tracking')
        .and();
  }

  /// Apply bandwidth-conscious settings (for limited network environments)
  static void applyBandwidthConscious(RoutingBuilder builder) {
    // Optimize for minimal network usage

    // Only send essential events over the network
    builder
        .routeEssential()
        .toAll()
        .noSampling()
        .withPriority(20)
        .withDescription('Bandwidth: Essential events only')
        .and();

    // Business-critical events
    builder
        .routeMatching(RegExp(r'(purchase|payment|signup|login)_.*'))
        .toAll()
        .noSampling()
        .withPriority(18)
        .withDescription('Bandwidth: Business-critical events')
        .and();

    // Errors need to be tracked
    builder
        .routeMatching(RegExp(r'(error|crash|exception)_.*'))
        .toAll()
        .lightSampling() // Some sampling to reduce volume
        .withPriority(15)
        .withDescription('Bandwidth: Error events with sampling')
        .and();

    // Everything else gets minimal tracking
    builder
        .routeDefault()
        .toAll()
        .sample(0.001) // 0.1% sampling
        .withPriority(0)
        .withDescription('Bandwidth: Minimal default tracking')
        .and();
  }

  /// Apply settings optimized for high-throughput systems
  static void applyHighThroughput(RoutingBuilder builder) {
    // Systems that process millions of events need aggressive optimization

    // Use batch-friendly routing and heavy sampling
    builder
        .routeHighVolume()
        .toAll()
        .sample(0.0001) // 0.01% sampling
        .withPriority(15)
        .withDescription('High-throughput: Ultra-minimal sampling')
        .and();

    // Only the most critical events
    builder
        .routeEssential()
        .toAll()
        .sample(0.1) // Even essential events get some sampling
        .withPriority(20)
        .withDescription('High-throughput: Sampled essential events')
        .and();

    // Errors need tracking but with sampling
    builder
        .routeMatching(RegExp(r'error_.*'))
        .toAll()
        .sample(0.01) // 1% error sampling
        .withPriority(18)
        .withDescription('High-throughput: Sampled error tracking')
        .and();

    // Minimal default tracking
    builder
        .routeDefault()
        .toAll()
        .sample(0.00001) // 0.001% sampling
        .withPriority(0)
        .withDescription('High-throughput: Extremely minimal default')
        .and();
  }
}
