import 'dart:async';

import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';

import '../events/app_events.dart';

class EventEnrichmentScreen extends StatefulWidget {
  const EventEnrichmentScreen({super.key});

  @override
  State<EventEnrichmentScreen> createState() => _EventEnrichmentScreenState();
}

class _EventEnrichmentScreenState extends State<EventEnrichmentScreen> {
  bool _transformerAdded = false;
  EventTransformer? _activeTransformer;
  final List<String> _log = [];
  StreamSubscription<EventDispatchRecord>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FlexTrack.eventDispatchStream.listen((record) {
      if (!mounted) return;
      final name = record.event.getName();
      final props = record.event.getProperties();
      setState(() {
        _log.insert(0, '[$name] ${props ?? {}}');
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (_transformerAdded && _activeTransformer != null) {
      FlexTrack.removeTransformer(_activeTransformer!);
    }
    super.dispose();
  }

  void _toggleTransformer() {
    setState(() {
      if (_transformerAdded) {
        FlexTrack.removeTransformer(_activeTransformer!);
        _activeTransformer = null;
        _transformerAdded = false;
      } else {
        _activeTransformer = (event) => EnrichedEvent(event, {
              'current_route': 'event_enrichment_screen',
              'screen_version': '1.0',
            });
        FlexTrack.addTransformer(_activeTransformer!);
        _transformerAdded = true;
      }
    });
  }

  Future<void> _fireButtonEvent() async {
    await FlexTrack.track(ButtonClickEvent(
      buttonId: 'enrichment_demo_button',
      buttonText: 'Fire Button Event',
      screenName: 'event_enrichment_screen',
    ));
  }

  Future<void> _firePageViewEvent() async {
    await FlexTrack.track(PageViewEvent(
      pageName: 'event_enrichment_screen',
      parameters: const {'source': 'demo'},
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Enrichment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TransformerStatusCard(active: _transformerAdded),
          const SizedBox(height: 16),
          _ToggleTransformerCard(
            active: _transformerAdded,
            onToggle: _toggleTransformer,
          ),
          const SizedBox(height: 16),
          _FireEventsCard(
            onFireButton: _fireButtonEvent,
            onFirePageView: _firePageViewEvent,
          ),
          const SizedBox(height: 16),
          _EventLogCard(
            log: _log,
            onClear: () => setState(() => _log.clear()),
          ),
        ],
      ),
    );
  }
}

class _TransformerStatusCard extends StatelessWidget {
  final bool active;

  const _TransformerStatusCard({required this.active});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.circle,
          color: active ? Colors.green : Colors.grey,
          size: 16,
        ),
        title: const Text('Active Transformers'),
        subtitle: Text(active ? '1 transformer active' : 'No transformers'),
        trailing: Text(
          active ? '1' : '0',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: active ? Colors.green : Colors.grey,
              ),
        ),
      ),
    );
  }
}

class _ToggleTransformerCard extends StatelessWidget {
  final bool active;
  final VoidCallback onToggle;

  const _ToggleTransformerCard({
    required this.active,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Enricher',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Automatically attaches current_route and screen_version '
              'to every event.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onToggle,
                child: Text(active ? 'Remove Transformer' : 'Add Transformer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FireEventsCard extends StatelessWidget {
  final VoidCallback onFireButton;
  final VoidCallback onFirePageView;

  const _FireEventsCard({
    required this.onFireButton,
    required this.onFirePageView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fire Test Events',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFireButton,
                    icon: const Icon(Icons.touch_app),
                    label: const Text('Button Event'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFirePageView,
                    icon: const Icon(Icons.pages),
                    label: const Text('Page View'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FlexClickTrack(
                event: ButtonClickEvent(
                  buttonId: 'flex_click_demo',
                  buttonText: 'FlexClickTrack Demo',
                  screenName: 'event_enrichment_screen',
                ),
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.ads_click),
                  label: const Text('FlexClickTrack Demo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventLogCard extends StatelessWidget {
  final List<String> log;
  final VoidCallback onClear;

  const _EventLogCard({required this.log, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Event Log',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: log.isEmpty
                  ? const Center(
                      child: Text('Fire an event to see it here.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: log.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log[index],
                          style: const TextStyle(
                              fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
