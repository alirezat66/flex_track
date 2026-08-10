import 'dart:async';

import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/widgets/flex_track_widget_dispatch.dart';
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Tracks when [child] is **visible** in the viewport (scroll lists, etc.).
///
/// Uses [FlexTrackScope.maybeOf] when present, otherwise the global
/// `FlexTrack.track` API when configured.
///
/// **Policy**
///
/// - [visibleFractionThreshold]: [VisibilityInfo.visibleFraction] must reach at
///   least this value (0–1) before an impression is considered.
/// - [minVisibleDuration]: if non-null and positive, the fraction must stay at
///   or above the threshold for at least this long; if the widget leaves the
///   threshold earlier, the timer is reset.
/// - [fireOnce]: if true (default), at most one dispatch per state
///   instance. If false, another impression may fire after visibility drops
///   below the threshold and then meets it again.
///
/// [visibilityKey] must be stable for the same logical slot (e.g. list item id).
class FlexImpressionTrack extends StatefulWidget {
  const FlexImpressionTrack({
    super.key,
    required this.visibilityKey,
    required this.event,
    required this.child,
    this.visibleFractionThreshold = 0.5,
    this.minVisibleDuration,
    this.fireOnce = true,
  }) : assert(
          visibleFractionThreshold > 0 && visibleFractionThreshold <= 1,
          'visibleFractionThreshold must be in (0, 1]',
        );

  final Key visibilityKey;

  final BaseEvent event;

  final Widget child;

  final double visibleFractionThreshold;

  final Duration? minVisibleDuration;

  final bool fireOnce;

  @override
  State<FlexImpressionTrack> createState() => _FlexImpressionTrackState();
}

class _FlexImpressionTrackState extends State<FlexImpressionTrack> {
  Timer? _minDurationTimer;
  DateTime? _aboveThresholdSince;
  bool _permanentlyFired = false;
  bool _firedThisStreak = false;

  @override
  void dispose() {
    _minDurationTimer?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || !flexTrackWidgetsEnabled(context)) {
      return;
    }
    if (widget.fireOnce && _permanentlyFired) {
      return;
    }

    final meets = info.visibleFraction >= widget.visibleFractionThreshold;
    final minDur = widget.minVisibleDuration;

    if (!meets) {
      _minDurationTimer?.cancel();
      _minDurationTimer = null;
      _aboveThresholdSince = null;
      if (!widget.fireOnce) {
        _firedThisStreak = false;
      }
      return;
    }

    if (!widget.fireOnce && _firedThisStreak) {
      return;
    }

    if (minDur == null || minDur <= Duration.zero) {
      _completeImpression();
      return;
    }

    _aboveThresholdSince ??= DateTime.now();
    _minDurationTimer?.cancel();
    final elapsed = DateTime.now().difference(_aboveThresholdSince!);
    final remaining = minDur - elapsed;
    if (remaining <= Duration.zero) {
      _completeImpression();
      return;
    }
    _minDurationTimer = Timer(remaining, () {
      if (!mounted) {
        return;
      }
      _minDurationTimer = null;
      _completeImpression();
    });
  }

  void _completeImpression() {
    _minDurationTimer?.cancel();
    _minDurationTimer = null;
    if (widget.fireOnce && _permanentlyFired) {
      return;
    }
    if (!widget.fireOnce && _firedThisStreak) {
      return;
    }

    if (widget.fireOnce) {
      _permanentlyFired = true;
    } else {
      _firedThisStreak = true;
    }

    if (!mounted) {
      return;
    }
    dispatchFlexTrackWidgetTrack(
      context,
      widget.event,
      FlexTrackWidgetSurface.impression,
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.child,
    );
  }
}
