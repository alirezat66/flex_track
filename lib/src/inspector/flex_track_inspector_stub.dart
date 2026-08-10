/// Web / non-IO stub: [FlexTrackInspector.start] and [stop] are no-ops.
class FlexTrackInspector {
  FlexTrackInspector._();

  /// Always `null` on this platform.
  static String? get url => null;

  /// No-op; returns `null` immediately.
  static Future<String?> start({int port = 7788}) async => null;

  /// No-op.
  static Future<void> stop() async {}
}
