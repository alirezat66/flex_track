import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Same [FlexTrackClient] installed by [FlexTrack.setup], exposed for manual calls.
final flexTrackClientProvider = Provider<FlexTrackClient>(
  (_) => FlexTrack.instance.client,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlexTrack.quickSetup([
    ConsoleTracker(showProperties: true, showTimestamps: false),
  ]);

  runApp(const ProviderScope(child: RiverpodDemoApp()));
}

class RiverpodDemoApp extends StatelessWidget {
  const RiverpodDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flex_track + Riverpod',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(flexTrackClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod + FlexTrackClient')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'FlexTrack.setup runs in main. Widget wrappers use FlexTrack.track; '
            'this button uses the injected FlexTrackClient from Riverpod.',
          ),
          const SizedBox(height: 16),
          FlexClickTrack(
            event: _DemoEvent('wrapper_tap'),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.touch_app),
                title: const Text('FlexClickTrack'),
                subtitle: const Text('Static FlexTrack.track under the hood'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              client.track(_DemoEvent('client_track', {'via': 'riverpod'}));
            },
            icon: const Icon(Icons.send),
            label: const Text('client.track via Provider'),
          ),
        ],
      ),
    );
  }
}
