import 'package:flex_track/flex_track.dart';

/// Single [FlexTrackRouteObserver] for [MaterialApp.navigatorObservers].
/// Screens that use [FlexTrackRouteViewMixin] must reference this instance.
final FlexTrackRouteObserver appFlexRouteObserver = FlexTrackRouteObserver();
