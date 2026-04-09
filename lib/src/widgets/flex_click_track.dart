import 'package:flex_track/src/core/flex_track.dart';
import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Wraps [child] and sends [event] with [FlexTrack.track] when the user
/// completes a **tap** in the hit region (short press with little movement).
///
/// Uses a [Listener] with [HitTestBehavior.translucent] on pointer down/up so
/// nested [InkWell]s and buttons still work, while drags/scrolls (movement
/// beyond [kTouchSlop]) do not trigger tracking.
class FlexClickTrack extends StatefulWidget {
  const FlexClickTrack({
    super.key,
    required this.event,
    required this.child,
  });

  final BaseEvent event;

  final Widget child;

  @override
  State<FlexClickTrack> createState() => _FlexClickTrackState();
}

class _FlexClickTrackState extends State<FlexClickTrack> {
  int? _activePointer;
  Offset? _downGlobalPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    _downGlobalPosition = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    final start = _downGlobalPosition;
    _activePointer = null;
    _downGlobalPosition = null;
    if (start == null) {
      return;
    }
    final moved = (event.position - start).distance;
    if (moved > kTouchSlop) {
      return;
    }
    _dispatchTrack();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointer) {
      _activePointer = null;
      _downGlobalPosition = null;
    }
  }

  void _dispatchTrack() {
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
            context: ErrorDescription('while dispatching FlexClickTrack'),
          ),
        );
      },
    );
  }
}
