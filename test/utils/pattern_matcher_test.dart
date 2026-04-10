import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(PatternMatcher.clearCache);

  group('PatternMatcher name matching', () {
    test(
      'matchSimplePattern treats * as a multi-character wildcard',
      () {
        expect(PatternMatcher.matchSimplePattern('screen_home', 'screen_*'),
            isTrue);
        expect(PatternMatcher.matchSimplePattern('other', 'screen_*'), isFalse);
        expect(PatternMatcher.matchSimplePattern('anything', '*'), isTrue);
      },
    );

    test(
      'matchSimplePattern treats ? as a single-character wildcard (exact length)',
      () {
        expect(PatternMatcher.matchSimplePattern('a1', 'a?'), isTrue);
        expect(PatternMatcher.matchSimplePattern('ab', 'a?'), isTrue);
        expect(PatternMatcher.matchSimplePattern('a', 'a?'), isFalse);
        expect(PatternMatcher.matchSimplePattern('abc', 'a?'), isFalse);
      },
    );

    test(
      'matchAnyPattern returns true when any listed pattern matches (OR)',
      () {
        expect(
          PatternMatcher.matchAnyPattern('purchase_done', [
            'click_*',
            'purchase_*',
          ]),
          isTrue,
        );
        expect(
          PatternMatcher.matchAnyPattern('unknown', ['a_*', 'b_*']),
          isFalse,
        );
      },
    );

    test(
      'matchAnyRegexPattern returns true when any regex matches',
      () {
        expect(
          PatternMatcher.matchAnyRegexPattern('foo_bar', [
            RegExp(r'^foo_'),
            RegExp(r'^other_'),
          ]),
          isTrue,
        );
      },
    );

    test(
      'matchAnyPrefix, matchAnySuffix, and matchAnySubstring behave as documented',
      () {
        expect(
          PatternMatcher.matchAnyPrefix('checkout_start', ['checkout', 'cart']),
          isTrue,
        );
        expect(
          PatternMatcher.matchAnySuffix('item_viewed', ['viewed', 'done']),
          isTrue,
        );
        expect(
          PatternMatcher.matchAnySubstring('user_login_failed', ['login']),
          isTrue,
        );
      },
    );
  });

  group('PatternMatcher property matching', () {
    test(
      'matchProperty returns false when properties are null or key is missing',
      () {
        expect(
          PatternMatcher.matchProperty(null, 'tier'),
          isFalse,
        );
        expect(
          PatternMatcher.matchProperty({'other': 1}, 'tier'),
          isFalse,
        );
      },
    );

    test(
      'matchProperty supports exact value, simple pattern, and regex on strings',
      () {
        final props = {'tier': 'premium', 'email': 'a@b.co'};

        expect(
          PatternMatcher.matchProperty(props, 'tier', expectedValue: 'premium'),
          isTrue,
        );
        expect(
          PatternMatcher.matchProperty(props, 'tier', expectedValue: 'free'),
          isFalse,
        );
        expect(
          PatternMatcher.matchProperty(props, 'email', pattern: '*@*.co'),
          isTrue,
        );
        expect(
          PatternMatcher.matchProperty(
            props,
            'email',
            regex: RegExp(r'^[^@]+@[^@]+$'),
          ),
          isTrue,
        );
      },
    );

    test(
      'matchProperty returns true when only checking that the property exists',
      () {
        expect(
          PatternMatcher.matchProperty({'flag': 42}, 'flag'),
          isTrue,
        );
      },
    );

    test(
      'matchAllProperties requires every matcher to pass (AND)',
      () {
        final props = {'a': 1, 'b': 'ok'};
        expect(
          PatternMatcher.matchAllProperties(props, {
            'a': PropertyMatcher.equals(1),
            'b': PropertyMatcher.equals('ok'),
          }),
          isTrue,
        );
        expect(
          PatternMatcher.matchAllProperties(props, {
            'a': PropertyMatcher.equals(1),
            'b': PropertyMatcher.equals('no'),
          }),
          isFalse,
        );
        expect(PatternMatcher.matchAllProperties(null, {}), isFalse);
      },
    );

    test(
      'matchAnyProperty passes when at least one property matcher passes (OR)',
      () {
        final props = {'a': 1, 'b': 2};
        expect(
          PatternMatcher.matchAnyProperty(props, {
            'a': PropertyMatcher.equals(99),
            'b': PropertyMatcher.equals(2),
          }),
          isTrue,
        );
        expect(PatternMatcher.matchAnyProperty(null, {}), isFalse);
      },
    );
  });

  group('PatternMatcher categories and validation', () {
    test(
      'matchesCategory classifies typical analytics-style event names',
      () {
        expect(
          PatternMatcher.matchesCategory(
            'click_button',
            EventCategoryPattern.userInteraction,
          ),
          isTrue,
        );
        expect(
          PatternMatcher.matchesCategory(
            'page_view_home',
            EventCategoryPattern.navigation,
          ),
          isTrue,
        );
        expect(
          PatternMatcher.matchesCategory(
            'purchase_complete',
            EventCategoryPattern.business,
          ),
          isTrue,
        );
        expect(
          PatternMatcher.matchesCategory(
            'random_name',
            EventCategoryPattern.business,
          ),
          isFalse,
        );
      },
    );

    test(
      'validatePattern accepts wildcards and reports invalid regex sources',
      () {
        expect(PatternMatcher.validatePattern('foo_*').isValid, isTrue);
        final bad = PatternMatcher.validatePattern('[unclosed');
        expect(bad.isValid, isFalse);
        expect(bad.error, isNotNull);
      },
    );

    test(
      'getCacheStats reflects cache usage after repeated category matches',
      () {
        PatternMatcher.clearCache();
        PatternMatcher.matchesCategory(
            'click_x', EventCategoryPattern.userInteraction);
        PatternMatcher.matchesCategory(
            'page_view_x', EventCategoryPattern.navigation);
        final stats = PatternMatcher.getCacheStats();
        expect(stats['size'], greaterThan(0));
        expect(stats['maxSize'], 100);
      },
    );
  });

  group('PropertyMatcher', () {
    test('toString summarizes the matcher kind', () {
      expect(PropertyMatcher.equals(1).toString(), contains('1'));
      expect(PropertyMatcher.pattern('a*').toString(), contains('a*'));
      expect(PropertyMatcher.regex(RegExp('x')).toString(), contains('x'));
    });
  });
}
