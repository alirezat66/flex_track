import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/mock_events.dart';

class _RouteScreen extends StatefulWidget {
  const _RouteScreen({
    required this.observer,
    required this.eventName,
  });

  final FlexTrackRouteObserver observer;
  final String eventName;

  @override
  State<_RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<_RouteScreen>
    with FlexTrackRouteViewMixin {
  @override
  FlexTrackRouteObserver get flexTrackRouteObserver => widget.observer;

  @override
  BaseEvent get routeViewEvent => CustomEvent.named(widget.eventName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.eventName)),
      body: TextButton(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const _SecondScreen(),
            ),
          );
        },
        child: const Text('open second'),
      ),
    );
  }
}

class _SecondScreen extends StatelessWidget {
  const _SecondScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('second')),
      body: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('pop'),
      ),
    );
  }
}

/// Second route that also uses [FlexTrackRouteViewMixin] (shared observer).
class _SecondRouteTracked extends StatefulWidget {
  const _SecondRouteTracked({required this.observer});

  final FlexTrackRouteObserver observer;

  @override
  State<_SecondRouteTracked> createState() => _SecondRouteTrackedState();
}

class _SecondRouteTrackedState extends State<_SecondRouteTracked>
    with FlexTrackRouteViewMixin {
  @override
  FlexTrackRouteObserver get flexTrackRouteObserver => widget.observer;

  @override
  BaseEvent get routeViewEvent => CustomEvent.named('screen_b');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('screen b')),
      body: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('close b'),
      ),
    );
  }
}

class _HomeWithMixinedPush extends StatefulWidget {
  const _HomeWithMixinedPush({required this.observer});

  final FlexTrackRouteObserver observer;

  @override
  State<_HomeWithMixinedPush> createState() => _HomeWithMixinedPushState();
}

class _HomeWithMixinedPushState extends State<_HomeWithMixinedPush>
    with FlexTrackRouteViewMixin {
  @override
  FlexTrackRouteObserver get flexTrackRouteObserver => widget.observer;

  @override
  BaseEvent get routeViewEvent => CustomEvent.named('screen_a');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _SecondRouteTracked(observer: widget.observer),
            ),
          );
        },
        child: const Text('open tracked second'),
      ),
    );
  }
}

class _ResumeScreen extends StatefulWidget {
  const _ResumeScreen({required this.observer});

  final FlexTrackRouteObserver observer;

  @override
  State<_ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<_ResumeScreen>
    with FlexTrackRouteViewMixin {
  @override
  FlexTrackRouteObserver get flexTrackRouteObserver => widget.observer;

  @override
  BaseEvent get routeViewEvent => CustomEvent.named('resume_screen');

  @override
  bool get trackWhenReturningFromChildRoute => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(),
                body: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('back'),
                ),
              ),
            ),
          );
        },
        child: const Text('push'),
      ),
    );
  }
}

void main() {
  group('FlexTrackRouteViewMixin', () {
    tearDown(() async {
      await FlexTrack.reset();
    });

    testWidgets('tracks initial route (home) once', (tester) async {
      final mock = await setupFlexTrackForTesting();
      final observer = FlexTrackRouteObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: _RouteScreen(observer: observer, eventName: 'home_screen'),
        ),
      );

      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'home_screen');
    });

    testWidgets('didPopNext fires when trackWhenReturningFromChildRoute',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      final observer = FlexTrackRouteObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: _ResumeScreen(observer: observer),
        ),
      );
      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'resume_screen');

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();

      expect(
        mock.capturedEvents.map((e) => e.getName()).toList(),
        ['resume_screen', 'resume_screen'],
      );
    });

    testWidgets('does NOT re-track home when pushing plain second route',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      final observer = FlexTrackRouteObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: _RouteScreen(observer: observer, eventName: 'home_only'),
        ),
      );
      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'home_only');

      await tester.tap(find.text('open second'));
      await tester.pumpAndSettle();

      expect(mock.capturedEvents, hasLength(1));
      expect(mock.capturedEvents.single.getName(), 'home_only');
    });

    testWidgets(
        'does NOT re-track home on pop when trackWhenReturningFromChildRoute is false',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      final observer = FlexTrackRouteObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: _RouteScreen(observer: observer, eventName: 'home_sticky'),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('open second'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('pop'));
      await tester.pumpAndSettle();

      expect(mock.capturedEvents, hasLength(1));
      expect(mock.capturedEvents.single.getName(), 'home_sticky');
    });

    testWidgets(
        'tracks each screen once with shared observer when both use mixin',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      final observer = FlexTrackRouteObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: _HomeWithMixinedPush(observer: observer),
        ),
      );
      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'screen_a');

      await tester.tap(find.text('open tracked second'));
      await tester.pumpAndSettle();

      expect(
        mock.capturedEvents.map((e) => e.getName()).toList(),
        ['screen_a', 'screen_b'],
      );

      await tester.tap(find.text('close b'));
      await tester.pumpAndSettle();

      expect(mock.capturedEvents, hasLength(2));
    });
  });
}
