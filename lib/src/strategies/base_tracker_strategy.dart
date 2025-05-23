import 'package:flex_track/src/models/event/base_event.dart';

import '../exceptions/tracker_exception.dart';
import 'tracker_strategy.dart';

/// Base implementation of TrackerStrategy with common functionality
abstract class BaseTrackerStrategy implements TrackerStrategy {
  final String _id;
  final String _name;
  bool _enabled;
  bool _initialized = false;

  BaseTrackerStrategy({
    required String id,
    required String name,
    bool enabled = true,
  })  : _id = id,
        _name = name,
        _enabled = enabled;

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  bool get isEnabled => _enabled && _initialized;

  @override
  bool get isGDPRCompliant => false;

  @override
  bool get supportsRealTime => true;

  @override
  int get maxBatchSize => 100;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await doInitialize();
      _initialized = true;
    } catch (e) {
      throw TrackerException(
        'Failed to initialize tracker $_id: $e',
        trackerId: _id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> track(BaseEvent event) async {
    if (!_initialized) {
      throw TrackerException(
        'Tracker $_id is not initialized. Call initialize() first.',
        trackerId: _id,
      );
    }
    if (!isEnabled) return;

    try {
      await doTrack(event);
    } catch (e) {
      throw TrackerException(
        'Failed to track event ${event.getName()} with tracker $_id: $e',
        trackerId: _id,
        eventName: event.getName(),
        originalError: e,
      );
    }
  }

  @override
  Future<void> trackBatch(List<BaseEvent> events) async {
    if (!_initialized) {
      throw TrackerException(
        'Tracker $_id is not initialized. Call initialize() first.',
        trackerId: _id,
      );
    }
    if (!isEnabled || events.isEmpty) return;

    try {
      // Check if tracker supports custom batch implementation
      if (supportsBatchTracking()) {
        await doTrackBatch(events);
      } else {
        // Fall back to individual tracking (default implementation)
        for (final event in events) {
          await track(event);
        }
      }
    } catch (e) {
      throw TrackerException(
        'Failed to track batch of ${events.length} events with tracker $_id: $e',
        trackerId: _id,
        originalError: e,
      );
    }
  }

  @override
  void enable() {
    _enabled = true;
  }

  @override
  void disable() {
    _enabled = false;
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!isEnabled) return;

    try {
      await doSetUserProperties(properties);
    } catch (e) {
      throw TrackerException(
        'Failed to set user properties for tracker $_id: $e',
        trackerId: _id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> identifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    if (!isEnabled) return;

    try {
      await doIdentifyUser(userId, properties);
    } catch (e) {
      throw TrackerException(
        'Failed to identify user for tracker $_id: $e',
        trackerId: _id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> reset() async {
    if (!isEnabled) return;

    try {
      await doReset();
    } catch (e) {
      throw TrackerException(
        'Failed to reset tracker $_id: $e',
        trackerId: _id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> flush() async {
    if (!isEnabled) return;

    try {
      await doFlush();
    } catch (e) {
      throw TrackerException(
        'Failed to flush tracker $_id: $e',
        trackerId: _id,
        originalError: e,
      );
    }
  }

  @override
  Map<String, dynamic> getDebugInfo() {
    return {
      'id': id,
      'name': name,
      'enabled': _enabled,
      'initialized': _initialized,
      'gdprCompliant': isGDPRCompliant,
      'supportsRealTime': supportsRealTime,
      'maxBatchSize': maxBatchSize,
      'supportsBatchTracking': supportsBatchTracking(),
    };
  }

  // ============= ABSTRACT METHODS TO IMPLEMENT =============

  /// Implement this method to perform the actual initialization
  /// Called once during tracker setup
  Future<void> doInitialize();

  /// Implement this method to perform the actual event tracking
  /// Called for each event that needs to be tracked
  Future<void> doTrack(BaseEvent event);

  // ============= OPTIONAL METHODS TO OVERRIDE =============

  /// Override this if the tracker supports efficient batch tracking
  /// Return true to enable custom batch implementation
  bool supportsBatchTracking() => false;

  /// Override this to implement custom batch tracking
  /// Only called if supportsBatchTracking() returns true
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    throw UnimplementedError('Batch tracking not implemented');
  }

  /// Override this to handle user property updates
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    // Default implementation does nothing
  }

  /// Override this to handle user identification
  Future<void> doIdentifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    // Default implementation does nothing
  }

  /// Override this to handle tracker reset
  Future<void> doReset() async {
    // Default implementation does nothing
  }

  /// Override this to handle flushing pending events
  Future<void> doFlush() async {
    // Default implementation does nothing
  }

  @override
  String toString() => 'TrackerStrategy($_id: $_name, enabled: $isEnabled)';
}
