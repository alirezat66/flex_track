import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/widgets/flex_track_widget_dispatch.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Fires [event] once after the first frame where this widget is laid out.
///
/// Uses [FlexTrackScope.maybeOf] when present, otherwise the global
/// `FlexTrack.track` API when configured.
///
/// **Limitations (by design)**
///
/// - This is **not** proof the user *saw* the widget: off-screen subtrees,
///   hidden tabs, or backgrounded apps can still run the post-frame callback.
/// - Prefer [FlexImpressionTrack] or route-level tracking when “visible in
///   viewport” or “screen shown” semantics matter.
///
/// Suitable for simple “widget mounted” analytics when the parent already
/// guarantees visibility (e.g. body of the active tab).
class FlexMountTrack extends StatefulWidget {
  const FlexMountTrack({
    super.key,
    required this.event,
    required this.child,
  });

  final BaseEvent event;

  final Widget child;

  @override
  State<FlexMountTrack> createState() => _FlexMountTrackState();
}

class _FlexMountTrackState extends State<FlexMountTrack> {
  bool _dispatched = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _dispatchOnce());
  }

  void _dispatchOnce() {
    if (!mounted || _dispatched) {
      return;
    }
    _dispatched = true;
    dispatchFlexTrackWidgetTrack(
      context,
      widget.event,
      FlexTrackWidgetSurface.mount,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
