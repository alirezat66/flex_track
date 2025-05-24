import 'package:flutter/material.dart';
import 'package:flex_track/flex_track.dart';
import '../utils/gdpr_manager.dart';
import '../events/app_events.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Track settings screen view
    FlexTrack.track(PageViewEvent(
      pageName: 'settings',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Settings & Privacy',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 24),

          // Privacy Section
          _buildSectionHeader('Privacy & Consent'),
          _buildPrivacySection(),

          SizedBox(height: 32),

          // Analytics Section
          _buildSectionHeader('Analytics Configuration'),
          _buildAnalyticsSection(),

          SizedBox(height: 32),

          // Debug Section
          _buildSectionHeader('Debug & Testing'),
          _buildDebugSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildPrivacySection() {
    final consent = GDPRManager.currentConsent;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Consent Status
            if (consent != null) ...[
              Text('Current Consent Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _consentStatusRow(
                  'Analytics & Performance', consent.hasGeneralConsent),
              _consentStatusRow('Personalization', consent.hasPIIConsent),
              _consentStatusRow('Marketing', consent.hasMarketingConsent),
              SizedBox(height: 8),
              Text(
                'Last updated: ${_formatDate(consent.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 16),
            ] else ...[
              Text(
                'No consent preferences set',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 16),
            ],

            // Privacy Actions
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updateConsent(),
                    child: Text('Update Privacy Preferences'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _revokeAllConsent(),
                    child: Text('Revoke All Consent'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _resetUserData(),
                    child: Text('Reset All Data'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FlexTrack Status
            Text('FlexTrack Status:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _statusRow('Setup', FlexTrack.isSetUp),
            _statusRow('Enabled', FlexTrack.isEnabled),

            SizedBox(height: 16),

            // Trackers Status
            Text('Registered Trackers:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...FlexTrack.getTrackerIds()
                .map((id) => _statusRow(id, FlexTrack.isTrackerEnabled(id))),

            SizedBox(height: 16),

            // Analytics Actions
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: FlexTrack.isEnabled
                            ? _disableAnalytics
                            : _enableAnalytics,
                        child: Text(FlexTrack.isEnabled
                            ? 'Disable Analytics'
                            : 'Enable Analytics'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _flushEvents,
                        child: Text('Flush Events'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showDebugInfo,
                    child: Text('Show Debug Info'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug & Testing Tools',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _sendTestEvents,
                    child: Text('Send Test Events'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _testEventRouting,
                    child: Text('Test Event Routing'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _validateConfiguration,
                    child: Text('Validate Configuration'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _exportAnalyticsLog,
                    child: Text('Export Analytics Log'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _consentStatusRow(String label, bool granted) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(label),
          Spacer(),
          Text(
            status ? 'Active' : 'Inactive',
            style: TextStyle(
              color: status ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateConsent() async {
    // Track settings interaction
    FlexTrack.track(ButtonClickEvent(
      buttonId: 'update_consent',
      buttonText: 'Update Privacy Preferences',
      screenName: 'settings',
    ));

    await GDPRManager.showConsentDialog(context);
    setState(() {}); // Refresh UI
  }

  Future<void> _revokeAllConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke All Consent'),
        content: Text(
            'This will disable all analytics tracking except essential system events. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Revoke All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GDPRManager.revokeConsent();
      setState(() {});

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All consent revoked')),
      );
    }
  }

  Future<void> _resetUserData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset All Data'),
        content: Text(
            'This will clear all user data and analytics history. This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Track data reset before clearing
      FlexTrack.track(ButtonClickEvent(
        buttonId: 'reset_user_data',
        buttonText: 'Reset All Data',
        screenName: 'settings',
      ));

      await FlexTrack.resetTrackers();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All user data reset')),
      );
    }
  }

  void _enableAnalytics() {
    FlexTrack.enable();
    setState(() {});

    FlexTrack.track(ButtonClickEvent(
      buttonId: 'enable_analytics',
      buttonText: 'Enable Analytics',
      screenName: 'settings',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Analytics enabled')),
    );
  }

  void _disableAnalytics() {
    FlexTrack.track(ButtonClickEvent(
      buttonId: 'disable_analytics',
      buttonText: 'Disable Analytics',
      screenName: 'settings',
    ));

    FlexTrack.disable();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Analytics disabled')),
    );
  }

  Future<void> _flushEvents() async {
    FlexTrack.track(ButtonClickEvent(
      buttonId: 'flush_events',
      buttonText: 'Flush Events',
      screenName: 'settings',
    ));

    await FlexTrack.flush();

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Events flushed')),
    );
  }

  void _showDebugInfo() {
    final debugInfo = FlexTrack.getDebugInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('FlexTrack Debug Info'),
        content: SingleChildScrollView(
          child: Text(
            debugInfo.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestEvents() async {
    // Send a variety of test events
    final events = [
      ButtonClickEvent(
        buttonId: 'test_button',
        buttonText: 'Test Button',
        screenName: 'settings',
      ),
      ErrorEvent(
        errorType: 'test_error',
        errorMessage: 'This is a test error',
        context: 'settings_screen',
      ),
      PerformanceEvent(
        metricName: 'test_metric',
        value: 123.45,
        unit: 'ms',
        context: 'settings_test',
      ),
    ];

    for (final event in events) {
      await FlexTrack.track(event);
    }

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${events.length} test events sent')),
    );
  }

  void _testEventRouting() {
    // Test different event routing scenarios
    final testEvent = ButtonClickEvent(
      buttonId: 'routing_test',
      buttonText: 'Routing Test',
      screenName: 'settings',
    );

    final debugInfo = FlexTrack.debugEvent(testEvent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Event Routing Test'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Event: ${testEvent.getName()}'),
              SizedBox(height: 8),
              Text(
                  'Target Trackers: ${debugInfo.routingResult.targetTrackers.join(', ')}'),
              SizedBox(height: 8),
              Text(
                  'Applied Rules: ${debugInfo.routingResult.appliedRules.length}'),
              SizedBox(height: 8),
              Text('Warnings: ${debugInfo.routingResult.warnings.length}'),
              if (debugInfo.routingResult.warnings.isNotEmpty) ...[
                SizedBox(height: 8),
                Text('Warning Details:'),
                ...debugInfo.routingResult.warnings.map((w) => Text('• $w')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _validateConfiguration() {
    final issues = FlexTrack.validate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configuration Validation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (issues.isEmpty) ...[
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(height: 8),
                Text('✅ Configuration is valid!'),
              ] else ...[
                Icon(Icons.warning, color: Colors.orange, size: 32),
                SizedBox(height: 8),
                Text('Found ${issues.length} issue(s):'),
                SizedBox(height: 8),
                ...issues.map((issue) => Text('• $issue')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportAnalyticsLog() {
    // In a real app, this would export actual logs
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Analytics Log'),
        content: Text(
            'Analytics log export is not implemented in this demo. In a real app, this would export event logs, configuration, and debug information.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
