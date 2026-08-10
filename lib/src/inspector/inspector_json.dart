/// JSON-safe conversion for inspector payloads (maps, lists, primitives).
Object? jsonSafeForInspector(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String || value is num || value is bool) {
    return value;
  }
  if (value is Map) {
    final out = <String, Object?>{};
    for (final e in value.entries) {
      out['${e.key}'] = jsonSafeForInspector(e.value as Object?);
    }
    return out;
  }
  if (value is List) {
    return value.map((e) => jsonSafeForInspector(e as Object?)).toList();
  }
  if (value is Set) {
    return value.map((e) => jsonSafeForInspector(e as Object?)).toList();
  }
  return value.toString();
}

/// Converts [getProperties] output to a JSON-encodable map.
Map<String, Object?>? jsonSafeProperties(Map<String, Object>? props) {
  if (props == null) {
    return null;
  }
  final out = <String, Object?>{};
  for (final e in props.entries) {
    out[e.key] = jsonSafeForInspector(e.value);
  }
  return out;
}
