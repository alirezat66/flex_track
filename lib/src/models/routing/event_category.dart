/// Represents a category of events for routing and organization
class EventCategory {
  final String name;
  final String? description;

  const EventCategory(this.name, {this.description});

  /// Predefined business category for revenue and conversion events
  static const EventCategory business = EventCategory('business',
      description: 'Revenue, conversions, and key business metrics');

  /// Predefined user category for user behavior and actions
  static const EventCategory user = EventCategory('user',
      description: 'User behavior, preferences, and actions');

  /// Predefined technical category for errors, debug, and performance
  static const EventCategory technical = EventCategory('technical',
      description: 'Errors, debugging, and performance metrics');

  /// Predefined sensitive category for events containing PII
  static const EventCategory sensitive = EventCategory('sensitive',
      description: 'Events containing personally identifiable information');

  /// Predefined marketing category for campaigns and attribution
  static const EventCategory marketing = EventCategory('marketing',
      description: 'Marketing campaigns, attribution, and advertising');

  /// Predefined system category for internal system events
  static const EventCategory system = EventCategory('system',
      description: 'Internal system events and health checks');

  /// Predefined security category for security-related events
  static const EventCategory security = EventCategory('security',
      description: 'Security events, authentication, and access control');

  /// Returns a list of all predefined categories
  static List<EventCategory> get predefined => [
        business,
        user,
        technical,
        sensitive,
        marketing,
        system,
        security,
      ];

  /// Creates a subcategory of this category
  EventCategory createSubcategory(String subcategoryName,
      {String? description}) {
    return EventCategory(
      '${name}_$subcategoryName',
      description: description ?? 'Subcategory of $name: $subcategoryName',
    );
  }

  /// Returns true if this is a subcategory of the specified parent
  bool isSubcategoryOf(EventCategory parent) {
    return name.startsWith('${parent.name}_');
  }

  /// Returns the parent category if this is a subcategory
  EventCategory? get parentCategory {
    final parts = name.split('_');
    if (parts.length > 1) {
      return EventCategory(parts.first);
    }
    return null;
  }

  /// Converts to a map for serialization/debugging
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isSubcategory': parentCategory != null,
      'parentCategory': parentCategory?.name,
    };
  }

  @override
  String toString() => 'EventCategory($name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EventCategory && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
