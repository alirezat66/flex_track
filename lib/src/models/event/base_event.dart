import 'package:flex_track/src/models/routing/event_category.dart';
import 'package:flex_track/src/models/routing/tracker_group.dart';

abstract class BaseEvent {
  /// Returns the name of the event
  String getName();

  /// Returns the properties associated with the event
  Map<String, Object>? getProperties();

  /// Optional category for automatic routing
  /// Override this in subclasses to enable category-based routing
  EventCategory? get category => null;

  /// Optional tracker group preference
  /// Override this to suggest which tracker group should handle this event
  TrackerGroup? get preferredGroup => null;

  /// Whether this event contains personally identifiable information (PII)
  /// Used for GDPR compliance and routing to appropriate trackers
  bool get containsPII => false;

  /// Whether this event requires user consent before tracking
  /// Set to false for essential events that don't require consent
  bool get requiresConsent => true;

  /// Whether this is a high-volume event that might need sampling
  /// Used for performance optimization
  bool get isHighVolume => false;

  /// Whether this is an essential event that should bypass normal restrictions
  /// Essential events may bypass consent requirements and sampling
  bool get isEssential => false;

  /// Timestamp when the event was created
  /// Defaults to current time, but can be overridden for historical events
  DateTime get timestamp => DateTime.now();

  /// Optional user ID associated with this event
  /// Used for user-specific routing and privacy compliance
  String? get userId => null;

  /// Optional session ID for grouping related events
  String? get sessionId => null;

  /// Converts the event to a map representation
  /// Useful for debugging and serialization
  Map<String, dynamic> toMap() {
    return {
      'name': getName(),
      'properties': getProperties(),
      'category': category?.name,
      'preferredGroup': preferredGroup?.name,
      'containsPII': containsPII,
      'requiresConsent': requiresConsent,
      'isHighVolume': isHighVolume,
      'isEssential': isEssential,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  @override
  String toString() {
    return 'Event(${getName()}${category != null ? ', category: ${category!.name}' : ''})';
  }
}
