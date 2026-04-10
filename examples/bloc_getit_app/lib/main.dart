import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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

final getIt = GetIt.instance;

class CounterCubit extends Cubit<int> {
  CounterCubit(this._client) : super(0);

  final FlexTrackClient _client;

  void increment() {
    emit(state + 1);
    _client.track(_DemoEvent('bloc_counter', {'count': state}));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlexTrack.quickSetup([
    ConsoleTracker(showProperties: true, showTimestamps: false),
  ]);

  getIt.registerSingleton<FlexTrackClient>(FlexTrack.instance.client);

  runApp(const BlocGetItDemoApp());
}

class BlocGetItDemoApp extends StatelessWidget {
  const BlocGetItDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(getIt<FlexTrackClient>()),
      child: MaterialApp(
        title: 'flex_track + Bloc + GetIt',
        theme: ThemeData(
          colorSchemeSeed: Colors.deepOrange,
          useMaterial3: true,
        ),
        home: const _HomePage(),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bloc + GetIt + FlexTrackClient')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'GetIt holds FlexTrack.instance.client after setup. '
            'Cubit calls client.track; FlexClickTrack still uses FlexTrack.track.',
          ),
          const SizedBox(height: 16),
          FlexClickTrack(
            event: _DemoEvent('wrapper_tap'),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.touch_app),
                title: const Text('FlexClickTrack'),
                subtitle: const Text('Uses static API'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<CounterCubit, int>(
            builder: (context, count) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Count: $count', textAlign: TextAlign.center),
                  FilledButton(
                    onPressed: () => context.read<CounterCubit>().increment(),
                    child: const Text('Increment (Cubit → client.track)'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
