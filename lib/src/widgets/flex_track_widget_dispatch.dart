import 'package:flex_track/src/core/flex_track.dart';
import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/widgets/flex_track_scope.dart';
import 'package:flutter/widgets.dart';

/// Which flex_track widget is sending an event (used for error reporting).
enum FlexTrackWidgetSurface {
  click('FlexClickTrack'),
  impression('FlexImpressionTrack'),
  mount('FlexMountTrack'),
  routeViewMixin('FlexTrackRouteViewMixin');

  const FlexTrackWidgetSurface(this._label);
  final String _label;
}

/// True when a flex_track widget should run tracking for this [context]:
/// either a scoped [FlexTrackClient] exists, or the global API is ready.
bool flexTrackWidgetsEnabled(BuildContext context) {
  return FlexTrackScope.maybeOf(context) != null || FlexTrack.isSetUp;
}

/// Dispatches [event] via [FlexTrackScope] when present, else [FlexTrack.track].
///
/// No-ops when neither a scoped client nor global setup exists.
void dispatchFlexTrackWidgetTrack(
  BuildContext context,
  BaseEvent event,
  FlexTrackWidgetSurface surface,
) {
  final scoped = FlexTrackScope.maybeOf(context);
  late final Future<void> trackFuture;
  if (scoped != null) {
    trackFuture = scoped.track(event);
  } else if (FlexTrack.isSetUp) {
    trackFuture = FlexTrack.track(event);
  } else {
    return;
  }

  trackFuture.then(
    (_) {},
    onError: (Object e, StackTrace st) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'flex_track',
          context: ErrorDescription('while dispatching ${surface._label}'),
        ),
      );
    },
  );
}
