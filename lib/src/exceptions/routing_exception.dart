import 'flex_track_exception.dart';

/// Exception thrown by routing-related operations
class RoutingException extends FlexTrackException {
  final String? eventName;
  final String? ruleName;

  const RoutingException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.eventName,
    this.ruleName,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('RoutingException');

    if (code != null) {
      buffer.write('($code)');
    }

    buffer.write(': $message');

    if (eventName != null) {
      buffer.write('\nEvent: $eventName');
    }

    if (ruleName != null) {
      buffer.write('\nRule: $ruleName');
    }

    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }

    return buffer.toString();
  }
}
