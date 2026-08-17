import 'dart:collection';

import '../models/event/base_event.dart';
import '../models/routing/event_category.dart';

/// A routed event waiting for delivery to one or more tracker destinations.
class QueuedEvent {
  QueuedEvent({
    required this.event,
    required Iterable<String> trackerIds,
    this.attempts = 0,
    DateTime? queuedAt,
  })  : trackerIds = List.unmodifiable(LinkedHashSet.of(trackerIds)),
        queuedAt = (queuedAt ?? DateTime.now()).toUtc() {
    if (this.trackerIds.isEmpty) {
      throw ArgumentError.value(trackerIds, 'trackerIds', 'Cannot be empty');
    }
    if (attempts < 0) {
      throw ArgumentError.value(attempts, 'attempts', 'Cannot be negative');
    }
  }

  final BaseEvent event;
  final List<String> trackerIds;
  final int attempts;
  final DateTime queuedAt;

  String get id => event.eventId;

  QueuedEvent copyWith({List<String>? trackerIds, int? attempts}) =>
      QueuedEvent(
        event: event,
        trackerIds: trackerIds ?? this.trackerIds,
        attempts: attempts ?? this.attempts,
        queuedAt: queuedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackerIds': trackerIds,
        'attempts': attempts,
        'queuedAt': queuedAt.toIso8601String(),
        'event': event.toMap(),
      };

  factory QueuedEvent.fromJson(Map<String, dynamic> json) => QueuedEvent(
        event: QueuedEventSnapshot.fromJson(
          (json['event'] as Map).cast<String, dynamic>(),
        ),
        trackerIds: (json['trackerIds'] as List).cast<String>(),
        attempts: json['attempts'] as int,
        queuedAt: DateTime.parse(json['queuedAt'] as String),
      );
}

/// Storage boundary used by the delivery runtime.
abstract interface class EventQueue {
  Future<void> enqueue(QueuedEvent item);
  Future<List<QueuedEvent>> read({required int limit});
  Future<void> replace(QueuedEvent item);
  Future<void> remove(String eventId);
  Future<int> size();
  Future<void> clear();
}

/// FIFO, process-local queue intended for tests and non-durable clients.
class InMemoryEventQueue implements EventQueue {
  final Map<String, QueuedEvent> _items = <String, QueuedEvent>{};

  @override
  Future<void> enqueue(QueuedEvent item) async {
    _items.putIfAbsent(item.id, () => item);
  }

  @override
  Future<List<QueuedEvent>> read({required int limit}) async {
    _checkLimit(limit);
    return List.unmodifiable(_items.values.take(limit));
  }

  @override
  Future<void> replace(QueuedEvent item) async {
    if (_items.containsKey(item.id)) _items[item.id] = item;
  }

  @override
  Future<void> remove(String eventId) async => _items.remove(eventId);

  @override
  Future<int> size() async => _items.length;

  @override
  Future<void> clear() async => _items.clear();
}

/// Immutable event representation used for retry and process restoration.
class QueuedEventSnapshot extends BaseEvent {
  QueuedEventSnapshot({
    required this.eventName,
    required this.eventProperties,
    required this.eventCategory,
    required this.eventContainsPII,
    required this.eventRequiresConsent,
    required this.eventIsHighVolume,
    required this.eventIsEssential,
    required this.eventUserId,
    required this.eventSessionId,
    required super.eventId,
    required super.timestamp,
  });

  factory QueuedEventSnapshot.fromJson(Map<String, dynamic> json) =>
      QueuedEventSnapshot(
        eventName: json['name'] as String,
        eventProperties: (json['properties'] as Map?)?.cast<String, Object>(),
        eventCategory: json['category'] == null
            ? null
            : EventCategory(json['category'] as String),
        eventContainsPII: json['containsPII'] as bool? ?? false,
        eventRequiresConsent: json['requiresConsent'] as bool? ?? true,
        eventIsHighVolume: json['isHighVolume'] as bool? ?? false,
        eventIsEssential: json['isEssential'] as bool? ?? false,
        eventUserId: json['userId'] as String?,
        eventSessionId: json['sessionId'] as String?,
        eventId: json['eventId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  final String eventName;
  final Map<String, Object>? eventProperties;
  final EventCategory? eventCategory;
  final bool eventContainsPII;
  final bool eventRequiresConsent;
  final bool eventIsHighVolume;
  final bool eventIsEssential;
  final String? eventUserId;
  final String? eventSessionId;

  @override
  String get name => eventName;
  @override
  Map<String, Object>? get properties => eventProperties;
  @override
  EventCategory? get category => eventCategory;
  @override
  bool get containsPII => eventContainsPII;
  @override
  bool get requiresConsent => eventRequiresConsent;
  @override
  bool get isHighVolume => eventIsHighVolume;
  @override
  bool get isEssential => eventIsEssential;
  @override
  String? get userId => eventUserId;
  @override
  String? get sessionId => eventSessionId;
}

void _checkLimit(int limit) {
  if (limit <= 0) {
    throw ArgumentError.value(limit, 'limit', 'Must be positive');
  }
}
