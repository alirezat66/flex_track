/// Manages user consent for different types of data processing
/// Provides GDPR and privacy compliance functionality
class ConsentManager {
  bool _hasGeneralConsent = false;
  bool _hasPIIConsent = false;
  bool _hasMarketingConsent = false;
  bool _hasAnalyticsConsent = false;
  bool _hasPerformanceConsent = false;

  DateTime? _consentTimestamp;
  String? _consentVersion;
  Map<String, bool> _customConsents = {};

  /// Whether the user has given general consent for data processing
  bool get hasGeneralConsent => _hasGeneralConsent;

  /// Whether the user has given consent for PII processing
  bool get hasPIIConsent => _hasPIIConsent;

  /// Whether the user has given consent for marketing communications
  bool get hasMarketingConsent => _hasMarketingConsent;

  /// Whether the user has given consent for analytics tracking
  bool get hasAnalyticsConsent => _hasAnalyticsConsent;

  /// Whether the user has given consent for performance monitoring
  bool get hasPerformanceConsent => _hasPerformanceConsent;

  /// When consent was last updated
  DateTime? get consentTimestamp => _consentTimestamp;

  /// Version of consent agreement
  String? get consentVersion => _consentVersion;

  /// Whether any consent has been given
  bool get hasAnyConsent =>
      _hasGeneralConsent ||
      _hasPIIConsent ||
      _hasMarketingConsent ||
      _hasAnalyticsConsent ||
      _hasPerformanceConsent ||
      _customConsents.values.any((consent) => consent);

  /// Whether all standard consents have been given
  bool get hasAllConsents =>
      _hasGeneralConsent &&
      _hasPIIConsent &&
      _hasMarketingConsent &&
      _hasAnalyticsConsent &&
      _hasPerformanceConsent;

  /// Set general consent status
  void setGeneralConsent(bool hasConsent) {
    _hasGeneralConsent = hasConsent;
    _updateTimestamp();
  }

  /// Set PII consent status
  void setPIIConsent(bool hasConsent) {
    _hasPIIConsent = hasConsent;
    _updateTimestamp();
  }

  /// Set marketing consent status
  void setMarketingConsent(bool hasConsent) {
    _hasMarketingConsent = hasConsent;
    _updateTimestamp();
  }

  /// Set analytics consent status
  void setAnalyticsConsent(bool hasConsent) {
    _hasAnalyticsConsent = hasConsent;
    _updateTimestamp();
  }

  /// Set performance consent status
  void setPerformanceConsent(bool hasConsent) {
    _hasPerformanceConsent = hasConsent;
    _updateTimestamp();
  }

  /// Set multiple consent types at once
  void setConsents({
    bool? general,
    bool? pii,
    bool? marketing,
    bool? analytics,
    bool? performance,
    String? version,
  }) {
    if (general != null) _hasGeneralConsent = general;
    if (pii != null) _hasPIIConsent = pii;
    if (marketing != null) _hasMarketingConsent = marketing;
    if (analytics != null) _hasAnalyticsConsent = analytics;
    if (performance != null) _hasPerformanceConsent = performance;
    if (version != null) _consentVersion = version;

    _updateTimestamp();
  }

  /// Grant all standard consents
  void grantAllConsents({String? version}) {
    setConsents(
      general: true,
      pii: true,
      marketing: true,
      analytics: true,
      performance: true,
      version: version,
    );
  }

  /// Revoke all consents
  void revokeAllConsents() {
    setConsents(
      general: false,
      pii: false,
      marketing: false,
      analytics: false,
      performance: false,
    );
    _customConsents.clear();
  }

  /// Set custom consent for specific purposes
  void setCustomConsent(String purpose, bool hasConsent) {
    _customConsents[purpose] = hasConsent;
    _updateTimestamp();
  }

  /// Get custom consent status
  bool getCustomConsent(String purpose) {
    return _customConsents[purpose] ?? false;
  }

  /// Remove custom consent
  void removeCustomConsent(String purpose) {
    _customConsents.remove(purpose);
    _updateTimestamp();
  }

  /// Get all custom consents
  Map<String, bool> getCustomConsents() {
    return Map.unmodifiable(_customConsents);
  }

  /// Set consent version
  void setConsentVersion(String version) {
    _consentVersion = version;
    _updateTimestamp();
  }

  /// Check if consent is required for a specific data type
  bool isConsentRequiredFor(ConsentType type) {
    switch (type) {
      case ConsentType.general:
        return !_hasGeneralConsent;
      case ConsentType.pii:
        return !_hasPIIConsent;
      case ConsentType.marketing:
        return !_hasMarketingConsent;
      case ConsentType.analytics:
        return !_hasAnalyticsConsent;
      case ConsentType.performance:
        return !_hasPerformanceConsent;
    }
  }

  /// Check if data processing is allowed for specific type
  bool isAllowedFor(ConsentType type) {
    switch (type) {
      case ConsentType.general:
        return _hasGeneralConsent;
      case ConsentType.pii:
        return _hasPIIConsent;
      case ConsentType.marketing:
        return _hasMarketingConsent;
      case ConsentType.analytics:
        return _hasAnalyticsConsent;
      case ConsentType.performance:
        return _hasPerformanceConsent;
    }
  }

