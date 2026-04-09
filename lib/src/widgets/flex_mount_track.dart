import 'package:flex_track/src/core/flex_track.dart';
import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Fires [event] once after the first frame where this widget is laid out.
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
    if (!FlexTrack.isSetUp) {
      return;
    }
    FlexTrack.track(widget.event).then(
      (_) {},
      onError: (Object e, StackTrace st) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: st,
            library: 'flex_track',
            context: ErrorDescription('while dispatching FlexMountTrack'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
