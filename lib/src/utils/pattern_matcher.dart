/// Utility for matching event names and properties against patterns
class PatternMatcher {
  // Cache compiled regexes for performance
  static final Map<String, RegExp> _regexCache = {};
  static const int _maxCacheSize = 100;

  /// Match event name against a simple pattern (supports * wildcards)
  static bool matchSimplePattern(String eventName, String pattern) {
    if (pattern == '*') return true;
    if (pattern == eventName) return true;

    // Convert simple wildcards to regex
    final regexPattern = pattern.replaceAll('*', '.*').replaceAll('?', '.');

    final regex = _getCachedRegex('^$regexPattern\$');
    return regex.hasMatch(eventName);
  }

  /// Match event name against a regex pattern
  static bool matchRegexPattern(String eventName, RegExp pattern) {
    return pattern.hasMatch(eventName);
  }

  /// Match event name against multiple patterns (OR logic)
  static bool matchAnyPattern(String eventName, List<String> patterns) {
    return patterns.any((pattern) => matchSimplePattern(eventName, pattern));
  }

  /// Match event name against multiple regex patterns (OR logic)
  static bool matchAnyRegexPattern(String eventName, List<RegExp> patterns) {
    return patterns.any((pattern) => pattern.hasMatch(eventName));
  }

  /// Check if event name starts with any of the given prefixes
  static bool matchAnyPrefix(String eventName, List<String> prefixes) {
    return prefixes.any((prefix) => eventName.startsWith(prefix));
  }

  /// Check if event name ends with any of the given suffixes
  static bool matchAnySuffix(String eventName, List<String> suffixes) {
    return suffixes.any((suffix) => eventName.endsWith(suffix));
  }

  /// Check if event name contains any of the given substrings
  static bool matchAnySubstring(String eventName, List<String> substrings) {
    return substrings.any((substring) => eventName.contains(substring));
  }

  /// Match properties against patterns
  static bool matchProperty(
    Map<String, dynamic>? properties,
    String propertyName, {
    dynamic expectedValue,
    String? pattern,
    RegExp? regex,
  }) {
    if (properties == null || !properties.containsKey(propertyName)) {
      return false;
    }

    final value = properties[propertyName];

    // Exact value match
    if (expectedValue != null) {
      return value == expectedValue;
    }

    // Pattern match (for string values)
    if (pattern != null && value is String) {
      return matchSimplePattern(value, pattern);
    }

    // Regex match (for string values)
    if (regex != null && value is String) {
      return regex.hasMatch(value);
    }

    // Property exists
    return true;
  }

  /// Match multiple properties (AND logic)
  static bool matchAllProperties(
      Map<String, dynamic>? properties, Map<String, PropertyMatcher> matchers) {
    if (properties == null) return false;

    return matchers.entries.every((entry) {
      final propertyName = entry.key;
      final matcher = entry.value;

      return matchProperty(
        properties,
        propertyName,
        expectedValue: matcher.expectedValue,
        pattern: matcher.pattern,
        regex: matcher.regex,
      );
    });
  }

  /// Match any of multiple properties (OR logic)
  static bool matchAnyProperty(
      Map<String, dynamic>? properties, Map<String, PropertyMatcher> matchers) {
    if (properties == null) return false;

    return matchers.entries.any((entry) {
      final propertyName = entry.key;
      final matcher = entry.value;

      return matchProperty(
        properties,
        propertyName,
        expectedValue: matcher.expectedValue,
        pattern: matcher.pattern,
        regex: matcher.regex,
      );
    });
  }

  /// Create a regex pattern for common event categories
  static RegExp createCategoryPattern(EventCategoryPattern category) {
    switch (category) {
      case EventCategoryPattern.userInteraction:
        return _getCachedRegex(
            r'(click|tap|touch|swipe|scroll|input|select|focus|blur)_.*');
      case EventCategoryPattern.navigation:
        return _getCachedRegex(r'(page_view|navigate|route|screen|tab)_.*');
      case EventCategoryPattern.business:
        return _getCachedRegex(
            r'(purchase|payment|signup|login|subscription|conversion)_.*');
      case EventCategoryPattern.error:
        return _getCachedRegex(r'(error|exception|crash|failure|timeout)_.*');
      case EventCategoryPattern.performance:
        return _getCachedRegex(r'(load|render|response|latency|memory|cpu)_.*');
      case EventCategoryPattern.debug:
        return _getCachedRegex(r'(debug|test|dev|trace|log)_.*');
      case EventCategoryPattern.system:
        return _getCachedRegex(r'(system|health|heartbeat|status|config)_.*');
      case EventCategoryPattern.network:
        return _getCachedRegex(
            r'(api|http|request|response|network|download|upload)_.*');
    }
  }

  /// Check if event name matches a category pattern
  static bool matchesCategory(String eventName, EventCategoryPattern category) {
    final pattern = createCategoryPattern(category);
    return pattern.hasMatch(eventName);
  }

  /// Validate pattern syntax
  static PatternValidationResult validatePattern(String pattern) {
    try {
      // Test simple patterns
      if (pattern.contains('*') || pattern.contains('?')) {
        final regexPattern = pattern.replaceAll('*', '.*').replaceAll('?', '.');
        RegExp('^$regexPattern\$');
        return PatternValidationResult.valid();
      }

      // Test as regex
      RegExp(pattern);
      return PatternValidationResult.valid();
    } catch (e) {
      return PatternValidationResult.invalid('Invalid pattern: $e');
    }
  }

  /// Get cached regex or create and cache new one
  static RegExp _getCachedRegex(String pattern) {
    if (_regexCache.containsKey(pattern)) {
      return _regexCache[pattern]!;
    }

    // Clear cache if it gets too large
    if (_regexCache.length >= _maxCacheSize) {
      _regexCache.clear();
    }

    final regex = RegExp(pattern, caseSensitive: false);
    _regexCache[pattern] = regex;
    return regex;
  }

  /// Clear the regex cache (useful for testing)
  static void clearCache() {
    _regexCache.clear();
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'size': _regexCache.length,
      'maxSize': _maxCacheSize,
    };
  }
}

/// Property matcher configuration
class PropertyMatcher {
  final dynamic expectedValue;
  final String? pattern;
  final RegExp? regex;

  const PropertyMatcher({
    this.expectedValue,
    this.pattern,
    this.regex,
  });

  /// Create a matcher for exact value
  factory PropertyMatcher.equals(dynamic value) {
    return PropertyMatcher(expectedValue: value);
  }

  /// Create a matcher for pattern matching
  factory PropertyMatcher.pattern(String pattern) {
    return PropertyMatcher(pattern: pattern);
  }

  /// Create a matcher for regex matching
  factory PropertyMatcher.regex(RegExp regex) {
    return PropertyMatcher(regex: regex);
  }

  @override
  String toString() {
    if (expectedValue != null) return 'equals($expectedValue)';
    if (pattern != null) return 'pattern($pattern)';
    if (regex != null) return 'regex(${regex!.pattern})';
    return 'exists';
  }
}

/// Common event category patterns
enum EventCategoryPattern {
  userInteraction,
  navigation,
  business,
  error,
  performance,
  debug,
  system,
  network,
}

/// Result of pattern validation
class PatternValidationResult {
  final bool isValid;
  final String? error;

  const PatternValidationResult._(this.isValid, this.error);

  factory PatternValidationResult.valid() {
    return const PatternValidationResult._(true, null);
  }

  factory PatternValidationResult.invalid(String error) {
    return PatternValidationResult._(false, error);
  }

  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $error';
  }
}
