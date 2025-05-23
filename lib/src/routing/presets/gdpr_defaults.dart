import '../../models/routing/event_category.dart';
import '../routing_builder.dart';

/// GDPR-compliant routing defaults for privacy compliance
class GDPRDefaults {
  /// Apply GDPR-compliant routing rules
  static void apply(RoutingBuilder builder, {List<String>? compliantTrackers}) {
    // Define GDPR compliant tracker group if trackers are specified
    if (compliantTrackers != null && compliantTrackers.isNotEmpty) {
      builder.defineGroup(
        'gdpr_compliant',
        compliantTrackers,
        description: 'GDPR and privacy compliant trackers',
      );
    }

    // Sensitive data events - strictest controls
    builder
        .routeCategory(EventCategory.sensitive)
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .requireConsent()
        .noSampling() // Don't sample sensitive data
        .withPriority(20)
        .withDescription('Sensitive data - GDPR compliant trackers only')
        .and();

    // All PII events require explicit PII consent
    builder
        .routePII()
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .noSampling() // Ensure all PII events are captured for compliance
        .withPriority(18)
        .withDescription('PII events requiring explicit consent')
        .and();

    // User behavior events require general consent
    builder
        .routeCategory(EventCategory.user)
        .toAll()
        .requireConsent()
        .mediumSampling() // Some sampling allowed for behavioral data
        .withPriority(12)
        .withDescription('User behavior events requiring consent')
        .and();

    // Marketing events require both general and marketing consent
    builder
        .routeCategory(EventCategory.marketing)
        .toAll()
        .requireConsent()
        .requirePIIConsent() // Marketing often involves PII
        .lightSampling()
        .withPriority(15)
        .withDescription('Marketing events requiring full consent')
        .and();

    // Events with email, phone, or other PII properties
    builder
        .routeWithProperty('email')
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .noSampling()
        .withPriority(19)
        .withDescription('Events with email - PII consent required')
        .and();

    builder
        .routeWithProperty('phone')
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .noSampling()
        .withPriority(19)
        .withDescription('Events with phone - PII consent required')
        .and();

    builder
        .routeWithProperty('ip_address')
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .noSampling()
        .withPriority(19)
        .withDescription('Events with IP address - PII consent required')
        .and();

    // Location data requires special handling
    builder
        .routeWithProperty('location')
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .noSampling()
        .withPriority(17)
        .withDescription('Location data - strict PII consent required')
        .and();

    builder
        .routeWithProperty('latitude')
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .noSampling()
        .withPriority(17)
        .withDescription('GPS coordinates - strict PII consent required')
        .and();

    // Essential system events that don't require consent (legal basis: legitimate interest)
    builder
        .routeCategory(EventCategory.security)
        .toAll()
        .skipConsent()
        .noSampling()
        .withPriority(25)
        .withDescription('Security events - legitimate interest basis')
        .and();

    builder
        .routeEssential()
        .toAll()
        .skipConsent()
        .noSampling()
        .withPriority(24)
        .withDescription('Essential events - legitimate interest basis')
        .and();

    // System health events (non-personal)
    builder
        .routeCategory(EventCategory.system)
        .toAll()
        .skipConsent()
        .lightSampling()
        .withPriority(8)
        .withDescription('System events - no personal data')
        .and();

    // Technical/performance events (anonymous)
    builder
        .routeCategory(EventCategory.technical)
        .toDevelopment()
        .skipConsent()
        .lightSampling()
        .onlyInDebug()
        .withPriority(6)
        .withDescription('Technical events - anonymous debug data')
        .and();

    // Default rule - requires general consent for everything else
    builder
        .routeDefault()
        .toAll()
        .requireConsent()
        .mediumSampling()
        .withPriority(0)
        .withDescription('Default GDPR-compliant routing')
        .and();
  }

