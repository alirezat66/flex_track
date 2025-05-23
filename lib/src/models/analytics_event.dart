/// Abstract base class for all analytics events
abstract class BaseEvent {
  /// Returns the name of the event
  String getName();

  /// Returns the properties associated with the event
  Map<String, Object>? getProperties();
}

/// Generic implementation of BaseEvent for simple cases
class AnalyticsEvent implements BaseEvent {
  final String name;
  final Map<String, Object>? properties;

  const AnalyticsEvent({required this.name, this.properties = const {}});

  @override
  String getName() => name;

  @override
  Map<String, Object>? getProperties() => properties;
}

/// Specialized event for user login
class LoginEvent extends AnalyticsEvent {
  final String userId;
  final String method;
  final bool success;

  LoginEvent({
    required this.userId,
    required this.method,
    required this.success,
  }) : super(
          name: 'login',
          properties: {'user_id': userId, 'method': method, 'success': success},
        );
}

/// Specialized event for purchases
class PurchaseEvent extends AnalyticsEvent {
  final String productId;
  final double amount;
  final String currency;
  final Map<String, dynamic>? additionalProperties;

  PurchaseEvent({
    required this.productId,
    required this.amount,
    required this.currency,
    this.additionalProperties,
  }) : super(
          name: 'purchase',
          properties: {
            'product_id': productId,
            'amount': amount,
            'currency': currency,
            if (additionalProperties != null) ...additionalProperties,
          },
        );
}

/// Custom event type for flexible event tracking
class CustomEvent extends AnalyticsEvent {
  CustomEvent({required super.name, required super.properties});
}
