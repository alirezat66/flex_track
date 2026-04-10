/// Local debug inspector (HTTP dashboard + WebSocket live feed).
///
/// On Flutter Web this library exports a no-op stub. On IO platforms it runs
/// a Shelf server. Import only where you need the inspector:
///
/// ```dart
/// import 'package:flex_track/flex_track_inspector.dart';
/// ```
library;

export 'src/inspector/flex_track_inspector.dart';
