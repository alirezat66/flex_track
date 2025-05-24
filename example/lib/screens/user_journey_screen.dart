import 'package:flutter/material.dart';
import 'package:flex_track/flex_track.dart';
import '../events/user_events.dart';
import '../events/app_events.dart';

class UserJourneyScreen extends StatefulWidget {
  const UserJourneyScreen({super.key});
  @override
  @override
  UserJourneyScreenState createState() => UserJourneyScreenState();
}

class UserJourneyScreenState extends State<UserJourneyScreen> {
  bool _isLoggedIn = false;
  String? _userName;
  int _currentStep = 0;
  final DateTime _sessionStartTime = DateTime.now();

  final List<String> _journeySteps = [
    'Welcome',
    'Registration',
    'Profile Setup',
    'Feature Discovery',
    'Engagement',
  ];

  @override
  void initState() {
    super.initState();
    // Track screen view
    FlexTrack.track(PageViewEvent(
      pageName: 'user_journey',
      parameters: {'journey_step': _journeySteps[_currentStep]},
    ));

    // Track session start
    FlexTrack.track(UserEngagementEvent(
      engagementType: 'session_start',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Text(
              'User Journey Demo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_currentStep + 1) / _journeySteps.length,
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 8),
            Text(
              'Step ${_currentStep + 1} of ${_journeySteps.length}: ${_journeySteps[_currentStep]}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 24),

            // Journey Content
            Expanded(
              child: _buildStepContent(),
            ),

            // Navigation Buttons
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep < _journeySteps.length - 1
                        ? _nextStep
                        : _completeJourney,
                    child: Text(
                      _currentStep < _journeySteps.length - 1
                          ? 'Next'
                          : 'Complete Journey',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildRegistrationStep();
      case 2:
        return _buildProfileStep();
      case 3:
        return _buildFeatureDiscoveryStep();
      case 4:
        return _buildEngagementStep();
      default:
        return Container();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        Icon(Icons.waving_hand, size: 80, color: Colors.orange),
        SizedBox(height: 24),
        Text(
          'Welcome to FlexTrack!',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'This demo shows how to track user journeys and engagement patterns with FlexTrack.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            FlexTrack.track(ButtonClickEvent(
              buttonId: 'welcome_cta',
              buttonText: 'Get Started',
              screenName: 'user_journey',
            ));
          },
          child: Text('Get Started'),
        ),
      ],
    );
  }

  Widget _buildRegistrationStep() {
    return Column(
      children: [
        Icon(Icons.person_add, size: 80, color: Colors.blue),
        SizedBox(height: 24),
        Text(
          'User Registration',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Track user registration events with different methods and consent options.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _simulateRegistration('email'),
                icon: Icon(Icons.email),
                label: Text('Register with Email'),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _simulateRegistration('google'),
                icon: Icon(Icons.g_mobiledata),
                label: Text('Register with Google'),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _simulateRegistration('apple'),
                icon: Icon(Icons.apple),
                label: Text('Register with Apple'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      children: [
        Icon(Icons.account_circle, size: 80, color: Colors.green),
        SizedBox(height: 24),
        Text(
          'Profile Setup',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Track profile completion and user property updates.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (_isLoggedIn) ...[
          SizedBox(height: 24),
          Text('Welcome, $_userName!',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 16),
        ],
        SizedBox(height: 24),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _setUserProperties,
                child: Text('Set User Properties'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureDiscoveryStep() {
    return Column(
      children: [
        Icon(Icons.explore, size: 80, color: Colors.purple),
        SizedBox(height: 24),
        Text(
          'Feature Discovery',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Track how users discover and interact with app features.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _FeatureButton(
              name: 'Analytics Dashboard',
              onPressed: () => _useFeature('analytics_dashboard'),
            ),
            _FeatureButton(
              name: 'Export Data',
              onPressed: () => _useFeature('export_data'),
            ),
            _FeatureButton(
              name: 'Team Collaboration',
              onPressed: () => _useFeature('team_collaboration'),
            ),
            _FeatureButton(
              name: 'Advanced Filters',
              onPressed: () => _useFeature('advanced_filters'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEngagementStep() {
    final sessionDuration =
        DateTime.now().difference(_sessionStartTime).inSeconds;

    return Column(
      children: [
        Icon(Icons.favorite, size: 80, color: Colors.red),
        SizedBox(height: 24),
        Text(
          'User Engagement',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Track engagement metrics and user satisfaction.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Session Duration: ${sessionDuration}s'),
                SizedBox(height: 8),
                Text(
                    'Journey Progress: ${((_currentStep + 1) / _journeySteps.length * 100).toInt()}%'),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _trackDeepEngagement,
                child: Text('Track Deep Engagement'),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _simulateChurn,
                child: Text('Simulate Churn Risk'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _simulateRegistration(String method) {
    setState(() {
      _isLoggedIn = true;
      _userName = 'Demo User';
    });

    FlexTrack.track(UserRegistrationEvent(
      registrationMethod: method,
      hasAcceptedTerms: true,
      hasAcceptedMarketing: method != 'apple', // Apple users typically opt out
    ));

    // Identify the user
    FlexTrack.identifyUser('demo_user_123', {
      'registration_method': method,
      'signup_date': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration tracked ($method)')),
    );
  }

  void _updateProfile() {
    FlexTrack.track(UserProfileUpdateEvent(
      updatedFields: ['name', 'bio', 'preferences'],
      isComplete: true,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile update tracked')),
    );
  }

  void _setUserProperties() {
    FlexTrack.setUserProperties({
      'plan_type': 'premium',
      'team_size': 5,
      'industry': 'technology',
      'last_active': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User properties set')),
    );
  }

  void _useFeature(String featureName) {
    FlexTrack.track(FeatureUsageEvent(
      featureName: featureName,
      action: 'start',
      context: {'source': 'user_journey_demo'},
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feature usage tracked: $featureName')),
    );
  }

  void _trackDeepEngagement() {
    final sessionDuration =
        DateTime.now().difference(_sessionStartTime).inSeconds;

    FlexTrack.track(UserEngagementEvent(
      engagementType: 'deep_engagement',
      sessionDuration: sessionDuration,
      screenCount: _currentStep + 1,
      actionCount: 10, // Mock action count
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deep engagement tracked')),
    );
  }

  void _simulateChurn() {
    FlexTrack.track(UserEngagementEvent(
      engagementType: 'churn_risk',
      sessionDuration: DateTime.now().difference(_sessionStartTime).inSeconds,
      screenCount: _currentStep + 1,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Churn risk event tracked')),
    );
  }

  void _nextStep() {
    if (_currentStep < _journeySteps.length - 1) {
      setState(() {
        _currentStep++;
      });

      FlexTrack.track(PageViewEvent(
        pageName: 'user_journey',
        parameters: {
          'journey_step': _journeySteps[_currentStep],
          'step_number': _currentStep.toString(),
        },
      ));
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });

      FlexTrack.track(PageViewEvent(
        pageName: 'user_journey',
        parameters: {
          'journey_step': _journeySteps[_currentStep],
          'step_number': _currentStep.toString(),
          'direction': 'back',
        },
      ));
    }
  }

  void _completeJourney() {
    final sessionDuration =
        DateTime.now().difference(_sessionStartTime).inSeconds;

    FlexTrack.track(UserEngagementEvent(
      engagementType: 'journey_complete',
      sessionDuration: sessionDuration,
      screenCount: _journeySteps.length,
    ));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Journey Complete!'),
        content: Text(
            'You\'ve completed the user journey demo.\n\nSession duration: ${sessionDuration}s'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentStep = 0;
              });
            },
            child: Text('Restart'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;

  const _FeatureButton({
    required this.name,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(name),
    );
  }
}
