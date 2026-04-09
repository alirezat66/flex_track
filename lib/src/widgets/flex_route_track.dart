import 'package:flex_track/src/core/flex_track.dart';
import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// [Navigator] observer used with [FlexTrackRouteViewMixin].
///
/// Register a single instance on [MaterialApp.navigatorObservers] (or
/// [CupertinoApp]) so mixin subscribers receive [RouteAware] callbacks.
///
/// ```dart
/// final flexRouteObserver = FlexTrackRouteObserver();
///
/// MaterialApp(
///   navigatorObservers: [flexRouteObserver],
///   home: MyScreen(),
/// );
/// ```
class FlexTrackRouteObserver extends RouteObserver<PageRoute<dynamic>> {}

/// Mixin on [State] for sending a [routeViewEvent] when the enclosing
/// [PageRoute] becomes relevant.
///
/// **Semantics**
///
/// - **Initial / first open** — [FlexTrack.track] runs when
///   [trackOnInitialPush] is true (default), using either [RouteAware.didPush]
///   or a one-time post-frame callback if the initial route never receives
///   `didPush` (e.g. [MaterialApp] [home]).
/// - **[didPopNext]** — A route above this one was popped; this route is
///   visible again. Fires only when [trackWhenReturningFromChildRoute] is true
///   (default false).
///
/// [didPushNext] and [didPop] do not send events.
///
/// Register the same [FlexTrackRouteObserver] on [MaterialApp.navigatorObservers].
/// The enclosing route must be a [PageRoute].
mixin FlexTrackRouteViewMixin<T extends StatefulWidget> on State<T>
    implements RouteAware {
  /// Observer registered on [MaterialApp.navigatorObservers].
  FlexTrackRouteObserver get flexTrackRouteObserver;

  /// Event to send when a tracked route transition occurs.
  BaseEvent get routeViewEvent;

  /// Whether to send [routeViewEvent] when this route first becomes the current
  /// top route.
  bool get trackOnInitialPush => true;

  /// Whether to send [routeViewEvent] on [didPopNext] when returning from a
  /// route that was pushed above this one.
  bool get trackWhenReturningFromChildRoute => false;

  bool _initialOpenTracked = false;
  bool _scheduledPostFrameFallback = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute<dynamic>) {
      flexTrackRouteObserver.subscribe(this, modalRoute);
      if (trackOnInitialPush &&
          !_initialOpenTracked &&
          !_scheduledPostFrameFallback) {
        _scheduledPostFrameFallback = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !trackOnInitialPush || _initialOpenTracked) {
            return;
          }
          final route = ModalRoute.of(context);
          if (route is PageRoute<dynamic> && route.isCurrent) {
            _initialOpenTracked = true;
            _dispatchRouteView();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    flexTrackRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    if (trackOnInitialPush && !_initialOpenTracked) {
      _initialOpenTracked = true;
      _dispatchRouteView();
    }
  }

  @override
  void didPopNext() {
    if (trackWhenReturningFromChildRoute) {
      _dispatchRouteView();
    }
  }

  @override
  void didPushNext() {}

  @override
  void didPop() {}

  void _dispatchRouteView() {
    if (!FlexTrack.isSetUp) {
      return;
    }
    FlexTrack.track(routeViewEvent).then(
      (_) {},
      onError: (Object e, StackTrace st) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: st,
            library: 'flex_track',
            context: ErrorDescription('while dispatching FlexTrackRouteViewMixin'),
          ),
        );
      },
    );
  }
}
