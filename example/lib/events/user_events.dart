import 'package:flex_track/flex_track.dart';

/// User registration event
class UserRegistrationEvent extends BaseEvent {
  final String registrationMethod; // 'email', 'google', 'facebook', 'apple'
  final bool hasAcceptedTerms;
  final bool hasAcceptedMarketing;

  UserRegistrationEvent({
    required this.registrationMethod,
    required this.hasAcceptedTerms,
    this.hasAcceptedMarketing = false,
  });

  @override
  String getName() => 'user_registration';

  @override
  Map<String, Object> getProperties() => {
        'registration_method': registrationMethod,
        'accepted_terms': hasAcceptedTerms,
        'accepted_marketing': hasAcceptedMarketing,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.user;

  @override
  bool get isEssential => true; // Important conversion metric

  @override
  bool get containsPII => false; // No personal identifiers
}

/// User login event
class UserLoginEvent extends BaseEvent {
  final String loginMethod; // 'email', 'google', 'facebook', 'apple'
  final bool isFirstLogin;

  UserLoginEvent({
    required this.loginMethod,
    this.isFirstLogin = false,
  });

  @override
  String getName() => 'user_login';

  @override
  Map<String, Object> getProperties() => {
        'login_method': loginMethod,
        'is_first_login': isFirstLogin,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.user;

  @override
  bool get containsPII => false;
}

/// User profile update event
class UserProfileUpdateEvent extends BaseEvent {
  final List<String> updatedFields;
  final bool isComplete; // Profile completion status

  UserProfileUpdateEvent({
    required this.updatedFields,
    required this.isComplete,
  });

  @override
  String getName() => 'user_profile_update';

  @override
  Map<String, Object> getProperties() => {
        'updated_fields': updatedFields,
        'is_complete': isComplete,
        'field_count': updatedFields.length,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.user;

  @override
  bool get containsPII => true; // Profile updates may contain PII
}

/// Feature usage event
class FeatureUsageEvent extends BaseEvent {
  final String featureName;
  final String action; // 'start', 'complete', 'abandon'
  final int? duration; // in seconds
  final Map<String, String>? context;

  FeatureUsageEvent({
    required this.featureName,
    required this.action,
    this.duration,
    this.context,
  });

  @override
  String getName() => 'feature_usage';

  @override
  Map<String, Object> getProperties() => {
        'feature_name': featureName,
        'action': action,
        if (duration != null) 'duration_seconds': duration!,
        if (context != null) 'context': context!,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.user;

  @override
  bool get isHighVolume => true; // Users interact with features frequently
}

/// User engagement event
class UserEngagementEvent extends BaseEvent {
  final String
      engagementType; // 'session_start', 'session_end', 'deep_engagement'
  final int? sessionDuration; // in seconds
  final int? screenCount; // number of screens viewed
  final int? actionCount; // number of actions taken

  UserEngagementEvent({
    required this.engagementType,
    this.sessionDuration,
    this.screenCount,
    this.actionCount,
  });

  @override
  String getName() => 'user_engagement';

  @override
  Map<String, Object> getProperties() => {
        'engagement_type': engagementType,
        if (sessionDuration != null)
          'session_duration_seconds': sessionDuration!,
        if (screenCount != null) 'screen_count': screenCount!,
        if (actionCount != null) 'action_count': actionCount!,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.user;
}
