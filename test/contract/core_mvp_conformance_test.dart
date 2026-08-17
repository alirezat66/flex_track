import 'dart:convert';
import 'dart:io';

import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixturePath = 'test/fixtures/conformance/core_mvp_cases.json';
const _schemaPath = 'test/fixtures/conformance/core_mvp.schema.json';
const _reportPath = 'test/fixtures/conformance/flutter_report.json';

void main() {
  final fixture = _readObject(_fixturePath);
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  test('fixture document satisfies the shared schema contract', () {
    final schema = _readObject(_schemaPath);
    expect(schema[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
    expect(fixture[r'$schema'], 'core_mvp.schema.json');
    expect(fixture['specVersion'], '1.0.0');
    expect(fixture['fixtureVersion'], matches(r'^1\.[0-9]+\.[0-9]+$'));
    expect(cases, isNotEmpty);

    final ids = <String>{};
    for (final fixtureCase in cases) {
      expect(fixtureCase.keys.toSet(),
          equals({'id', 'behavior', 'input', 'expected'}));
      expect(fixtureCase['id'], isA<String>());
      expect((fixtureCase['id'] as String), isNotEmpty);
      expect(ids.add(fixtureCase['id'] as String), isTrue,
          reason: 'Fixture IDs must be unique');
      expect(
        ['routing', 'consent', 'sampling', 'enrichment', 'debug'],
        contains(fixtureCase['behavior']),
      );
      expect(fixtureCase['input'], isA<Map<String, dynamic>>());
      expect(fixtureCase['expected'], isA<Map<String, dynamic>>());
    }
  });

  for (final fixtureCase in cases) {
    test('conformance: ${fixtureCase['id']}', () async {
      expect(
        await _runCase(fixtureCase),
        fixtureCase['expected'],
        reason: fixtureCase['id'] as String,
      );
    });
  }

  test('machine-readable Flutter report covers every passing case', () {
    final report = _readObject(_reportPath);
    final caseIds = cases.map((value) => value['id']).toList();

    expect(report['specVersion'], fixture['specVersion']);
    expect(report['fixtureVersion'], fixture['fixtureVersion']);
    expect(report['implementation'], 'flutter');
    expect(report['total'], cases.length);
    expect(report['passed'], cases.length);
    expect(report['failed'], 0);
    expect(report['caseIds'], caseIds);
  });
}

Future<Map<String, dynamic>> _runCase(Map<String, dynamic> fixtureCase) async {
  final input = fixtureCase['input'] as Map<String, dynamic>;
  switch (fixtureCase['behavior']) {
    case 'routing':
      return _runRouting(input);
    case 'consent':
      return _runConsent(input);
    case 'sampling':
      final identity = input['identity'] as String;
      final rate = (input['sampleRate'] as num).toDouble();
      return {
        'hash': SamplingUtils.stableHash(identity),
        'accepted': SamplingUtils.shouldSampleDeterministic(identity, rate),
      };
    case 'enrichment':
      final original = _FixtureEvent.fromJson(input);
      final enriched = EnrichedEvent(
        original,
        _objectProperties(input['extraProperties']),
      );
      return {
        'eventId': enriched.eventId,
        'timestamp': enriched.timestamp.toIso8601String(),
        'name': enriched.name,
        'properties': enriched.properties,
      };
    case 'debug':
      final setup = _routingSetup(input);
      final tracker = MockTracker(id: 'analytics', name: 'Analytics');
      final client = await FlexTrackClient.create(
        [tracker],
        routing: setup.engine.configuration,
      );
      client.setGeneralConsent(true);
      final recordFuture = client.eventDispatchStream.first;
      await client.track(setup.event);
      final record = await recordFuture;
      await client.dispose();
      return {
        'targetTrackers': record.targetTrackers,
        'successfulTrackerIds': record.successfulTrackerIds,
      };
    default:
      throw StateError('Unsupported behavior: ${fixtureCase['behavior']}');
  }
}

Map<String, dynamic> _runRouting(Map<String, dynamic> input) {
  final setup = _routingSetup(input);
  final result = setup.engine.routeEvent(
    setup.event,
    availableTrackers: setup.availableTrackers,
  );
  return {
    'targets': result.targetTrackers,
    'appliedPriorities':
        result.appliedRules.map((rule) => rule.priority).toList(),
  };
}

Map<String, dynamic> _runConsent(Map<String, dynamic> input) {
  final event = _FixtureEvent.fromJson(input['event'] as Map<String, dynamic>);
  final rule = _ruleFromJson(input['rule'] as Map<String, dynamic>);
  final result = RoutingEngine(RoutingConfiguration(rules: [rule])).routeEvent(
    event,
    hasGeneralConsent: input['generalConsent'] as bool,
    hasPIIConsent: input['piiConsent'] as bool,
    availableTrackers: {'analytics'},
  );
  return {
    'targets': result.targetTrackers,
    'skipReasons': result.skippedRules.map((value) => value.reason).toList(),
  };
}

_RoutingSetup _routingSetup(Map<String, dynamic> input) {
  final event = _FixtureEvent.fromJson(input['event'] as Map<String, dynamic>);
  final rules = (input['rules'] as List)
      .cast<Map<String, dynamic>>()
      .map(_ruleFromJson)
      .toList();
  final defaultIds = (input['defaultGroup'] as List?)?.cast<String>();
  final configuration = RoutingConfiguration(
    rules: rules,
    defaultGroup:
        defaultIds == null ? null : TrackerGroup('fixture-default', defaultIds),
  );
  return _RoutingSetup(
    event,
    RoutingEngine(configuration),
    (input['availableTrackers'] as List).cast<String>().toSet(),
  );
}

RoutingRule _ruleFromJson(Map<String, dynamic> json) {
  final targets = (json['targets'] as List).cast<String>();
  return RoutingRule(
    eventNamePattern: json['nameContains'] as String?,
    category: _category(json['category'] as String?),
    isDefault: json['default'] as bool? ?? false,
    targetGroup: TrackerGroup('fixture', targets),
    requireConsent: json['requireConsent'] as bool? ?? false,
    requirePIIConsent: json['requirePIIConsent'] as bool? ?? false,
    priority: json['priority'] as int? ?? 0,
  );
}

EventCategory? _category(String? value) =>
    value == null ? null : EventCategory(value);

Map<String, Object> _objectProperties(Object? value) =>
    (value as Map<String, dynamic>).cast<String, Object>();

Map<String, dynamic> _readObject(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, dynamic>();

class _RoutingSetup {
  const _RoutingSetup(this.event, this.engine, this.availableTrackers);

  final BaseEvent event;
  final RoutingEngine engine;
  final Set<String> availableTrackers;
}

class _FixtureEvent extends BaseEvent {
  _FixtureEvent({
    required this.eventName,
    this.eventProperties,
    this.eventCategory,
    this.eventContainsPII = false,
    this.eventRequiresConsent = true,
    super.eventId,
    super.timestamp,
  });

  factory _FixtureEvent.fromJson(Map<String, dynamic> json) => _FixtureEvent(
        eventName: json['name'] as String,
        eventProperties: json['properties'] == null
            ? null
            : _objectProperties(json['properties']),
        eventCategory: _category(json['category'] as String?),
        eventContainsPII: json['containsPII'] as bool? ?? false,
        eventRequiresConsent: json['requiresConsent'] as bool? ?? true,
        eventId: json['eventId'] as String?,
        timestamp: json['timestamp'] == null
            ? null
            : DateTime.parse(json['timestamp'] as String),
      );

  final String eventName;
  final Map<String, Object>? eventProperties;
  final EventCategory? eventCategory;
  final bool eventContainsPII;
  final bool eventRequiresConsent;

  @override
  String get name => eventName;

  @override
  Map<String, Object>? get properties => eventProperties;

  @override
  EventCategory? get category => eventCategory;

  @override
  bool get containsPII => eventContainsPII;

  @override
  bool get requiresConsent => eventRequiresConsent;
}
