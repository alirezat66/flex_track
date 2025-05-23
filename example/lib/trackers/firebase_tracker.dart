import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flex_track/flex_track.dart';

/// Firebase Analytics implementation of TrackerStrategy
class FirebaseTracker extends BaseTrackerStrategy {
  final FirebaseAnalytics analytics;

  FirebaseTracker({
    required this.analytics,
    super.enabled = true,
  });

  @override
  Future<void> doInitialize() async {
    // Firebase Analytics doesn't require explicit initialization
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    if (event is PurchaseEvent) {
      await analytics.logPurchase(
        currency: event.currency,
        value: event.amount,
        items: [
          AnalyticsEventItem(
            itemId: event.productId,
            itemName: 'Premium Subscription',
            price: event.amount,
          ),
        ],
      );
    } else {
      await analytics.logEvent(
        name: event.getName(),
        parameters: event.getProperties(),
      );
    }
  }
}
