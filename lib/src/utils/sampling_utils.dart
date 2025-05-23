import 'dart:math' as math;

/// Utility class for event sampling operations
class SamplingUtils {
  static final math.Random _random = math.Random();
  static int _seed = DateTime.now().millisecondsSinceEpoch;

  /// Check if an event should be sampled based on sample rate
  static bool shouldSample(double sampleRate) {
    if (sampleRate >= 1.0) return true;
    if (sampleRate <= 0.0) return false;

    return _random.nextDouble() < sampleRate;
  }

  /// Check if an event should be sampled using deterministic sampling
  /// This ensures consistent sampling for the same input
  static bool shouldSampleDeterministic(String input, double sampleRate) {
    if (sampleRate >= 1.0) return true;
    if (sampleRate <= 0.0) return false;

    // Use hash of input for deterministic sampling
    final hash = input.hashCode.abs();
    final normalizedHash = (hash % 10000) / 10000.0;

    return normalizedHash < sampleRate;
  }

  /// Check if an event should be sampled based on user ID
  /// Ensures consistent sampling per user
  static bool shouldSampleByUserId(String? userId, double sampleRate) {
    if (userId == null || userId.isEmpty) {
      return shouldSample(sampleRate);
    }

    return shouldSampleDeterministic(userId, sampleRate);
  }

  /// Check if an event should be sampled based on session ID
  /// Ensures consistent sampling per session
  static bool shouldSampleBySessionId(String? sessionId, double sampleRate) {
    if (sessionId == null || sessionId.isEmpty) {
      return shouldSample(sampleRate);
    }

    return shouldSampleDeterministic(sessionId, sampleRate);
  }

  /// Sample events based on event name hash
  /// Useful for sampling specific event types consistently
  static bool shouldSampleByEventName(String eventName, double sampleRate) {
    return shouldSampleDeterministic(eventName, sampleRate);
  }

  /// Sample events using time-based sampling
  /// Useful for periodic sampling or rate limiting
  static bool shouldSampleByTime(Duration interval) {
    final now = DateTime.now();
    final millisSinceEpoch = now.millisecondsSinceEpoch;
    final intervalMs = interval.inMilliseconds;

    if (intervalMs <= 0) return true;

    return (millisSinceEpoch % intervalMs) == 0;
  }

  /// Sample events with exponential backoff
  /// Reduces sampling rate over time for repeated events
  static bool shouldSampleWithBackoff(int eventCount, double baseSampleRate,
      {double backoffFactor = 0.5}) {
    if (eventCount <= 0) return shouldSample(baseSampleRate);

    // Reduce sample rate exponentially based on event count
    final adjustedRate =
        baseSampleRate * math.pow(backoffFactor, eventCount - 1);
    return shouldSample(adjustedRate.clamp(0.0, 1.0));
  }

  /// Sample events with reservoir sampling
  /// Maintains a fixed-size sample of events
  static bool shouldIncludeInReservoir(int currentCount, int reservoirSize) {
    if (currentCount <= reservoirSize) return true;

    // Probability decreases as more events are seen
    final probability = reservoirSize / currentCount;
    return _random.nextDouble() < probability;
  }

  /// Calculate adaptive sampling rate based on event volume
  /// Automatically adjusts sampling rate based on event frequency
  static double calculateAdaptiveSamplingRate(
    int eventCount,
    Duration timeWindow,
    int targetEventsPerWindow,
  ) {
    if (eventCount <= targetEventsPerWindow) return 1.0;

    // Reduce sampling rate proportionally to excess events
    return (targetEventsPerWindow / eventCount).clamp(0.001, 1.0);
  }

  /// Sample events using weighted probability
  /// Different events can have different sampling weights
  static bool shouldSampleWeighted(
      Map<String, double> weights, String eventType) {
    final weight = weights[eventType] ?? 1.0;
    return shouldSample(weight);
  }

  /// Create sampling buckets for A/B testing
  /// Consistently assigns events to buckets for testing
  static int getSamplingBucket(String identifier, int bucketCount) {
    if (bucketCount <= 0) return 0;

    final hash = identifier.hashCode.abs();
    return hash % bucketCount;
  }

  /// Check if event should be sampled for A/B test bucket
  static bool shouldSampleForBucket(
      String identifier, int bucketCount, List<int> targetBuckets) {
    final bucket = getSamplingBucket(identifier, bucketCount);
    return targetBuckets.contains(bucket);
  }

  /// Set seed for reproducible sampling (useful for testing)
  static void setSeed(int seed) {
    _seed = seed;
    // Note: dart:math Random doesn't support setting seed on existing instance
    // In a real implementation, you might need to create a new Random instance
  }

  /// Get current seed
  static int getSeed() => _seed;

  /// Reset to random seed
  static void resetSeed() {
    _seed = DateTime.now().millisecondsSinceEpoch;
  }

  /// Validate sample rate
  static SampleRateValidationResult validateSampleRate(double sampleRate) {
    if (sampleRate < 0.0) {
      return SampleRateValidationResult.invalid(
          'Sample rate cannot be negative: $sampleRate');
    }

    if (sampleRate > 1.0) {
      return SampleRateValidationResult.invalid(
          'Sample rate cannot exceed 1.0: $sampleRate');
    }

    return SampleRateValidationResult.valid();
  }

  /// Convert percentage to sample rate
  static double percentageToSampleRate(double percentage) {
    return (percentage / 100.0).clamp(0.0, 1.0);
  }

  /// Convert sample rate to percentage
  static double sampleRateToPercentage(double sampleRate) {
    return (sampleRate * 100.0).clamp(0.0, 100.0);
  }

