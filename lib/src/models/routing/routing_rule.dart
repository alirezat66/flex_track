import 'package:flex_track/src/models/event/base_event.dart';

import 'event_category.dart';
import 'tracker_group.dart';

/// Represents a routing rule that determines where events should be sent
class RoutingRule {
  final String? id;
  final Type? eventType;
  final String? eventNamePattern;
  final RegExp? eventNameRegex;
  final EventCategory? category;
  final String? hasProperty;
  final dynamic propertyValue;
  final bool? containsPII;
  final bool? isHighVolume;
  final bool? isEssential;
  final bool isDefault;
  final TrackerGroup targetGroup;
  final double sampleRate;
  final bool requireConsent;
  final bool debugOnly;
  final bool productionOnly;
  final bool requirePIIConsent;
  final int priority;
  final String? description;

  const RoutingRule({
    this.id,
    this.eventType,
    this.eventNamePattern,
    this.eventNameRegex,
    this.category,
    this.hasProperty,
    this.propertyValue,
    this.containsPII,
    this.isHighVolume,
    this.isEssential,
    this.isDefault = false,
    required this.targetGroup,
    this.sampleRate = 1.0,
    this.requireConsent = true,
    this.debugOnly = false,
    this.productionOnly = false,
    this.requirePIIConsent = false,
    this.priority = 0,
    this.description,
  }) : assert(sampleRate >= 0.0 && sampleRate <= 1.0,
            'Sample rate must be between 0.0 and 1.0');

  /// Check if this rule matches the given event
  bool matches(BaseEvent event, {bool isDebugMode = false}) {
    // Check environment restrictions first
    if (debugOnly && !isDebugMode) return false;
    if (productionOnly && isDebugMode) return false;

    // Check event type
    if (eventType != null && event.runtimeType != eventType) {
      return false;
    }

    // Check event name pattern (contains check)
    if (eventNamePattern != null && !event.name.contains(eventNamePattern!)) {
      return false;
    }

    // Check regex pattern
    if (eventNameRegex != null && !eventNameRegex!.hasMatch(event.name)) {
      return false;
    }

    // Check category
    if (category != null && event.category != category) {
      return false;
    }

    // Check property existence and value
    if (hasProperty != null) {
      final props = event.properties;
      if (props == null || !props.containsKey(hasProperty)) {
        return false;
      }

      // Check property value if specified
      if (propertyValue != null && props[hasProperty] != propertyValue) {
        return false;
      }
    }

    // Check PII flag
    if (containsPII != null && event.containsPII != containsPII) {
      return false;
    }

    // Check high volume flag
    if (isHighVolume != null && event.isHighVolume != isHighVolume) {
      return false;
    }

    // Check essential flag
    if (isEssential != null && event.isEssential != isEssential) {
      return false;
    }

    return true;
  }

  /// Returns true if this rule should be applied based on consent
  bool shouldApply(
    BaseEvent event, {
    bool hasGeneralConsent = false,
    bool hasPIIConsent = false,
  }) {
    // Essential events bypass consent requirements
    if (event.isEssential) return true;

    // Check general consent requirement
    if (requireConsent && !hasGeneralConsent) return false;

    // Check PII consent requirement
    if (requirePIIConsent && !hasPIIConsent) return false;

    // Check if event requires consent but we don't have it
    if (event.requiresConsent && !hasGeneralConsent) return false;

    return true;
  }

  /// Returns true if this rule should be sampled for the given event
  bool shouldSample() {
    if (sampleRate >= 1.0) return true;
    if (sampleRate <= 0.0) return false;

    // Use a simple random sampling
    return (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0 < sampleRate;
  }

  /// Creates a copy of this rule with updated properties
  RoutingRule copyWith({
    String? id,
    Type? eventType,
    String? eventNamePattern,
    RegExp? eventNameRegex,
    EventCategory? category,
    String? hasProperty,
    dynamic propertyValue,
    bool? containsPII,
    bool? isHighVolume,
    bool? isEssential,
    bool? isDefault,
    TrackerGroup? targetGroup,
    double? sampleRate,
    bool? requireConsent,
    bool? debugOnly,
    bool? productionOnly,
    bool? requirePIIConsent,
    int? priority,
    String? description,
  }) {
    return RoutingRule(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      eventNamePattern: eventNamePattern ?? this.eventNamePattern,
      eventNameRegex: eventNameRegex ?? this.eventNameRegex,
      category: category ?? this.category,
      hasProperty: hasProperty ?? this.hasProperty,
      propertyValue: propertyValue ?? this.propertyValue,
      containsPII: containsPII ?? this.containsPII,
      isHighVolume: isHighVolume ?? this.isHighVolume,
      isEssential: isEssential ?? this.isEssential,
      isDefault: isDefault ?? this.isDefault,
      targetGroup: targetGroup ?? this.targetGroup,
      sampleRate: sampleRate ?? this.sampleRate,
      requireConsent: requireConsent ?? this.requireConsent,
      debugOnly: debugOnly ?? this.debugOnly,
      productionOnly: productionOnly ?? this.productionOnly,
      requirePIIConsent: requirePIIConsent ?? this.requirePIIConsent,
      priority: priority ?? this.priority,
      description: description ?? this.description,
    );
  }

  /// Converts to a map for serialization/debugging
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventType': eventType?.toString(),
      'eventNamePattern': eventNamePattern,
      'eventNameRegex': eventNameRegex?.pattern,
      'category': category?.name,
      'hasProperty': hasProperty,
      'propertyValue': propertyValue,
      'containsPII': containsPII,
      'isHighVolume': isHighVolume,
      'isEssential': isEssential,
      'isDefault': isDefault,
      'targetGroup': targetGroup.toMap(),
      'sampleRate': sampleRate,
      'requireConsent': requireConsent,
      'debugOnly': debugOnly,
      'productionOnly': productionOnly,
      'requirePIIConsent': requirePIIConsent,
      'priority': priority,
      'description': description,
    };
  }

  @override
  String toString() {
    final conditions = <String>[];

    if (eventType != null) conditions.add('type: $eventType');
    if (eventNamePattern != null) conditions.add('pattern: $eventNamePattern');
    if (eventNameRegex != null) {
      conditions.add('regex: ${eventNameRegex!.pattern}');
    }
    if (category != null) conditions.add('category: ${category!.name}');
    if (isDefault) conditions.add('default');

    return 'RoutingRule(${conditions.join(', ')} → ${targetGroup.name})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutingRule &&
          other.id == id &&
          other.eventType == eventType &&
          other.eventNamePattern == eventNamePattern &&
          other.eventNameRegex?.pattern == eventNameRegex?.pattern &&
          other.category == category &&
          other.targetGroup == targetGroup;

  @override
  int get hashCode => Object.hash(
        id,
        eventType,
        eventNamePattern,
        eventNameRegex?.pattern,
        category,
        targetGroup,
      );
}
