import 'consent_manager.dart';

/// Context information for tracking events
/// Contains environment, user, and session data that affects routing and processing
class TrackingContext {
  final String? _userId;
  final String? _sessionId;
  final String? _deviceId;
  final Map<String, dynamic> _userProperties;
  final Map<String, dynamic> _sessionProperties;
  final ConsentManager _consentManager;
  final Environment _environment;
  final String? _appVersion;
  final String? _buildNumber;
  final DateTime _createdAt;

  TrackingContext._({
    String? userId,
    String? sessionId,
    String? deviceId,
    Map<String, dynamic>? userProperties,
    Map<String, dynamic>? sessionProperties,
    ConsentManager? consentManager,
    Environment environment = Environment.production,
    String? appVersion,
    String? buildNumber,
  })  : _userId = userId,
        _sessionId = sessionId,
        _deviceId = deviceId,
        _userProperties = userProperties ?? {},
        _sessionProperties = sessionProperties ?? {},
        _consentManager = consentManager ?? ConsentManager(),
        _environment = environment,
        _appVersion = appVersion,
        _buildNumber = buildNumber,
        _createdAt = DateTime.now();

  /// Create a new tracking context
  factory TrackingContext.create({
    String? userId,
    String? sessionId,
    String? deviceId,
    Map<String, dynamic>? userProperties,
    Map<String, dynamic>? sessionProperties,
    ConsentManager? consentManager,
    Environment environment = Environment.production,
    String? appVersion,
    String? buildNumber,
  }) {
    return TrackingContext._(
      userId: userId,
      sessionId: sessionId,
      deviceId: deviceId,
      userProperties: userProperties,
      sessionProperties: sessionProperties,
      consentManager: consentManager,
      environment: environment,
      appVersion: appVersion,
      buildNumber: buildNumber,
    );
  }

  /// Create a development context with debug settings
  factory TrackingContext.development({
    String? userId,
    String? sessionId,
    ConsentManager? consentManager,
  }) {
    return TrackingContext._(
      userId: userId,
      sessionId: sessionId,
      deviceId: 'dev-device',
      environment: Environment.development,
      consentManager: consentManager,
      appVersion: 'dev',
      buildNumber: 'debug',
    );
  }

  /// Create a testing context with minimal setup
  factory TrackingContext.testing({
    String? userId,
    String? sessionId,
  }) {
    final consentManager = ConsentManager();
    consentManager.grantAllConsents(version: 'test');

    return TrackingContext._(
      userId: userId,
      sessionId: sessionId,
      deviceId: 'test-device',
      environment: Environment.testing,
      consentManager: consentManager,
      appVersion: 'test',
      buildNumber: '0',
    );
  }

  // ========== GETTERS ==========

  /// Current user ID
  String? get userId => _userId;

  /// Current session ID
  String? get sessionId => _sessionId;

  /// Device identifier
  String? get deviceId => _deviceId;

  /// User properties
  Map<String, dynamic> get userProperties => Map.unmodifiable(_userProperties);

  /// Session properties
  Map<String, dynamic> get sessionProperties =>
      Map.unmodifiable(_sessionProperties);

  /// Consent manager
  ConsentManager get consentManager => _consentManager;

  /// Current environment
  Environment get environment => _environment;

  /// App version
  String? get appVersion => _appVersion;

  /// Build number
  String? get buildNumber => _buildNumber;

  /// When this context was created
  DateTime get createdAt => _createdAt;

  /// Whether we're in debug mode
  bool get isDebugMode => _environment == Environment.development;

  /// Whether we're in production
  bool get isProduction => _environment == Environment.production;

  /// Whether we're in testing
  bool get isTesting => _environment == Environment.testing;

  // ========== USER MANAGEMENT ==========

  /// Create a new context with updated user ID
  TrackingContext withUserId(String? userId) {
    return TrackingContext._(
      userId: userId,
      sessionId: _sessionId,
      deviceId: _deviceId,
      userProperties: Map.from(_userProperties),
      sessionProperties: Map.from(_sessionProperties),
      consentManager: _consentManager,
      environment: _environment,
      appVersion: _appVersion,
      buildNumber: _buildNumber,
    );
  }

  /// Create a new context with updated session ID
  TrackingContext withSessionId(String? sessionId) {
    return TrackingContext._(
      userId: _userId,
      sessionId: sessionId,
      deviceId: _deviceId,
      userProperties: Map.from(_userProperties),
      sessionProperties: Map.from(_sessionProperties),
      consentManager: _consentManager,
      environment: _environment,
      appVersion: _appVersion,
      buildNumber: _buildNumber,
    );
  }

  /// Create a new context with updated user properties
  TrackingContext withUserProperties(Map<String, dynamic> properties) {
    final updatedProperties = Map<String, dynamic>.from(_userProperties);
    updatedProperties.addAll(properties);

    return TrackingContext._(
      userId: _userId,
      sessionId: _sessionId,
      deviceId: _deviceId,
      userProperties: updatedProperties,
      sessionProperties: Map.from(_sessionProperties),
      consentManager: _consentManager,
      environment: _environment,
      appVersion: _appVersion,
      buildNumber: _buildNumber,
    );
  }

