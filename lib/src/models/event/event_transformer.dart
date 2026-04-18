import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/event/enriched_event.dart';

export 'enriched_event.dart';

/// A function that takes a [BaseEvent] and returns a (potentially enriched)
/// [BaseEvent]. The returned event replaces the original for all downstream
/// routing and tracker dispatch.
///
/// Transformers are applied in registration order. Each transformer receives
/// the output of the previous one, enabling chaining.
///
/// Use [EnrichedEvent] to attach extra properties without modifying the
/// original event class:
/// ```dart
/// FlexTrack.addTransformer((event) => EnrichedEvent(event, {
///   'current_route': myRouteObserver.currentRoute,
/// }));
/// ```
typedef EventTransformer = BaseEvent Function(BaseEvent event);

/// Returns an [EventTransformer] that applies [transformer] only when
/// [condition] returns `true` for the incoming event. Otherwise the event
/// is passed through unchanged.
///
/// Example — only enrich UI events with the current route:
/// ```dart
/// FlexTrack.addTransformer(
///   conditionalTransformer(
///     (event) => event.category == EventCategory.ui,
///     (event) => EnrichedEvent(event, {'current_route': myRouter.location}),
///   ),
/// );
/// ```
EventTransformer conditionalTransformer(
  bool Function(BaseEvent) condition,
  EventTransformer transformer,
) {
  return (BaseEvent event) {
    if (condition(event)) {
      return transformer(event);
    }
    return event;
  };
}
