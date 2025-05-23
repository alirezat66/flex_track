import '../strategies/tracker_strategy.dart';
import '../exceptions/tracker_exception.dart';
import '../exceptions/configuration_exception.dart';

/// Registry that manages all registered tracker strategies
class TrackerRegistry {
  final Map<String, TrackerStrategy> _trackers = {};
  final Map<String, bool> _initializationStatus = {};
  bool _isInitialized = false;

  /// Returns true if the registry has been initialized
  bool get isInitialized => _isInitialized;

  /// Returns all registered tracker IDs
  Set<String> get registeredTrackerIds => _trackers.keys.toSet();

  /// Returns all registered trackers
  List<TrackerStrategy> get registeredTrackers => _trackers.values.toList();

  /// Returns the number of registered trackers
  int get count => _trackers.length;

  /// Register a single tracker strategy
  void register(TrackerStrategy tracker) {
    if (_isInitialized) {
      throw TrackerException(
        'Cannot register trackers after initialization',
        trackerId: tracker.id,
        code: 'ALREADY_INITIALIZED',
      );
    }

    if (_trackers.containsKey(tracker.id)) {
      throw TrackerException(
        'Tracker with ID "${tracker.id}" is already registered',
        trackerId: tracker.id,
        code: 'DUPLICATE_ID',
      );
    }

    if (tracker.id.isEmpty) {
      throw ConfigurationException(
        'Tracker ID cannot be empty',
        fieldName: 'id',
      );
    }

    _trackers[tracker.id] = tracker;
    _initializationStatus[tracker.id] = false;
  }

  /// Register multiple tracker strategies
  void registerAll(List<TrackerStrategy> trackers) {
    for (final tracker in trackers) {
      register(tracker);
    }
  }

  /// Unregister a tracker by ID
  bool unregister(String trackerId) {
    if (_isInitialized) {
      throw TrackerException(
        'Cannot unregister trackers after initialization',
        trackerId: trackerId,
        code: 'ALREADY_INITIALIZED',
      );
    }

    final removed = _trackers.remove(trackerId) != null;
    _initializationStatus.remove(trackerId);
    return removed;
  }

  /// Get a tracker by ID
  TrackerStrategy? get(String trackerId) {
    return _trackers[trackerId];
  }

  /// Get multiple trackers by IDs
  List<TrackerStrategy> getMultiple(List<String> trackerIds) {
    final result = <TrackerStrategy>[];
    for (final id in trackerIds) {
      final tracker = _trackers[id];
      if (tracker != null) {
        result.add(tracker);
      }
    }
    return result;
  }

  /// Check if a tracker is registered
  bool contains(String trackerId) {
    return _trackers.containsKey(trackerId);
  }

  /// Check if a tracker is enabled
  bool isEnabled(String trackerId) {
    final tracker = _trackers[trackerId];
    return tracker?.isEnabled ?? false;
  }

  /// Check if a tracker is initialized
  bool isTrackerInitialized(String trackerId) {
    return _initializationStatus[trackerId] ?? false;
  }

  /// Initialize all registered trackers
  Future<void> initialize() async {
    if (_isInitialized) {
      return; // Already initialized
    }

    final failures = <String, Exception>{};

    // Initialize each tracker
    for (final entry in _trackers.entries) {
      final trackerId = entry.key;
      final tracker = entry.value;

      try {
        await tracker.initialize();
        _initializationStatus[trackerId] = true;
      } catch (e) {
        _initializationStatus[trackerId] = false;
        failures[trackerId] = e is Exception ? e : Exception(e.toString());
      }
    }

    _isInitialized = true;

    // Report any failures
    if (failures.isNotEmpty) {
      final failureMessage =
          failures.entries.map((e) => '${e.key}: ${e.value}').join(', ');

      throw TrackerException(
        'Failed to initialize ${failures.length} tracker(s): $failureMessage',
        code: 'INITIALIZATION_FAILURES',
      );
    }
  }

