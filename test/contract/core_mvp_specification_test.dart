import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core MVP specification keeps required contract sections', () {
    final specification =
        File('docs/core-mvp-specification.md').readAsStringSync();

    expect(specification, contains('Specification version: 1.0.0'));
    expect(specification, contains('## 2. MVP boundary'));
    expect(specification, contains('## 9. Processing order'));
    expect(specification, contains('## 12. Versioning and compatibility'));
    expect(specification, contains('**MUST**'));
    expect(specification, contains('Durable/offline queues'));
    expect(specification, contains('sampling_vectors.json'));
  });
}