  /// Create a new context with updated session properties
  TrackingContext withSessionProperties(Map<String, dynamic> properties) {
    final updatedProperties = Map<String, dynamic>.from(_sessionProperties);
    updatedProperties.addAll(properties);

    return TrackingContext._(
      userId: _userId,
      sessionId: _sessionId,
      deviceId: _deviceId,
      userProperties: Map.from(_userProperties),
      sessionProperties: updatedProperties,
      consentManager: _consentManager,
      environment: _environment,
      appVersion: _appVersion,
      buildNumber: _buildNumber,
    );
  }

  /// Create a new context with updated environment
  TrackingContext withEnvironment(Environment environment) {
    return TrackingContext._(
      userId: _userId,
      sessionId: _sessionId,
      deviceId: _deviceId,
      userProperties: Map.from(_userProperties),
      sessionProperties: Map.from(_sessionProperties),
      consentManager: _consentManager,
      environment: environment,
      appVersion: _appVersion,
      buildNumber: _buildNumber,
    );
  }

  // ========== CONVENIENCE METHODS ==========

  /// Get user property by key
  T? getUserProperty<T>(String key) {
    final value = _userProperties[key];
    return value is T ? value : null;
  }

  /// Get session property by key
  T? getSessionProperty<T>(String key) {
    final value = _sessionProperties[key];
    return value is T ? value : null;
  }

  /// Check if user is identified
  bool get isUserIdentified => _userId != null && _userId!.isNotEmpty;

  /// Check if session is active
  bool get hasActiveSession => _sessionId != null && _sessionId!.isNotEmpty;

  /// Get context properties that should be added to events
  Map<String, dynamic> getContextProperties() {
    final properties = <String, dynamic>{};

    if (_userId != null) properties['user_id'] = _userId;
    if (_sessionId != null) properties['session_id'] = _sessionId;
    if (_deviceId != null) properties['device_id'] = _deviceId;
    if (_appVersion != null) properties['app_version'] = _appVersion;
    if (_buildNumber != null) properties['build_number'] = _buildNumber;

    properties['environment'] = _environment.name;
    properties['context_created_at'] = _createdAt.toIso8601String();

    return properties;
  }

  // ========== SERIALIZATION ==========

  /// Convert to map for storage/debugging
  Map<String, dynamic> toMap() {
    return {
      'userId': _userId,
      'sessionId': _sessionId,
      'deviceId': _deviceId,
      'userProperties': _userProperties,
      'sessionProperties': _sessionProperties,
      'consent': _consentManager.toMap(),
      'environment': _environment.name,
      'appVersion': _appVersion,
      'buildNumber': _buildNumber,
      'createdAt': _createdAt.toIso8601String(),
      'isUserIdentified': isUserIdentified,
      'hasActiveSession': hasActiveSession,
    };
  }

  /// Create from map (e.g., from storage)
  static TrackingContext fromMap(Map<String, dynamic> data) {
    final consentManager = ConsentManager();
    if (data['consent'] != null) {
      consentManager.loadFromMap(data['consent']);
    }

    final environmentName = data['environment'] as String? ?? 'production';
    final environment = Environment.values.firstWhere(
      (e) => e.name == environmentName,
      orElse: () => Environment.production,
    );

    return TrackingContext._(
      userId: data['userId'],
      sessionId: data['sessionId'],
      deviceId: data['deviceId'],
      userProperties: Map<String, dynamic>.from(data['userProperties'] ?? {}),
      sessionProperties:
          Map<String, dynamic>.from(data['sessionProperties'] ?? {}),
      consentManager: consentManager,
      environment: environment,
      appVersion: data['appVersion'],
      buildNumber: data['buildNumber'],
    );
  }

  /// Validate the context configuration
  List<String> validate() {
    final issues = <String>[];

    // Validate consent
    issues.addAll(_consentManager.validate());

    // Validate user identification in production
    if (_environment == Environment.production && !isUserIdentified) {
      issues.add(
          'User not identified in production environment - consider privacy implications');
    }

    // Validate session in production
    if (_environment == Environment.production && !hasActiveSession) {
      issues.add(
          'No active session in production - session tracking recommended');
    }

    // Validate app version
    if (_environment == Environment.production && _appVersion == null) {
      issues.add('App version not set - recommended for production tracking');
    }

    return issues;
  }

  @override
  String toString() {
    return 'TrackingContext('
        'user: ${isUserIdentified ? _userId : 'anonymous'}, '
        'session: ${hasActiveSession ? _sessionId : 'none'}, '
        'environment: ${_environment.name}'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingContext &&
          other._userId == _userId &&
          other._sessionId == _sessionId &&
          other._deviceId == _deviceId &&
          other._environment == _environment;

  @override
  int get hashCode => Object.hash(_userId, _sessionId, _deviceId, _environment);
}

/// Application environment types
enum Environment {
  development,
  testing,
  staging,
  production,
}

/// Extension to provide convenient environment checks
extension EnvironmentExtension on Environment {
  /// Whether this is a development environment
  bool get isDevelopment => this == Environment.development;

  /// Whether this is a testing environment
  bool get isTesting => this == Environment.testing;

  /// Whether this is a staging environment
  bool get isStaging => this == Environment.staging;

  /// Whether this is a production environment
  bool get isProduction => this == Environment.production;

  /// Whether debug features should be enabled
  bool get enableDebug =>
      this == Environment.development || this == Environment.testing;

  /// Whether sampling should be applied
  bool get enableSampling =>
      this == Environment.production || this == Environment.staging;

  /// Whether consent is strictly required
  bool get strictConsent => this == Environment.production;
}
