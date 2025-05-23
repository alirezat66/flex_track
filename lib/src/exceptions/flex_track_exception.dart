abstract class FlexTrackException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const FlexTrackException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(runtimeType.toString());
    if (code != null) {
      buffer.write('($code)');
    }
    buffer.write(': $message');

    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }

    return buffer.toString();
  }
}
