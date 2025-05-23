import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/routing/event_category.dart';

class CustomEvent extends BaseEvent {
  final String _name;
  final Map<String, dynamic>? _properties;
  final EventCategory? _category;
  final bool _containsPII;
  final bool _isHighVolume;
  final bool _isEssential;

  CustomEvent(this._name, {
    Map<String, dynamic>? properties,
    EventCategory? category,
    bool containsPII = false,
    bool isHighVolume = false,
    bool isEssential = false,
  }) : _properties = properties,
       _category = category,
       _containsPII = containsPII,
       _isHighVolume = isHighVolume,
       _isEssential = isEssential;

  factory CustomEvent.named(String name, {
    Map<String, dynamic>? properties,
    EventCategory? category,
    bool containsPII = false,
    bool isHighVolume = false,
    bool isEssential = false,
  }) {
    return CustomEvent(
      name,
      properties: properties,
      category: category,
      containsPII: containsPII,
      isHighVolume: isHighVolume,
      isEssential: isEssential,
    );
  }

  @override
  String getName() => _name;

  @override
  @override
  @override
  Map<String, Object>? getProperties() => _properties?.cast<String, Object>();

  @override
  EventCategory? get category => _category;

  @override
  bool get containsPII => _containsPII;

  @override
  bool get isHighVolume => _isHighVolume;

  @override
  bool get isEssential => _isEssential;
}

class PurchaseEvent extends CustomEvent {
  PurchaseEvent({
    required double amount,
    required String currency,
    Map<String, dynamic>? properties,
  }) : super(
    'purchase',
    properties: {
      ...?properties,
      'amount': amount,
      'currency': currency,
    },
    category: EventCategory.business,
    isEssential: true,
    containsPII: true,
  );
}