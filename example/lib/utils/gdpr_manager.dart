import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flex_track/flex_track.dart';

/// Mock SharedPreferences since we don't want to add dependencies
class MockSharedPreferences {
  static final Map<String, String> _storage = {};

  String? getString(String key) => _storage[key];

  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  static Future<MockSharedPreferences> getInstance() async {
    return MockSharedPreferences();
  }
}

class GDPRManager {
  static const String _consentKey = 'gdpr_consent';
  static const String _consentVersionKey = 'gdpr_consent_version';
  static const String _currentConsentVersion = '2.0';

  static late MockSharedPreferences _prefs;
  static ConsentStatus? _currentConsent;

  static Future<void> initialize() async {
    _prefs = await MockSharedPreferences.getInstance();
    await _loadConsent();
    _applyConsentToFlexTrack();
  }

  static Future<void> _loadConsent() async {
    final consentData = _prefs.getString(_consentKey);
    final savedVersion = _prefs.getString(_consentVersionKey);

    if (consentData != null && savedVersion == _currentConsentVersion) {
      _currentConsent = ConsentStatus.fromJson(consentData);
    } else {
      // Consent version changed or no consent saved
      _currentConsent = null;
    }
  }

  static ConsentStatus? get currentConsent => _currentConsent;

  static bool get hasValidConsent => _currentConsent != null;

  static bool get needsConsentUpdate => !hasValidConsent;

  static Future<void> updateConsent(ConsentStatus consent) async {
    _currentConsent = consent;

    await _prefs.setString(_consentKey, consent.toJson());
    await _prefs.setString(_consentVersionKey, _currentConsentVersion);

    _applyConsentToFlexTrack();

    // Track consent change
    await FlexTrack.track(ConsentChangeEvent(
      hasGeneralConsent: consent.hasGeneralConsent,
      hasPIIConsent: consent.hasPIIConsent,
      hasMarketingConsent: consent.hasMarketingConsent,
    ));
  }

  static void _applyConsentToFlexTrack() {
    if (_currentConsent != null) {
      FlexTrack.setConsent(
        general: _currentConsent!.hasGeneralConsent,
        pii: _currentConsent!.hasPIIConsent,
      );
    } else {
      // No consent - disable all tracking except essential
      FlexTrack.setConsent(general: false, pii: false);
    }
  }

  static Future<void> showConsentDialog(BuildContext context) async {
    if (hasValidConsent) return;

    final result = await showDialog<ConsentStatus>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConsentDialog(),
    );

    if (result != null) {
      await updateConsent(result);
    }
  }

  static Future<void> revokeConsent() async {
    _currentConsent = ConsentStatus(
      hasGeneralConsent: false,
      hasPIIConsent: false,
      hasMarketingConsent: false,
    );

    await updateConsent(_currentConsent!);
    await FlexTrack.resetTrackers(); // Clear all user data
  }
}

class ConsentStatus {
  final bool hasGeneralConsent;
  final bool hasPIIConsent;
  final bool hasMarketingConsent;
  final DateTime timestamp;

  ConsentStatus({
    required this.hasGeneralConsent,
    required this.hasPIIConsent,
    required this.hasMarketingConsent,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String toJson() {
    return jsonEncode({
      'general': hasGeneralConsent,
      'pii': hasPIIConsent,
      'marketing': hasMarketingConsent,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  static ConsentStatus fromJson(String json) {
    final data = jsonDecode(json);
    return ConsentStatus(
      hasGeneralConsent: data['general'] ?? false,
      hasPIIConsent: data['pii'] ?? false,
      hasMarketingConsent: data['marketing'] ?? false,
      timestamp: DateTime.parse(data['timestamp']),
    );
  }
}

class ConsentDialog extends StatefulWidget {
  const ConsentDialog({super.key});

  @override
  ConsentDialogState createState() => ConsentDialogState();
}

class ConsentDialogState extends State<ConsentDialog> {
  bool _generalConsent = false;
  bool _piiConsent = false;
  bool _marketingConsent = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Privacy Settings'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We respect your privacy. Please choose your preferences:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Analytics & Performance'),
              subtitle:
                  Text('Help us improve the app with anonymous usage data'),
              value: _generalConsent,
              onChanged: (value) =>
                  setState(() => _generalConsent = value ?? false),
            ),
            CheckboxListTile(
              title: Text('Personalization'),
              subtitle: Text('Personalized content and recommendations'),
              value: _piiConsent,
              onChanged: (value) =>
                  setState(() => _piiConsent = value ?? false),
            ),
            CheckboxListTile(
              title: Text('Marketing Communications'),
              subtitle: Text('Promotional emails and targeted advertising'),
              value: _marketingConsent,
              onChanged: (value) =>
                  setState(() => _marketingConsent = value ?? false),
            ),
            SizedBox(height: 16),
            Text(
              'Essential cookies and data processing are always active for core functionality.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(ConsentStatus(
              hasGeneralConsent: false,
              hasPIIConsent: false,
              hasMarketingConsent: false,
            ));
          },
          child: Text('Decline All'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _generalConsent = true;
              _piiConsent = true;
              _marketingConsent = true;
            });
          },
          child: Text('Accept All'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(ConsentStatus(
              hasGeneralConsent: _generalConsent,
              hasPIIConsent: _piiConsent,
              hasMarketingConsent: _marketingConsent,
            ));
          },
          child: Text('Save Preferences'),
        ),
      ],
    );
  }
}

/// Event to track consent changes
class ConsentChangeEvent extends BaseEvent {
  final bool hasGeneralConsent;
  final bool hasPIIConsent;
  final bool hasMarketingConsent;

  ConsentChangeEvent({
    required this.hasGeneralConsent,
    required this.hasPIIConsent,
    required this.hasMarketingConsent,
  });

  @override
  String get name => 'consent_change';

  @override
  Map<String, Object> get properties => {
        'general_consent': hasGeneralConsent,
        'pii_consent': hasPIIConsent,
        'marketing_consent': hasMarketingConsent,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.system;

  @override
  bool get isEssential => true; // Important for compliance

  @override
  bool get requiresConsent => false; // Legitimate interest
}
