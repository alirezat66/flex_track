import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';

/// Minimal event for the sample (inline for clarity).
class _DemoEvent extends BaseEvent {
  _DemoEvent(this._name, [this._props]);

  final String _name;
  final Map<String, Object>? _props;

  @override
  String getName() => _name;

  @override
  Map<String, Object>? getProperties() => _props;

  @override
  bool get requiresConsent => false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlexTrack.quickSetup([
    ConsoleTracker(showProperties: true, showTimestamps: false),
  ]);

  runApp(const StaticDemoApp());
}

class StaticDemoApp extends StatelessWidget {
  const StaticDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flex_track (static API)',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Static FlexTrack API')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Uses FlexTrack.setup / FlexTrack.track only. '
            'Widget wrappers still call the static API internally.',
          ),
          const SizedBox(height: 16),
          FlexMountTrack(
            event: _DemoEvent('widget_strip_mounted'),
            child: FlexClickTrack(
              event: _DemoEvent('wrapper_tap'),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.touch_app),
                  title: const Text('FlexClickTrack'),
                  subtitle: const Text(
                    'Tap — check console for ConsoleTracker output',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              FlexTrack.track(_DemoEvent('manual_track', {'source': 'button'}));
            },
            icon: const Icon(Icons.send),
            label: const Text('FlexTrack.track(...)'),
          ),
        ],
      ),
    );
  }
}