  /// Create a consent summary for compliance reporting
  ConsentSummary getSummary() {
    return ConsentSummary(
      hasGeneralConsent: _hasGeneralConsent,
      hasPIIConsent: _hasPIIConsent,
      hasMarketingConsent: _hasMarketingConsent,
      hasAnalyticsConsent: _hasAnalyticsConsent,
      hasPerformanceConsent: _hasPerformanceConsent,
      customConsents: Map.from(_customConsents),
      consentTimestamp: _consentTimestamp,
      consentVersion: _consentVersion,
    );
  }

  /// Load consent state from a map (e.g., from storage)
  void loadFromMap(Map<String, dynamic> data) {
    _hasGeneralConsent = data['general'] ?? false;
    _hasPIIConsent = data['pii'] ?? false;
    _hasMarketingConsent = data['marketing'] ?? false;
    _hasAnalyticsConsent = data['analytics'] ?? false;
    _hasPerformanceConsent = data['performance'] ?? false;
    _consentVersion = data['version'];

    if (data['timestamp'] != null) {
      _consentTimestamp = DateTime.tryParse(data['timestamp']);
    }

    if (data['custom'] != null && data['custom'] is Map) {
      _customConsents = Map<String, bool>.from(data['custom']);
    }
  }

  /// Export consent state to a map (e.g., for storage)
  Map<String, dynamic> toMap() {
    return {
      'general': _hasGeneralConsent,
      'pii': _hasPIIConsent,
      'marketing': _hasMarketingConsent,
      'analytics': _hasAnalyticsConsent,
      'performance': _hasPerformanceConsent,
      'custom': Map.from(_customConsents),
      'timestamp': _consentTimestamp?.toIso8601String(),
      'version': _consentVersion,
    };
  }

  /// Update the consent timestamp
  void _updateTimestamp() {
    _consentTimestamp = DateTime.now();
  }

  /// Validate consent configuration
  List<String> validate() {
    final issues = <String>[];

    // Check for potential GDPR compliance issues
    if (_hasGeneralConsent && !_hasPIIConsent) {
      issues.add(
          'General consent granted but PII consent denied - may cause compliance issues');
    }

    // Check consent version
    if (_consentVersion == null && hasAnyConsent) {
      issues
          .add('Consent version not set - recommended for compliance tracking');
    }

    // Check consent timestamp
    if (_consentTimestamp == null && hasAnyConsent) {
      issues
          .add('Consent timestamp not set - required for compliance reporting');
    }

    return issues;
  }

  @override
  String toString() {
    final consents = <String>[];
    if (_hasGeneralConsent) consents.add('general');
    if (_hasPIIConsent) consents.add('pii');
    if (_hasMarketingConsent) consents.add('marketing');
    if (_hasAnalyticsConsent) consents.add('analytics');
    if (_hasPerformanceConsent) consents.add('performance');

    return 'ConsentManager(${consents.join(', ')}${_customConsents.isNotEmpty ? ', custom: ${_customConsents.length}' : ''})';
  }
}

/// Types of consent that can be managed
enum ConsentType {
  general,
  pii,
  marketing,
  analytics,
  performance,
}

/// Summary of consent status for reporting and compliance
class ConsentSummary {
  final bool hasGeneralConsent;
  final bool hasPIIConsent;
  final bool hasMarketingConsent;
  final bool hasAnalyticsConsent;
  final bool hasPerformanceConsent;
  final Map<String, bool> customConsents;
  final DateTime? consentTimestamp;
  final String? consentVersion;

  const ConsentSummary({
    required this.hasGeneralConsent,
    required this.hasPIIConsent,
    required this.hasMarketingConsent,
    required this.hasAnalyticsConsent,
    required this.hasPerformanceConsent,
    required this.customConsents,
    this.consentTimestamp,
    this.consentVersion,
  });

  /// Whether any consent has been given
  bool get hasAnyConsent =>
      hasGeneralConsent ||
      hasPIIConsent ||
      hasMarketingConsent ||
      hasAnalyticsConsent ||
      hasPerformanceConsent ||
      customConsents.values.any((consent) => consent);

  /// Whether all standard consents have been given
  bool get hasAllStandardConsents =>
      hasGeneralConsent &&
      hasPIIConsent &&
      hasMarketingConsent &&
      hasAnalyticsConsent &&
      hasPerformanceConsent;

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'general': hasGeneralConsent,
      'pii': hasPIIConsent,
      'marketing': hasMarketingConsent,
      'analytics': hasAnalyticsConsent,
      'performance': hasPerformanceConsent,
      'custom': customConsents,
      'timestamp': consentTimestamp?.toIso8601String(),
      'version': consentVersion,
      'hasAnyConsent': hasAnyConsent,
      'hasAllStandardConsents': hasAllStandardConsents,
    };
  }

  @override
  String toString() {
    return 'ConsentSummary(any: $hasAnyConsent, all: $hasAllStandardConsents, version: $consentVersion)';
  }
}
