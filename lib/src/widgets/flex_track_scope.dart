import 'package:flex_track/src/core/flex_track_client.dart';
import 'package:flutter/widgets.dart';

/// Supplies a [FlexTrackClient] to descendant tracking widgets.
///
/// [FlexClickTrack], [FlexImpressionTrack], [FlexMountTrack], and
/// [FlexTrackRouteViewMixin] resolve the client in this order:
///
/// 1. [maybeOf] — scoped [client] from the nearest [FlexTrackScope]
/// 2. Else the global static API when it has been set up (`FlexTrack.setup`)
/// 3. Else no-op
///
/// **Simple apps:** omit this widget; tracking widgets use the static API only.
///
/// **Injectable client:** wrap a subtree (e.g. below `MaterialApp`) with
/// `FlexTrackScope(client: myClient, child: ...)` so widgets and Riverpod/Bloc
/// can share the same instance without passing a client into every widget.
class FlexTrackScope extends InheritedWidget {
  const FlexTrackScope({
    super.key,
    required this.client,
    required super.child,
  });

  /// Client used by descendant flex_track widgets when this scope is found.
  final FlexTrackClient client;

  /// The scoped [FlexTrackClient], or null if there is no [FlexTrackScope]
  /// above [context].
  static FlexTrackClient? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlexTrackScope>()
        ?.client;
  }

  @override
  bool updateShouldNotify(covariant FlexTrackScope oldWidget) {
    return client != oldWidget.client;
  }
}
