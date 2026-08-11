import 'package:flex_track/flex_track.dart';

/// E-commerce purchase event
class PurchaseEvent extends BaseEvent {
  final String productId;
  final String productName;
  final double amount;
  final String currency;
  final int quantity;
  final String? couponCode;
  final String paymentMethod;

  PurchaseEvent({
    required this.productId,
    required this.productName,
    required this.amount,
    required this.currency,
    this.quantity = 1,
    this.couponCode,
    required this.paymentMethod,
  });

  @override
  String get name => 'purchase';

  @override
  Map<String, Object> get properties => {
        'product_id': productId,
        'product_name': productName,
        'amount': amount,
        'currency': currency,
        'quantity': quantity,
        if (couponCode != null) 'coupon_code': couponCode!,
        'payment_method': paymentMethod,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.business;

  @override
  bool get isEssential => true; // Critical for revenue tracking

  @override
  bool get containsPII => false; // No personal data
}

/// Cart abandonment event
class CartAbandonmentEvent extends BaseEvent {
  final List<String> productIds;
  final double totalValue;
  final String currency;
  final int itemCount;
  final String abandonmentStage; // 'cart', 'checkout', 'payment'

  CartAbandonmentEvent({
    required this.productIds,
    required this.totalValue,
    required this.currency,
    required this.itemCount,
    required this.abandonmentStage,
  });

  @override
  String get name => 'cart_abandonment';

  @override
  Map<String, Object> get properties => {
        'product_ids': productIds,
        'total_value': totalValue,
        'currency': currency,
        'item_count': itemCount,
        'abandonment_stage': abandonmentStage,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.business;

  @override
  bool get isHighVolume => true; // Many users abandon carts
}

/// Add to cart event
class AddToCartEvent extends BaseEvent {
  final String productId;
  final String productName;
  final double price;
  final String currency;
  final int quantity;

  AddToCartEvent({
    required this.productId,
    required this.productName,
    required this.price,
    required this.currency,
    this.quantity = 1,
  });

  @override
  String get name => 'add_to_cart';

  @override
  Map<String, Object> get properties => {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'currency': currency,
        'quantity': quantity,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.business;
}

/// Subscription event
class SubscriptionEvent extends BaseEvent {
  final String planId;
  final String planName;
  final double price;
  final String currency;
  final String billingCycle; // 'monthly', 'yearly'
  final String action; // 'subscribe', 'upgrade', 'downgrade', 'cancel'

  SubscriptionEvent({
    required this.planId,
    required this.planName,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.action,
  });

  @override
  String get name => 'subscription_$action';

  @override
  Map<String, Object> get properties => {
        'plan_id': planId,
        'plan_name': planName,
        'price': price,
        'currency': currency,
        'billing_cycle': billingCycle,
        'action': action,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.business;

  @override
  bool get isEssential => true;
}
