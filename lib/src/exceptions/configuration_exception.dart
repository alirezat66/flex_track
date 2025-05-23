import 'flex_track_exception.dart';

/// Exception thrown by configuration-related operations
class ConfigurationException extends FlexTrackException {
  final String? configType;
  final String? fieldName;

  const ConfigurationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.configType,
    this.fieldName,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('ConfigurationException');

    if (code != null) {
      buffer.write('($code)');
    }

    buffer.write(': $message');

    if (configType != null) {
      buffer.write('\nConfiguration Type: $configType');
    }

    if (fieldName != null) {
      buffer.write('\nField: $fieldName');
    }

    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }

    return buffer.toString();
  }
}
