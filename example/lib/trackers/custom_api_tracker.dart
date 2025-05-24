import 'dart:convert';
import 'dart:io';
import 'package:flex_track/flex_track.dart';
import 'package:flutter/foundation.dart';

/// Custom API tracker for internal analytics using dart:io HttpClient
class CustomAPITracker extends BaseTrackerStrategy {
  final String apiUrl;
  final String? apiKey;
  final List<BaseEvent> _eventBuffer = [];
  final int _maxBufferSize;
  late HttpClient _httpClient;

  CustomAPITracker({
    required this.apiUrl,
    this.apiKey,
    int maxBufferSize = 50,
  })  : _maxBufferSize = maxBufferSize,
        super(
          id: 'custom_api',
          name: 'Custom API Tracker',
        );

  @override
  bool get isGDPRCompliant => true; // Assuming your API is compliant

  @override
  bool get supportsRealTime => true;

  @override
  int get maxBatchSize => 100;

  @override
  Future<void> doInitialize() async {
    _httpClient = HttpClient();
    _httpClient.connectionTimeout = Duration(seconds: 10);

    // Test API connectivity
    try {
      final uri = Uri.parse('$apiUrl/health');
      final request = await _httpClient.getUrl(uri);
      _addHeaders(request);

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('API health check failed: ${response.statusCode}');
      }

      // Drain the response
      await response.drain();
    } catch (e) {
      throw TrackerException(
        'Failed to initialize Custom API tracker: $e',
        trackerId: id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    _eventBuffer.add(event);

    // Auto-flush when buffer is full
    if (_eventBuffer.length >= _maxBufferSize) {
      await doFlush();
    }
  }

  @override
  bool supportsBatchTracking() => true;

  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    _eventBuffer.addAll(events);

    if (_eventBuffer.length >= _maxBufferSize) {
      await doFlush();
    }
  }

  @override
  Future<void> doFlush() async {
    if (_eventBuffer.isEmpty) return;

    final eventsToSend = List<BaseEvent>.from(_eventBuffer);
    _eventBuffer.clear();

    try {
      final payload = {
        'events': eventsToSend
            .map((event) => {
                  'name': event.getName(),
                  'properties': event.getProperties(),
                  'timestamp': event.timestamp.toIso8601String(),
                  'category': event.category?.name,
                  'contains_pii': event.containsPII,
                  'is_essential': event.isEssential,
                })
            .toList(),
        'batch_timestamp': DateTime.now().toIso8601String(),
        'batch_size': eventsToSend.length,
      };

      final uri = Uri.parse('$apiUrl/events/batch');
      final request = await _httpClient.postUrl(uri);
      _addHeaders(request);

      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 201) {
        final responseBody = await response.transform(utf8.decoder).join();
        throw Exception('API returned ${response.statusCode}: $responseBody');
      }

      // Drain the response
      await response.drain();
    } catch (e) {
      // Re-add events to buffer on failure (simple retry logic)
      _eventBuffer.addAll(eventsToSend);

      throw TrackerException(
        'Failed to flush events to custom API: $e',
        trackerId: id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    try {
      final payload = {
        'properties': properties,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final uri = Uri.parse('$apiUrl/user/properties');
      final request = await _httpClient.postUrl(uri);
      _addHeaders(request);

      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 201) {
        final responseBody = await response.transform(utf8.decoder).join();
        throw Exception('API returned ${response.statusCode}: $responseBody');
      }

      // Drain the response
      await response.drain();
    } catch (e) {
      throw TrackerException(
        'Failed to set user properties: $e',
        trackerId: id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> doIdentifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    try {
      final payload = {
        'user_id': userId,
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      final uri = Uri.parse('$apiUrl/user/identify');
      final request = await _httpClient.postUrl(uri);
      _addHeaders(request);

      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 201) {
        final responseBody = await response.transform(utf8.decoder).join();
        throw Exception('API returned ${response.statusCode}: $responseBody');
      }

      // Drain the response
      await response.drain();
    } catch (e) {
      throw TrackerException(
        'Failed to identify user: $e',
        trackerId: id,
        originalError: e,
      );
    }
  }

  @override
  Future<void> doReset() async {
    _eventBuffer.clear();

    try {
      final uri = Uri.parse('$apiUrl/user/reset');
      final request = await _httpClient.postUrl(uri);
      _addHeaders(request);

      final response = await request.close();

      // Reset errors are not critical, just drain response
      await response.drain();
    } catch (e) {
      // Reset errors are not critical
      debugPrint('Warning: Failed to reset user on custom API: $e');
    }
  }

  void _addHeaders(HttpClientRequest request) {
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('User-Agent', 'FlexTrack-CustomTracker/1.0');

    if (apiKey != null) {
      request.headers.set('Authorization', 'Bearer $apiKey');
    }
  }

  @override
  Map<String, dynamic> getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      'apiUrl': apiUrl,
      'hasApiKey': apiKey != null,
      'bufferSize': _eventBuffer.length,
      'maxBufferSize': _maxBufferSize,
    };
  }

  /// Clean up HTTP client on disposal
  void dispose() {
    _httpClient.close();
  }
}
