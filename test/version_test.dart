import 'dart:io';

import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exported package version matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\S+)\s*$', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(flexTrackVersion, match!.group(1));
  });
}