  /// Enable a tracker
  void enable(String trackerId) {
    final tracker = _trackers[trackerId];
    if (tracker == null) {
      throw TrackerException(
        'Tracker not found: $trackerId',
        trackerId: trackerId,
        code: 'NOT_FOUND',
      );
    }
    tracker.enable();
  }

  /// Disable a tracker
  void disable(String trackerId) {
    final tracker = _trackers[trackerId];
    if (tracker == null) {
      throw TrackerException(
        'Tracker not found: $trackerId',
        trackerId: trackerId,
        code: 'NOT_FOUND',
      );
    }
    tracker.disable();
  }

  /// Enable all trackers
  void enableAll() {
    for (final tracker in _trackers.values) {
      tracker.enable();
    }
  }

  /// Disable all trackers
  void disableAll() {
    for (final tracker in _trackers.values) {
      tracker.disable();
    }
  }

  /// Set user properties for all trackers
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    final futures = <Future>[];

    for (final tracker in _trackers.values) {
      if (tracker.isEnabled) {
        futures.add(tracker.setUserProperties(properties));
      }
    }

    await Future.wait(futures);
  }

  /// Identify user for all trackers
  Future<void> identifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    final futures = <Future>[];

    for (final tracker in _trackers.values) {
      if (tracker.isEnabled) {
        futures.add(tracker.identifyUser(userId, properties));
      }
    }

    await Future.wait(futures);
  }

  /// Reset all trackers
  Future<void> reset() async {
    final futures = <Future>[];

    for (final tracker in _trackers.values) {
      if (tracker.isEnabled) {
        futures.add(tracker.reset());
      }
    }

    await Future.wait(futures);
  }

  /// Flush all trackers
  Future<void> flush() async {
    final futures = <Future>[];

    for (final tracker in _trackers.values) {
      if (tracker.isEnabled) {
        futures.add(tracker.flush());
      }
    }

    await Future.wait(futures);
  }

  /// Clear all registered trackers (only if not initialized)
  void clear() {
    if (_isInitialized) {
      throw TrackerException(
        'Cannot clear trackers after initialization',
        code: 'ALREADY_INITIALIZED',
      );
    }

    _trackers.clear();
    _initializationStatus.clear();
  }

  /// Get debug information about all trackers
  Map<String, dynamic> getDebugInfo() {
    final trackerInfo = <String, Map<String, dynamic>>{};

    for (final entry in _trackers.entries) {
      final trackerId = entry.key;
      final tracker = entry.value;

      trackerInfo[trackerId] = {
        ...tracker.getDebugInfo(),
        'initialized': _initializationStatus[trackerId] ?? false,
      };
    }

    return {
      'isInitialized': _isInitialized,
      'trackerCount': _trackers.length,
      'enabledTrackers': _trackers.values.where((t) => t.isEnabled).length,
      'initializedTrackers':
          _initializationStatus.values.where((status) => status).length,
      'trackers': trackerInfo,
    };
  }

  /// Validate the registry configuration
  List<String> validate() {
    final issues = <String>[];

    if (_trackers.isEmpty) {
      issues.add('No trackers registered');
    }

    // Check for duplicate tracker names (not IDs)
    final names = _trackers.values.map((t) => t.name).toList();
    final duplicateNames = <String>[];
    final seenNames = <String>{};

    for (final name in names) {
      if (seenNames.contains(name)) {
        duplicateNames.add(name);
      } else {
        seenNames.add(name);
      }
    }

    if (duplicateNames.isNotEmpty) {
      issues.add('Duplicate tracker names found: ${duplicateNames.join(', ')}');
    }

    // Check for trackers with empty or invalid IDs
    for (final tracker in _trackers.values) {
      if (tracker.id.isEmpty) {
        issues.add('Tracker has empty ID: ${tracker.name}');
      }

      if (tracker.name.isEmpty) {
        issues.add('Tracker has empty name: ${tracker.id}');
      }
    }

    return issues;
  }

  @override
  String toString() {
    return 'TrackerRegistry(${_trackers.length} trackers, initialized: $_isInitialized)';
  }
}
