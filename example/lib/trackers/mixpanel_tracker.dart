import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:flex_track/flex_track.dart';

/// Mixpanel implementation of TrackerStrategy
class MixpanelTracker extends BaseTrackerStrategy {
  final Mixpanel mixpanel;

  MixpanelTracker({
    required this.mixpanel,
    super.enabled = true,
  });

  @override
  Future<void> doInitialize() async {
    // Mixpanel is initialized by the app
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    if (event is PurchaseEvent) {
      mixpanel.track(
        'Purchase',
        properties: {
          'product_id': event.productId,
          'amount': event.amount,
          'currency': event.currency,
        },
      );
    } else {
      mixpanel.track(
        event.getName(),
        properties: event.getProperties(),
      );
    }
  }
}
