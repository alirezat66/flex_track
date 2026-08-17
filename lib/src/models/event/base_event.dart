import 'dart:math';

import 'package:flex_track/src/models/routing/event_category.dart';
import 'package:flex_track/src/models/routing/tracker_group.dart';

abstract class BaseEvent {
  BaseEvent({String? eventId, DateTime? timestamp})
      : eventId = _resolveEventId(eventId),
        timestamp = timestamp ?? DateTime.now().toUtc();

  /// Stable identifier for this event occurrence.
  ///
  /// Supply an existing id when reconstructing an event for retry or replay.
  /// Otherwise FlexTrack generates an RFC 4122 version 4 UUID.
  final String eventId;

  /// Immutable time at which this event occurrence was created.
  ///
  /// Supply the original value when reconstructing historical events.
  final DateTime timestamp;

  /// Returns the name of the event.
  String get name;

  /// Returns the properties associated with the event.
  Map<String, Object>? get properties;

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

  /// Optional user ID associated with this event
  /// Used for user-specific routing and privacy compliance
  String? get userId => null;

  /// Optional session ID for grouping related events
  String? get sessionId => null;

  /// Converts the event to a map representation
  /// Useful for debugging and serialization
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'properties': properties,
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
    return 'Event($name${category != null ? ', category: ${category!.name}' : ''})';
  }
}

final Random _eventIdRandom = Random.secure();

String _resolveEventId(String? eventId) {
  if (eventId != null) {
    if (eventId.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'Cannot be empty');
    }
    return eventId;
  }

  final bytes = List<int>.generate(16, (_) => _eventIdRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
  final value = hex.join();

  return '${value.substring(0, 8)}-'
      '${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-'
      '${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
