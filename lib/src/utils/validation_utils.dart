/// Utility class for validating FlexTrack configurations and data
class ValidationUtils {
  /// Validate tracker ID
  static ValidationResult validateTrackerId(String? trackerId) {
    if (trackerId == null || trackerId.isEmpty) {
      return ValidationResult.invalid('Tracker ID cannot be null or empty');
    }

    if (trackerId.length > 50) {
      return ValidationResult.invalid('Tracker ID cannot exceed 50 characters');
    }

    // Check for valid characters (alphanumeric, underscore, hyphen)
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(trackerId)) {
      return ValidationResult.invalid(
          'Tracker ID can only contain letters, numbers, underscores, and hyphens');
    }

    // Reserved IDs
    const reservedIds = ['all', 'none', 'default', 'system'];
    if (reservedIds.contains(trackerId.toLowerCase())) {
      return ValidationResult.invalid('Tracker ID "$trackerId" is reserved');
    }

    return ValidationResult.valid();
  }

  /// Validate event name
  static ValidationResult validateEventName(String? eventName) {
    if (eventName == null || eventName.isEmpty) {
      return ValidationResult.invalid('Event name cannot be null or empty');
    }

    if (eventName.length > 100) {
      return ValidationResult.invalid(
          'Event name cannot exceed 100 characters');
    }

    // Check for valid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
    if (!validPattern.hasMatch(eventName)) {
      return ValidationResult.invalid(
          'Event name can only contain letters, numbers, underscores, dots, and hyphens');
    }

    // Should not start with numbers or special characters
    if (!RegExp(r'^[a-zA-Z]').hasMatch(eventName)) {
      return ValidationResult.invalid('Event name must start with a letter');
    }

    return ValidationResult.valid();
  }

  /// Validate event properties
  static ValidationResult validateEventProperties(
      Map<String, Object>? properties) {
    if (properties == null) {
      return ValidationResult.valid();
    }

    if (properties.length > 50) {
      return ValidationResult.invalid(
          'Event cannot have more than 50 properties');
    }

    for (final entry in properties.entries) {
      final keyResult = validatePropertyKey(entry.key);
      if (!keyResult.isValid) {
        return ValidationResult.invalid(
            'Invalid property key "${entry.key}": ${keyResult.error}');
      }

      final valueResult = validatePropertyValue(entry.value);
      if (!valueResult.isValid) {
        return ValidationResult.invalid(
            'Invalid property value for "${entry.key}": ${valueResult.error}');
      }
    }

    return ValidationResult.valid();
  }

  /// Validate property key
  static ValidationResult validatePropertyKey(String key) {
    if (key.isEmpty) {
      return ValidationResult.invalid('Property key cannot be empty');
    }

    if (key.length > 30) {
      return ValidationResult.invalid(
          'Property key cannot exceed 30 characters');
    }

    // Check for valid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validPattern.hasMatch(key)) {
      return ValidationResult.invalid(
          'Property key can only contain letters, numbers, and underscores');
    }

    // Reserved property names
    const reservedKeys = [
      'timestamp',
      'event_name',
      'user_id',
      'session_id',
      'device_id',
      'app_version',
      'platform',
      'environment'
    ];
    if (reservedKeys.contains(key.toLowerCase())) {
      return ValidationResult.invalid('Property key "$key" is reserved');
    }

    return ValidationResult.valid();
  }

  /// Validate property value
  static ValidationResult validatePropertyValue(Object value) {
    // Check allowed types
    if (!(value is String ||
        value is num ||
        value is bool ||
        value is DateTime)) {
      return ValidationResult.invalid(
          'Property value must be String, num, bool, or DateTime');
    }

    // String value validation
    if (value is String) {
      if (value.length > 1000) {
        return ValidationResult.invalid(
            'String property value cannot exceed 1000 characters');
      }
    }

    // Numeric value validation
    if (value is num) {
      if (value.isNaN || value.isInfinite) {
        return ValidationResult.invalid(
            'Numeric property value cannot be NaN or infinite');
      }
    }

    return ValidationResult.valid();
  }

  /// Validate user ID
  static ValidationResult validateUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      return ValidationResult.valid(); // User ID is optional
    }

    if (userId.length > 100) {
      return ValidationResult.invalid('User ID cannot exceed 100 characters');
    }

    // Check for potentially problematic characters
    if (userId.contains('\n') ||
        userId.contains('\r') ||
        userId.contains('\t')) {
      return ValidationResult.invalid(
          'User ID cannot contain newlines or tabs');
    }

    return ValidationResult.valid();
  }

  /// Validate session ID
  static ValidationResult validateSessionId(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      return ValidationResult.valid(); // Session ID is optional
    }

    if (sessionId.length > 100) {
      return ValidationResult.invalid(
          'Session ID cannot exceed 100 characters');
    }

    // Should be a valid identifier format
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(sessionId)) {
      return ValidationResult.invalid(
          'Session ID can only contain letters, numbers, underscores, and hyphens');
    }

    return ValidationResult.valid();
  }

  /// Validate sample rate
  static ValidationResult validateSampleRate(double sampleRate) {
    if (sampleRate < 0.0) {
      return ValidationResult.invalid('Sample rate cannot be negative');
    }

    if (sampleRate > 1.0) {
      return ValidationResult.invalid('Sample rate cannot exceed 1.0');
    }

    if (sampleRate.isNaN || sampleRate.isInfinite) {
      return ValidationResult.invalid('Sample rate must be a valid number');
    }

    return ValidationResult.valid();
  }

  /// Validate rule priority
  static ValidationResult validateRulePriority(int priority) {
    if (priority < -1000 || priority > 1000) {
      return ValidationResult.invalid(
          'Rule priority must be between -1000 and 1000');
    }

    return ValidationResult.valid();
  }

  /// Validate tracker group configuration
  static ValidationResult validateTrackerGroup(
      String groupName, List<String> trackerIds) {
    // Validate group name
    final nameResult = validateTrackerId(groupName);
    if (!nameResult.isValid) {
      return ValidationResult.invalid(
          'Invalid group name: ${nameResult.error}');
    }

    // Validate tracker IDs
    if (trackerIds.isEmpty) {
      return ValidationResult.invalid(
          'Tracker group must contain at least one tracker ID');
    }

    if (trackerIds.length > 20) {
      return ValidationResult.invalid(
          'Tracker group cannot contain more than 20 trackers');
    }

    for (final trackerId in trackerIds) {
      if (trackerId != '*') {
        // '*' is special case for "all"
        final idResult = validateTrackerId(trackerId);
        if (!idResult.isValid) {
          return ValidationResult.invalid(
              'Invalid tracker ID "$trackerId": ${idResult.error}');
        }
      }
    }

    // Check for duplicates
    final uniqueIds = trackerIds.toSet();
    if (uniqueIds.length != trackerIds.length) {
      return ValidationResult.invalid(
          'Tracker group contains duplicate tracker IDs');
    }

    return ValidationResult.valid();
  }

  /// Validate routing configuration
  static ValidationResult validateRoutingConfiguration(
      List<ValidationRule> rules) {
    if (rules.isEmpty) {
      return ValidationResult.warning(
          'No routing rules defined - events may not be tracked');
    }

    if (rules.length > 100) {
      return ValidationResult.invalid('Too many routing rules (max 100)');
    }

    // Check for duplicate rule IDs
    final ruleIds =
        rules.where((rule) => rule.id != null).map((rule) => rule.id!).toList();

    final uniqueIds = ruleIds.toSet();
    if (uniqueIds.length != ruleIds.length) {
      return ValidationResult.invalid('Duplicate rule IDs found');
    }

    // Check for default rule
    final hasDefaultRule = rules.any((rule) => rule.isDefault);
    if (!hasDefaultRule) {
      return ValidationResult.warning(
          'No default routing rule - unmatched events may not be tracked');
    }

    // Validate each rule
    for (final rule in rules) {
      final ruleResult = validateRoutingRule(rule);
      if (!ruleResult.isValid) {
        return ValidationResult.invalid(
            'Invalid routing rule: ${ruleResult.error}');
      }
    }

    return ValidationResult.valid();
  }

  /// Validate individual routing rule
  static ValidationResult validateRoutingRule(ValidationRule rule) {
    // Validate rule ID
    if (rule.id != null) {
      final idResult = validateTrackerId(rule.id!);
      if (!idResult.isValid) {
        return ValidationResult.invalid('Invalid rule ID: ${idResult.error}');
      }
    }

    // Validate sample rate
    final sampleResult = validateSampleRate(rule.sampleRate);
    if (!sampleResult.isValid) {
      return sampleResult;
    }

    // Validate priority
    final priorityResult = validateRulePriority(rule.priority);
    if (!priorityResult.isValid) {
      return priorityResult;
    }

    // Validate target group
    if (rule.targetGroup != null) {
      final groupResult = validateTrackerGroup(
          rule.targetGroup!.name, rule.targetGroup!.trackerIds);
      if (!groupResult.isValid) {
        return ValidationResult.invalid(
            'Invalid target group: ${groupResult.error}');
      }
    }

    // Validate conflicting conditions
    if (rule.debugOnly && rule.productionOnly) {
      return ValidationResult.invalid(
          'Rule cannot be both debug-only and production-only');
    }

    return ValidationResult.valid();
  }

  /// Validate consent configuration
  static ValidationResult validateConsentConfiguration(
      ConsentValidationData data) {
    // Check for required consent in production
    if (data.isProduction && !data.hasAnyConsent) {
      return ValidationResult.warning(
          'No consent configured in production environment');
    }

    // Check for PII consent when tracking PII
    if (data.tracksPII && !data.hasPIIConsent) {
      return ValidationResult.invalid(
          'PII consent required when tracking personally identifiable information');
    }

    // Check consent version
    if (data.hasAnyConsent && data.consentVersion == null) {
      return ValidationResult.warning(
          'Consent version not set - recommended for compliance tracking');
    }

    return ValidationResult.valid();
  }

  /// Validate complete FlexTrack setup
  static List<ValidationResult> validateSetup(SetupValidationData data) {
    final results = <ValidationResult>[];

    // Validate trackers
    if (data.trackers.isEmpty) {
      results.add(
          ValidationResult.invalid('At least one tracker must be registered'));
    } else {
      for (final tracker in data.trackers) {
        final trackerResult = validateTrackerId(tracker.id);
        if (!trackerResult.isValid) {
          results.add(ValidationResult.invalid(
              'Invalid tracker "${tracker.name}": ${trackerResult.error}'));
        }
      }
    }

    // Validate routing rules
    final routingResult = validateRoutingConfiguration(data.routingRules);
    results.add(routingResult);

    // Validate consent
    final consentResult = validateConsentConfiguration(data.consentData);
    results.add(consentResult);

    return results
        .where((result) => !result.isValid || result.isWarning)
        .toList();
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final bool isWarning;
  final String? error;

  const ValidationResult._(this.isValid, this.isWarning, this.error);

  factory ValidationResult.valid() {
    return const ValidationResult._(true, false, null);
  }

  factory ValidationResult.invalid(String error) {
    return ValidationResult._(false, false, error);
  }

  factory ValidationResult.warning(String warning) {
    return ValidationResult._(true, true, warning);
  }

  @override
  String toString() {
    if (isValid && !isWarning) return 'Valid';
    if (isWarning) return 'Warning: $error';
    return 'Invalid: $error';
  }
}