  /// Get sampling statistics
  static SamplingStats calculateStats(List<bool> samplingResults) {
    if (samplingResults.isEmpty) {
      return SamplingStats(
        totalEvents: 0,
        sampledEvents: 0,
        actualSampleRate: 0.0,
      );
    }

    final sampledCount = samplingResults.where((sampled) => sampled).length;
    final actualRate = sampledCount / samplingResults.length;

    return SamplingStats(
      totalEvents: samplingResults.length,
      sampledEvents: sampledCount,
      actualSampleRate: actualRate,
    );
  }

  /// Create a sampling strategy based on configuration
  static SamplingStrategy createStrategy(SamplingConfig config) {
    return SamplingStrategy(config);
  }
}

/// Sampling strategy that encapsulates sampling logic
class SamplingStrategy {
  final SamplingConfig config;
  final Map<String, int> _eventCounts = {};
  final Map<String, DateTime> _lastSampleTimes = {};

  SamplingStrategy(this.config);

  /// Check if event should be sampled based on strategy
  bool shouldSample(String eventName, {String? userId, String? sessionId}) {
    switch (config.type) {
      case SamplingType.random:
        return SamplingUtils.shouldSample(config.sampleRate);

      case SamplingType.deterministic:
        final key = userId ?? sessionId ?? eventName;
        return SamplingUtils.shouldSampleDeterministic(key, config.sampleRate);

      case SamplingType.timeBased:
        if (config.timeInterval == null) return false;
        return SamplingUtils.shouldSampleByTime(config.timeInterval!);

      case SamplingType.adaptive:
        return _shouldSampleAdaptive(eventName);

      case SamplingType.backoff:
        return _shouldSampleWithBackoff(eventName);
    }
  }

  bool _shouldSampleAdaptive(String eventName) {
    final now = DateTime.now();
    final windowStart =
        now.subtract(config.timeWindow ?? const Duration(minutes: 1));

    // Reset counts if outside time window
    final lastTime = _lastSampleTimes[eventName];
    if (lastTime == null || lastTime.isBefore(windowStart)) {
      _eventCounts[eventName] = 0;
    }

    final count = _eventCounts[eventName] ?? 0;
    _eventCounts[eventName] = count + 1;
    _lastSampleTimes[eventName] = now;

    final adaptiveRate = SamplingUtils.calculateAdaptiveSamplingRate(
      count,
      config.timeWindow ?? const Duration(minutes: 1),
      config.targetEventsPerWindow ?? 100,
    );

    return SamplingUtils.shouldSample(adaptiveRate);
  }

  bool _shouldSampleWithBackoff(String eventName) {
    final count = _eventCounts[eventName] ?? 0;
    _eventCounts[eventName] = count + 1;

    return SamplingUtils.shouldSampleWithBackoff(
      count,
      config.sampleRate,
      backoffFactor: config.backoffFactor ?? 0.5,
    );
  }

  /// Reset strategy state
  void reset() {
    _eventCounts.clear();
    _lastSampleTimes.clear();
  }
}

/// Sampling configuration
class SamplingConfig {
  final SamplingType type;
  final double sampleRate;
  final Duration? timeInterval;
  final Duration? timeWindow;
  final int? targetEventsPerWindow;
  final double? backoffFactor;

  const SamplingConfig({
    required this.type,
    required this.sampleRate,
    this.timeInterval,
    this.timeWindow,
    this.targetEventsPerWindow,
    this.backoffFactor,
  });

  factory SamplingConfig.random(double sampleRate) {
    return SamplingConfig(type: SamplingType.random, sampleRate: sampleRate);
  }

  factory SamplingConfig.deterministic(double sampleRate) {
    return SamplingConfig(
        type: SamplingType.deterministic, sampleRate: sampleRate);
  }

  factory SamplingConfig.timeBased(Duration interval) {
    return SamplingConfig(
        type: SamplingType.timeBased, sampleRate: 1.0, timeInterval: interval);
  }

  factory SamplingConfig.adaptive({
    required Duration timeWindow,
    required int targetEventsPerWindow,
  }) {
    return SamplingConfig(
      type: SamplingType.adaptive,
      sampleRate: 1.0,
      timeWindow: timeWindow,
      targetEventsPerWindow: targetEventsPerWindow,
    );
  }

  factory SamplingConfig.backoff(double baseSampleRate,
      {double backoffFactor = 0.5}) {
    return SamplingConfig(
      type: SamplingType.backoff,
      sampleRate: baseSampleRate,
      backoffFactor: backoffFactor,
    );
  }
}

/// Types of sampling strategies
enum SamplingType {
  random,
  deterministic,
  timeBased,
  adaptive,
  backoff,
}

/// Sample rate validation result
class SampleRateValidationResult {
  final bool isValid;
  final String? error;

  const SampleRateValidationResult._(this.isValid, this.error);

  factory SampleRateValidationResult.valid() {
    return const SampleRateValidationResult._(true, null);
  }

  factory SampleRateValidationResult.invalid(String error) {
    return SampleRateValidationResult._(false, error);
  }

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $error';
}

/// Sampling statistics
class SamplingStats {
  final int totalEvents;
  final int sampledEvents;
  final double actualSampleRate;

  const SamplingStats({
    required this.totalEvents,
    required this.sampledEvents,
    required this.actualSampleRate,
  });

  int get droppedEvents => totalEvents - sampledEvents;
  double get dropRate => 1.0 - actualSampleRate;

  Map<String, dynamic> toMap() {
    return {
      'totalEvents': totalEvents,
      'sampledEvents': sampledEvents,
      'droppedEvents': droppedEvents,
      'actualSampleRate': actualSampleRate,
      'dropRate': dropRate,
    };
  }

  @override
  String toString() {
    return 'SamplingStats(${(actualSampleRate * 100).toStringAsFixed(1)}% of $totalEvents events)';
  }
}
