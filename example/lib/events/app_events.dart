import 'package:flex_track/flex_track.dart';

/// App startup event
class AppStartEvent extends BaseEvent {
  final String appVersion;
  final String buildNumber;
  final String platform;

  AppStartEvent({
    String? appVersion,
    String? buildNumber,
    String? platform,
  })  : appVersion = appVersion ?? '1.0.0',
        buildNumber = buildNumber ?? '1',
        platform = platform ?? 'unknown';

  @override
  String get name => 'app_start';

  @override
  Map<String, Object> get properties => {
        'app_version': appVersion,
        'build_number': buildNumber,
        'platform': platform,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.system;

  @override
  bool get isEssential => true;

  @override
  bool get requiresConsent => false; // System event
}

/// Page view event
class PageViewEvent extends BaseEvent {
  final String pageName;
  final Map<String, String>? parameters;
  @override
  final DateTime timestamp;

  PageViewEvent({
    required this.pageName,
    this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String get name => 'page_view';

  @override
  Map<String, Object> get properties => {
        'page_name': pageName,
        if (parameters != null) 'parameters': parameters!,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.user;

  @override
  bool get isHighVolume => true; // Frequent navigation
}

/// Button click event
class ButtonClickEvent extends BaseEvent {
  final String buttonId;
  final String buttonText;
  final String? screenName;

  ButtonClickEvent({
    required this.buttonId,
    required this.buttonText,
    this.screenName,
  });

  @override
  String get name => 'button_click';

  @override
  Map<String, Object> get properties => {
        'button_id': buttonId,
        'button_text': buttonText,
        if (screenName != null) 'screen_name': screenName!,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.user;

  @override
  bool get isHighVolume => true; // Many clicks per session
}

/// Error event
class ErrorEvent extends BaseEvent {
  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final String? context;

  ErrorEvent({
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    this.context,
  });

  @override
  String get name => 'error';

  @override
  Map<String, Object> get properties => {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace!,
        if (context != null) 'context': context!,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.technical;

  @override
  bool get isEssential => true; // Important for debugging

  @override
  bool get requiresConsent => false; // Legitimate interest
}

/// Performance event
class PerformanceEvent extends BaseEvent {
  final String metricName;
  final double value;
  final String unit;
  final String? context;

  PerformanceEvent({
    required this.metricName,
    required this.value,
    required this.unit,
    this.context,
  });

  @override
  String get name => 'performance_metric';

  @override
  Map<String, Object> get properties => {
        'metric_name': metricName,
        'value': value,
        'unit': unit,
        if (context != null) 'context': context!,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.technical;

  @override
  bool get requiresConsent => false; // System performance data
}