  /// Apply strict GDPR compliance (maximum privacy protection)
  static void applyStrict(RoutingBuilder builder,
      {List<String>? compliantTrackers}) {
    // Apply base GDPR defaults
    apply(builder, compliantTrackers: compliantTrackers);

    // Override with stricter rules

    // ALL events with any user data require PII consent
    builder
        .routeWithProperty('user_id')
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .noSampling()
        .withPriority(22)
        .withDescription('User ID events - strict PII consent')
        .and();

    builder
        .routeWithProperty('session_id')
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requireConsent()
        .lightSampling() // Session IDs are less sensitive than PII
        .withPriority(13)
        .withDescription('Session tracking - consent required')
        .and();

    // Any behavioral tracking requires consent
    builder
        .routeMatching(RegExp(r'(click|view|scroll|interaction)_.*'))
        .toAll()
        .requireConsent()
        .mediumSampling()
        .withPriority(14)
        .withDescription('Behavioral events - consent required')
        .and();
  }

  /// Apply minimal GDPR compliance (relaxed but still compliant)
  static void applyMinimal(RoutingBuilder builder,
      {List<String>? compliantTrackers}) {
    // Define GDPR compliant tracker group if trackers are specified
    if (compliantTrackers != null && compliantTrackers.isNotEmpty) {
      builder.defineGroup(
        'gdpr_compliant',
        compliantTrackers,
        description: 'GDPR and privacy compliant trackers',
      );
    }

    // Only the most sensitive data requires special handling

    // PII events go to compliant trackers
    builder
        .routePII()
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .withPriority(16)
        .withDescription('PII events - minimal GDPR compliance')
        .and();

    // Sensitive category events
    builder
        .routeCategory(EventCategory.sensitive)
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requirePIIConsent()
        .withPriority(15)
        .withDescription('Sensitive events - minimal GDPR compliance')
        .and();

    // Essential events don't require consent
    builder
        .routeEssential()
        .toAll()
        .skipConsent()
        .withPriority(20)
        .withDescription('Essential events - legitimate interest')
        .and();

    // Security events don't require consent
    builder
        .routeCategory(EventCategory.security)
        .toAll()
        .skipConsent()
        .withPriority(18)
        .withDescription('Security events - legitimate interest')
        .and();

    // Everything else gets standard treatment
    builder
        .routeDefault()
        .toAll()
        .withPriority(0)
        .withDescription('Default minimal GDPR routing')
        .and();
  }

  /// Apply GDPR defaults for specific regions
  static void applyForRegion(RoutingBuilder builder, GDPRRegion region,
      {List<String>? compliantTrackers}) {
    switch (region) {
      case GDPRRegion.eu:
        applyStrict(builder, compliantTrackers: compliantTrackers);
        break;
      case GDPRRegion.uk:
        apply(builder, compliantTrackers: compliantTrackers);
        break;
      case GDPRRegion.california:
        applyCCPA(builder, compliantTrackers: compliantTrackers);
        break;
      case GDPRRegion.global:
        applyMinimal(builder, compliantTrackers: compliantTrackers);
        break;
    }
  }

  /// Apply CCPA (California Consumer Privacy Act) defaults
  static void applyCCPA(RoutingBuilder builder,
      {List<String>? compliantTrackers}) {
    // Define GDPR compliant tracker group if trackers are specified
    if (compliantTrackers != null && compliantTrackers.isNotEmpty) {
      builder.defineGroup(
        'gdpr_compliant',
        compliantTrackers,
        description: 'GDPR and privacy compliant trackers',
      );
    }
    // CCPA is less strict than GDPR but still requires consent for personal info

    builder
        .routePII()
        .toGroupNamed(
            (compliantTrackers != null && compliantTrackers.isNotEmpty)
                ? 'gdpr_compliant'
                : 'all')
        .requireConsent() // CCPA requires opt-out rather than opt-in
        .withPriority(15)
        .withDescription('PII events - CCPA compliance')
        .and();

    builder
        .routeCategory(EventCategory.marketing)
        .toAll()
        .requireConsent()
        .withPriority(12)
        .withDescription('Marketing events - CCPA compliance')
        .and();

    // Less strict than GDPR for other categories
    builder
        .routeDefault()
        .toAll()
        .withPriority(0)
        .withDescription('Default CCPA-compliant routing')
        .and();
  }
}

/// GDPR regions with different compliance requirements
enum GDPRRegion {
  /// European Union - strictest GDPR compliance
  eu,

  /// United Kingdom - GDPR-equivalent (UK GDPR)
  uk,

  /// California - CCPA compliance
  california,

  /// Global - minimal but compliant defaults
  global,
}
