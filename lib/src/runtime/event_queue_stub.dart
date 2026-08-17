import 'event_queue.dart';

/// File persistence is unavailable on this platform.
class FileEventQueue implements EventQueue {
  FileEventQueue(Object file) {
    throw UnsupportedError('FileEventQueue requires dart:io');
  }

  Never _unsupported() =>
      throw UnsupportedError('FileEventQueue requires dart:io');
  @override
  Future<void> clear() => _unsupported();
  @override
  Future<void> enqueue(QueuedEvent item) => _unsupported();
  @override
  Future<List<QueuedEvent>> read({required int limit}) => _unsupported();
  @override
  Future<void> remove(String eventId) => _unsupported();
  @override
  Future<void> replace(QueuedEvent item) => _unsupported();
  @override
  Future<int> size() => _unsupported();
}
