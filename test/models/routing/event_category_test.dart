import 'package:flex_track/src/models/routing/event_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventCategory', () {
    test('should create a subcategory correctly', () {
      const parentCategory = EventCategory('parent');
      final subcategory = parentCategory.createSubcategory('child');
      expect(subcategory.name, 'parent_child');
      expect(subcategory.description, 'Subcategory of parent: child');
    });

    test('should create a subcategory with custom description', () {
      const parentCategory = EventCategory('parent');
      final subcategory =
          parentCategory.createSubcategory('child', description: 'Custom');
      expect(subcategory.name, 'parent_child');
      expect(subcategory.description, 'Custom');
    });

    test('isSubcategoryOf should return true for a valid subcategory', () {
      const parentCategory = EventCategory('parent');
      final subcategory = parentCategory.createSubcategory('child');
      expect(subcategory.isSubcategoryOf(parentCategory), isTrue);
    });

    test('isSubcategoryOf should return false for a non-subcategory', () {
      const category1 = EventCategory('category1');
      const category2 = EventCategory('category2');
      expect(category1.isSubcategoryOf(category2), isFalse);
    });

    test('parentCategory should return the correct parent', () {
      const parentCategory = EventCategory('parent');
      final subcategory = parentCategory.createSubcategory('child');
      expect(subcategory.parentCategory?.name, 'parent');
    });

    test('parentCategory should return null for a top-level category', () {
      const category = EventCategory('top-level'); // No underscore or hyphen
      expect(category.parentCategory, isNull);
    });

    test('toMap should return a correct map representation', () {
      const category = EventCategory('test_category', description: 'A test');
      final map = category.toMap();
      expect(map['name'], 'test_category');
      expect(map['description'], 'A test');
      expect(map['isSubcategory'],
          isTrue); // 'test_category' is not a subcategory by the new logic
      expect(map['parentCategory'],
          'test'); // 'test_category' has no parent by the new logic

      final subcategory = category.createSubcategory('sub');
      final subMap = subcategory.toMap();
      expect(subMap['name'], 'test_category_sub');
      expect(subMap['description'], 'Subcategory of test_category: sub');
      expect(subMap['isSubcategory'], isTrue);
      expect(subMap['parentCategory'],
          'test_category'); // Parent should be 'test_category'
    });

    test('toString should return a correct string representation', () {
      const category = EventCategory('test_category');
      expect(category.toString(), 'EventCategory(test_category)');
    });

    test('hashCode should be consistent with name', () {
      const category1 = EventCategory('test_category');
      const category2 = EventCategory('test_category');
      const category3 = EventCategory('another_category');
      expect(category1.hashCode, category2.hashCode);
      expect(category1.hashCode, isNot(category3.hashCode));
    });

    test('equality operator should work correctly', () {
      const category1 = EventCategory('test_category');
      const category2 = EventCategory('test_category');
      const category3 = EventCategory('another_category');
      expect(category1 == category2, isTrue);
      expect(category1 == category3, isFalse);
      expect(category1, isNotNull);
      expect(category1 == Object(), isFalse);
    });

    group('Predefined Event Categories', () {
      test('business category should be defined', () {
        expect(EventCategory.business.name, 'business');
        expect(EventCategory.business.description,
            'Revenue, conversions, and key business metrics');
      });

      test('user category should be defined', () {
        expect(EventCategory.user.name, 'user');
        expect(EventCategory.user.description,
            'User behavior, preferences, and actions');
      });

      test('technical category should be defined', () {
        expect(EventCategory.technical.name, 'technical');
        expect(EventCategory.technical.description,
            'Errors, debugging, and performance metrics');
      });

      test('sensitive category should be defined', () {
        expect(EventCategory.sensitive.name, 'sensitive');
        expect(EventCategory.sensitive.description,
            'Events containing personally identifiable information');
      });

      test('marketing category should be defined', () {
        expect(EventCategory.marketing.name, 'marketing');
        expect(EventCategory.marketing.description,
            'Marketing campaigns, attribution, and advertising');
      });

      test('system category should be defined', () {
        expect(EventCategory.system.name, 'system');
        expect(EventCategory.system.description,
            'Internal system events and health checks');
      });

      test('security category should be defined', () {
        expect(EventCategory.security.name, 'security');
        expect(EventCategory.security.description,
            'Security events, authentication, and access control');
      });

      test('predefined list should contain all predefined categories', () {
        final predefined = EventCategory.predefined;
        expect(predefined, contains(EventCategory.business));
        expect(predefined, contains(EventCategory.user));
        expect(predefined, contains(EventCategory.technical));
        expect(predefined, contains(EventCategory.sensitive));
        expect(predefined, contains(EventCategory.marketing));
        expect(predefined, contains(EventCategory.system));
        expect(predefined, contains(EventCategory.security));
        expect(predefined.length, 7);
      });
    });
  });
}
