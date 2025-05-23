import 'flex_track_exception.dart';

/// Exception thrown by tracker-related operations
class TrackerException extends FlexTrackException {
  final String? trackerId;
  final String? eventName;

  const TrackerException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.trackerId,
    this.eventName,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('TrackerException');

    if (code != null) {
      buffer.write('($code)');
    }

    buffer.write(': $message');

    if (trackerId != null) {
      buffer.write('\nTracker ID: $trackerId');
    }

    if (eventName != null) {
      buffer.write('\nEvent: $eventName');
    }

    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }

    return buffer.toString();
  }
}
