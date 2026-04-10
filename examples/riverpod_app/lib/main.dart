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

/// Provided in [main] via [ProviderScope] overrides — same instance wrapped by
/// [FlexTrackScope] so [FlexClickTrack] picks it up without [FlexTrack.setup].
final flexTrackClientProvider = Provider<FlexTrackClient>(
  (_) => throw UnimplementedError('Override flexTrackClientProvider in main'),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = await FlexTrackClient.create([
    ConsoleTracker(showProperties: true, showTimestamps: false),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        flexTrackClientProvider.overrideWithValue(client),
      ],
      child: const RiverpodDemoApp(),
    ),
  );
}

class RiverpodDemoApp extends ConsumerWidget {
  const RiverpodDemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(flexTrackClientProvider);

    return MaterialApp(
      title: 'flex_track + Riverpod',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: FlexTrackScope(
        client: client,
        child: const _HomePage(),
      ),
    );
  }
}

class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(flexTrackClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod + FlexTrackScope')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'No FlexTrack.setup: a FlexTrackClient is created in main, injected '
            'through Riverpod, and the home route is wrapped with FlexTrackScope. '
            'FlexClickTrack below uses that scoped client. The button calls '
            'client.track directly.',
          ),
          const SizedBox(height: 16),
          FlexClickTrack(
            event: _DemoEvent('wrapper_tap'),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.touch_app),
                title: const Text('FlexClickTrack'),
                subtitle: const Text('Uses FlexTrackScope client (scoped)'),
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
