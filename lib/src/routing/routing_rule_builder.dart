import 'package:flex_track/src/models/event/base_event.dart';

import '../models/routing/routing_rule.dart';
import '../models/routing/tracker_group.dart';
import '../exceptions/configuration_exception.dart';
import 'routing_builder.dart';
import 'route_config_builder.dart';

/// Builder for configuring routing rule properties and conditions
class RoutingRuleBuilder {
  final RoutingBuilder _parent;
  final RouteConfigBuilder _config;
  final TrackerGroup _targetGroup;

  double _sampleRate = 1.0;
  bool _requireConsent = true;
  bool _debugOnly = false;
  bool _productionOnly = false;
  bool _requirePIIConsent = false;
  int _priority = 0;
  String? _description;
  String? _id;

  RoutingRuleBuilder(this._parent, this._config, this._targetGroup);

  // ========== RULE MODIFIERS ==========

  /// Set sampling rate (0.0 to 1.0)
  RoutingRuleBuilder sample(double rate) {
    if (rate < 0.0 || rate > 1.0) {
      throw ConfigurationException(
        'Sample rate must be between 0.0 and 1.0, got $rate',
        fieldName: 'sampleRate',
      );
    }
    _sampleRate = rate;
    return this;
  }

  /// Require user consent
  RoutingRuleBuilder requireConsent() {
    _requireConsent = true;
    return this;
  }

  /// Skip consent requirement
  RoutingRuleBuilder skipConsent() {
    _requireConsent = false;
    return this;
  }

  /// Only send in debug mode
  RoutingRuleBuilder onlyInDebug() {
    _debugOnly = true;
    _productionOnly = false; // Can't be both
    return this;
  }

  /// Only send in production mode
  RoutingRuleBuilder onlyInProduction() {
    _productionOnly = true;
    _debugOnly = false; // Can't be both
    return this;
  }

  /// Require specific PII consent
  RoutingRuleBuilder requirePIIConsent() {
    _requirePIIConsent = true;
    return this;
  }

  /// Set rule priority (higher = more important)
  RoutingRuleBuilder withPriority(int priority) {
    _priority = priority;
    return this;
  }

  /// Set rule description for debugging
  RoutingRuleBuilder withDescription(String description) {
    if (description.isEmpty) {
      throw ConfigurationException(
        'Description cannot be empty',
        fieldName: 'description',
      );
    }
    _description = description;
    return this;
  }

  /// Set rule ID for identification
  RoutingRuleBuilder withId(String id) {
    if (id.isEmpty) {
      throw ConfigurationException(
        'Rule ID cannot be empty',
        fieldName: 'id',
      );
    }
    _id = id;
    return this;
  }

  // ========== CONVENIENCE METHODS ==========

  /// Set heavy sampling (1% of events)
  RoutingRuleBuilder heavySampling() => sample(0.01);

  /// Set light sampling (10% of events)
  RoutingRuleBuilder lightSampling() => sample(0.1);

  /// Set medium sampling (50% of events)
  RoutingRuleBuilder mediumSampling() => sample(0.5);

  /// Set no sampling (100% of events)
  RoutingRuleBuilder noSampling() => sample(1.0);

  /// Set high priority
  RoutingRuleBuilder highPriority() => withPriority(10);

  /// Set low priority
  RoutingRuleBuilder lowPriority() => withPriority(-10);

  /// Mark as essential (no consent required, no sampling)
  RoutingRuleBuilder essential() {
    return skipConsent().noSampling().highPriority();
  }

  // ========== CHAINING METHODS ==========

  /// Finish configuring this rule and return to main builder
  RoutingBuilder and() {
    _finalize();
    return _parent;
  }

  /// Finish configuring this rule and start a new route
  RouteConfigBuilder<T> andRoute<T extends BaseEvent>() {
    _finalize();
    return _parent.route<T>();
  }

  /// Finish configuring this rule and add a named route
  RouteConfigBuilder andRouteNamed(String pattern) {
    _finalize();
    return _parent.routeNamed(pattern);
  }

  /// Finish configuring this rule and add a regex route
  RouteConfigBuilder andRouteMatching(RegExp pattern) {
    _finalize();
    return _parent.routeMatching(pattern);
  }

  /// Finish configuring this rule and add default route
  RouteConfigBuilder andRouteDefault() {
    _finalize();
    return _parent.routeDefault();
  }

  // ========== FINALIZATION ==========

  /// Complete the rule and add it to the parent builder
  void _finalize() {
    final rule = RoutingRule(
      id: _id,
      eventType: _config.eventType,
      eventNamePattern: _config.eventNamePattern,
      eventNameRegex: _config.eventNameRegex,
      category: _config.category,
      hasProperty: _config.hasProperty,
      propertyValue: _config.propertyValue,
      containsPII: _config.containsPII,
      isHighVolume: _config.isHighVolume,
      isEssential: _config.isEssential,
      isDefault: _config.isDefault,
      targetGroup: _targetGroup,
      sampleRate: _sampleRate,
      requireConsent: _requireConsent,
      debugOnly: _debugOnly,
      productionOnly: _productionOnly,
      requirePIIConsent: _requirePIIConsent,
      priority: _priority,
      description: _description ?? _generateDescription(),
    );

    _parent.addRule(rule);
  }

  /// Generate a description if none was provided
  String _generateDescription() {
    final parts = <String>[];

    if (_config.eventType != null) {
      parts.add('${_config.eventType} events');
    } else if (_config.eventNamePattern != null) {
      parts.add('events containing "${_config.eventNamePattern}"');
    } else if (_config.eventNameRegex != null) {
      parts.add('events matching /${_config.eventNameRegex!.pattern}/');
    } else if (_config.category != null) {
      parts.add('${_config.category!.name} events');
    } else if (_config.isDefault) {
      parts.add('default routing');
    } else {
      parts.add('events');
    }

    parts.add('to ${_targetGroup.name}');

    if (_sampleRate < 1.0) {
      parts.add('(${(_sampleRate * 100).toStringAsFixed(1)}% sampled)');
    }

    if (_debugOnly) {
      parts.add('(debug only)');
    } else if (_productionOnly) {
      parts.add('(production only)');
    }

    return parts.join(' ');
  }
}
