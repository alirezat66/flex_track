import 'package:flutter/material.dart';

import '../runtime/offline_delivery_demo.dart';

class OfflineDeliveryScreen extends StatefulWidget {
  const OfflineDeliveryScreen({
    super.key,
    this.demo,
  });

  final OfflineDeliveryDemo? demo;

  @override
  State<OfflineDeliveryScreen> createState() => _OfflineDeliveryScreenState();
}

class _OfflineDeliveryScreenState extends State<OfflineDeliveryScreen> {
  late final OfflineDeliveryDemo _demo =
      widget.demo ?? OfflineDeliveryDemo.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _demo.addListener(_refresh);
    _demo.refreshQueueSize();
  }

  @override
  void dispose() {
    _demo.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dispatch = _demo.lastDispatch;
    final delivered = dispatch?.trackingResults
            .where((result) => result.successful)
            .map((result) => result.trackerId)
            .toList() ??
        const <String>[];
    final failed = dispatch?.trackingResults
            .where((result) => !result.successful)
            .map((result) => result.trackerId)
            .toList() ??
        const <String>[];

    return ListView(
      key: const Key('offline-delivery-lab'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Offline Delivery Lab',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Control connectivity and one failing destination, then inspect '
          'queueing and selective retry here or in FlexTrack Inspector.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('network-toggle'),
                title: const Text('Network available'),
                subtitle: Text(_demo.isOnline ? 'Online' : 'Offline'),
                value: _demo.isOnline,
                onChanged: _busy
                    ? null
                    : (value) => _run(() => _demo.setOnline(value)),
              ),
              SwitchListTile(
                key: const Key('failure-toggle'),
                title: const Text('Retry destination succeeds'),
                subtitle: Text(_demo.retryTrackerFails
                    ? 'Intentional failure enabled'
                    : 'Healthy'),
                value: !_demo.retryTrackerFails,
                onChanged: _busy
                    ? null
                    : (value) => _demo.setRetryTrackerFails(!value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending events: ${_demo.queueSize}',
                    key: const Key('queue-count'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Reliable destination: '
                    '${_demo.successTracker.successCount} delivered / '
                    '${_demo.successTracker.attemptCount} attempts'),
                Text('Retry destination: '
                    '${_demo.retryTracker.successCount} delivered / '
                    '${_demo.retryTracker.attemptCount} attempts'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('track-delivery-event'),
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await _demo.track();
                        }),
                icon: const Icon(Icons.send),
                label: const Text('Track event'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('flush-delivery-queue'),
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await _demo.flush();
                        }),
                icon: const Icon(Icons.sync),
                label: const Text('Flush queue'),
              ),
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (dispatch != null) ...[
          const SizedBox(height: 16),
          _ResultCard(
            title: 'Last dispatch',
            lines: {
              'Delivered': delivered,
              'Failed': failed,
              'Queued': dispatch.queuedTrackerIds,
            },
          ),
        ],
        if (_demo.lastFlush case final flush?) ...[
          const SizedBox(height: 12),
          Card(
            key: const Key('flush-result'),
            child: ListTile(
              title: const Text('Last flush'),
              subtitle: Text(
                '${flush.attemptedEvents} attempted · '
                '${flush.deliveredEvents} delivered · '
                '${flush.remainingEvents} remaining',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.lines});

  final String title;
  final Map<String, List<String>> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('dispatch-result'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final entry in lines.entries)
              Text('${entry.key}: '
                  '${entry.value.isEmpty ? 'none' : entry.value.join(', ')}'),
          ],
        ),
      ),
    );
  }
}
