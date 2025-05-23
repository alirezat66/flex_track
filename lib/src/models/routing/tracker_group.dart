/// Represents a group of trackers that can be targeted for event routing
class TrackerGroup {
  final String name;
  final List<String> trackerIds;
  final String? description;

  const TrackerGroup(this.name, this.trackerIds, {this.description});

  /// Special group that represents all registered trackers
  static const TrackerGroup all =
      TrackerGroup('all', ['*'], description: 'All registered trackers');

  /// Predefined development and debugging group
  static const TrackerGroup development = TrackerGroup(
      'development', ['console'],
      description: 'Development and debugging trackers');

  /// Returns true if this group contains the special "all" identifier
  bool get includesAll => trackerIds.contains('*');

  /// Returns true if this group contains the specified tracker ID
  bool containsTracker(String trackerId) {
    return includesAll || trackerIds.contains(trackerId);
  }

  /// Creates a new group by combining this group with another
  TrackerGroup combineWith(TrackerGroup other) {
    final combinedIds = <String>{...trackerIds, ...other.trackerIds}.toList();
    return TrackerGroup(
      '${name}_${other.name}',
      combinedIds,
      description: 'Combined group of $name and ${other.name}',
    );
  }

  /// Creates a new group by excluding specified tracker IDs
  TrackerGroup excluding(List<String> excludeIds) {
    final filteredIds =
        trackerIds.where((id) => !excludeIds.contains(id)).toList();
    return TrackerGroup(
      '${name}_filtered',
      filteredIds,
      description: '$description (excluding ${excludeIds.join(', ')})',
    );
  }

  /// Converts to a map for serialization/debugging
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'trackerIds': trackerIds,
      'description': description,
      'includesAll': includesAll,
    };
  }

  @override
  String toString() => 'TrackerGroup($name: ${trackerIds.join(', ')})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackerGroup &&
          other.name == name &&
          _listEquals(other.trackerIds, trackerIds);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(trackerIds));

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
