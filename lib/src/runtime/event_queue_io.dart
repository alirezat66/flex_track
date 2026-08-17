import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'event_queue.dart';

/// Durable FIFO queue using atomic replacement in an application-owned file.
class FileEventQueue implements EventQueue {
  FileEventQueue(this.file);

  final File file;
  Future<void> _tail = Future.value();

  Future<T> _locked<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  @override
  Future<void> enqueue(QueuedEvent item) => _mutate((items) {
        if (!items.any((value) => value.id == item.id)) items.add(item);
      });

  @override
  Future<List<QueuedEvent>> read({required int limit}) => _locked(() async {
        if (limit <= 0) throw ArgumentError.value(limit, 'limit');
        return List.unmodifiable((await _load()).take(limit));
      });

  @override
  Future<void> replace(QueuedEvent item) => _mutate((items) {
        final index = items.indexWhere((value) => value.id == item.id);
        if (index >= 0) items[index] = item;
      });

  @override
  Future<void> remove(String eventId) =>
      _mutate((items) => items.removeWhere((value) => value.id == eventId));

  @override
  Future<int> size() => _locked(() async => (await _load()).length);

  @override
  Future<void> clear() => _locked(() async {
        if (await file.exists()) await file.delete();
      });

  Future<void> _mutate(void Function(List<QueuedEvent>) change) =>
      _locked(() async {
        final items = await _load();
        change(items);
        await _persist(items);
      });

  Future<List<QueuedEvent>> _load() async {
    if (!await file.exists() || await file.length() == 0) return [];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw const FormatException('FlexTrack queue root must be a JSON array');
    }
    return decoded
        .map((value) =>
            QueuedEvent.fromJson((value as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> _persist(List<QueuedEvent> items) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(items.map((value) => value.toJson()).toList()),
      flush: true,
    );
    await temporary.rename(file.path);
  }
}