/// Data classes for validation

class ValidationRule {
  final String? id;
  final double sampleRate;
  final int priority;
  final bool debugOnly;
  final bool productionOnly;
  final bool isDefault;
  final ValidationTrackerGroup? targetGroup;

  const ValidationRule({
    this.id,
    required this.sampleRate,
    required this.priority,
    this.debugOnly = false,
    this.productionOnly = false,
    this.isDefault = false,
    this.targetGroup,
  });
}

class ValidationTrackerGroup {
  final String name;
  final List<String> trackerIds;

  const ValidationTrackerGroup(this.name, this.trackerIds);
}

class ValidationTracker {
  final String id;
  final String name;

  const ValidationTracker(this.id, this.name);
}

class ConsentValidationData {
  final bool isProduction;
  final bool hasAnyConsent;
  final bool hasPIIConsent;
  final bool tracksPII;
  final String? consentVersion;

  const ConsentValidationData({
    required this.isProduction,
    required this.hasAnyConsent,
    required this.hasPIIConsent,
    required this.tracksPII,
    this.consentVersion,
  });
}

class SetupValidationData {
  final List<ValidationTracker> trackers;
  final List<ValidationRule> routingRules;
  final ConsentValidationData consentData;

  const SetupValidationData({
    required this.trackers,
    required this.routingRules,
    required this.consentData,
  });
}
