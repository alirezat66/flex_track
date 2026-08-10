import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/routing/event_category.dart';
import 'package:flex_track/src/models/routing/tracker_group.dart';

/// A [BaseEvent] wrapper that merges extra properties onto an existing event
/// without requiring mutation of the original.
///
/// All metadata getters are forwarded to [original]. [getProperties] returns
/// original properties merged with [extraProperties]; extra properties take
/// precedence on key collision.
///
/// Transformers produce [EnrichedEvent]s — user-defined events never need
/// to be modified.
///
/// Example:
/// ```dart
/// FlexTrack.addTransformer((event) => EnrichedEvent(event, {
///   'current_route': '/home',
///   'app_version': '1.2.3',
/// }));
/// ```
class EnrichedEvent extends BaseEvent {
  final BaseEvent _original;
  final Map<String, Object> _extraProperties;

  EnrichedEvent(BaseEvent original, Map<String, Object> extraProperties)
      : _original = original,
        _extraProperties = Map.unmodifiable(extraProperties);

  /// The original unwrapped event.
  BaseEvent get original => _original;

  /// The extra properties added by the transformer.
  Map<String, Object> get extraProperties => _extraProperties;

  @override
  String getName() => _original.getName();

  @override
  Map<String, Object> getProperties() => {
        ...?_original.getProperties(),
        ..._extraProperties,
      };

  @override
  EventCategory? get category => _original.category;

  @override
  TrackerGroup? get preferredGroup => _original.preferredGroup;

  @override
  bool get containsPII => _original.containsPII;

  @override
  bool get requiresConsent => _original.requiresConsent;

  @override
  bool get isHighVolume => _original.isHighVolume;

  @override
  bool get isEssential => _original.isEssential;

  @override
  DateTime get timestamp => _original.timestamp;

  @override
  String? get userId => _original.userId;

  @override
  String? get sessionId => _original.sessionId;
}
