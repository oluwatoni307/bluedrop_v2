// lib/features/auth/screens/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../auth_widgets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _weightController = TextEditingController();
  String _selectedActivity = 'moderate'; // Default
  final Map<String, bool> _healthConditions = {
    'diabetic': false,
    'pregnant': false,
    'kidney': false,
    'none': false,
  };

  int? _estimatedGoal;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculateEstimatedGoal() {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      setState(() => _estimatedGoal = null);
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight < 20 || weight > 300) {
      setState(() => _estimatedGoal = null);
      return;
    }

    // Get selected health conditions
    final selectedConditions = _healthConditions.entries
        .where((e) => e.value && e.key != 'none')
        .map((e) => e.key)
        .toList();

    // Calculate using provider's method
    final goal = ref
        .read(authProvider.notifier)
        .calculateDailyGoal(
          weight: weight,
          activityLevel: _selectedActivity,
          healthConditions: selectedConditions,
        );

    setState(() => _estimatedGoal = goal);
  }

  void _onHealthConditionChanged(String condition, bool? value) {
    setState(() {
      if (condition == 'none') {
        // If "None" is selected, uncheck all others
        if (value == true) {
          _healthConditions.forEach((key, _) {
            _healthConditions[key] = key == 'none';
          });
        }
      } else {
        // If any condition is selected, uncheck "None"
        _healthConditions[condition] = value ?? false;
        if (value == true) {
          _healthConditions['none'] = false;
        }

        // If all conditions are unchecked, check "None"
        final anySelected = _healthConditions.entries
            .where((e) => e.key != 'none')
            .any((e) => e.value);
        if (!anySelected) {
          _healthConditions['none'] = true;
        }
      }
    });

    _calculateEstimatedGoal();
  }

  Future<void> _handleContinue() async {
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      _showError('Please enter your weight');
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight < 20 || weight > 300) {
      _showError('Weight must be between 20 and 300 kg');
      return;
    }

    // Get selected health conditions (excluding "none")
    final selectedConditions = _healthConditions.entries
        .where((e) => e.value && e.key != 'none')
        .map((e) => e.key)
        .toList();

    // Call provider to complete setup
    final success = await ref
        .read(authProvider.notifier)
        .completeProfileSetup(
          weight: weight,
          activityLevel: _selectedActivity,
          healthConditions: selectedConditions,
        );

    if (success && mounted) {
      // Navigate to HomePage
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    // Show error in SnackBar when error changes
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      next.whenData((state) {
        if (state.error != null && state.error!.isNotEmpty && mounted) {
          _showError(state.error!);
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Can't go back - setup is mandatory
        title: const Text(
          'Profile Setup',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // This sets isAuthenticated = false, and the Router sends them to /login
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: authAsync.when(
        data: (authState) => LoadingOverlay(
          isLoading: authState.isLoading,
          message: 'Setting up your profile...',
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Let\'s personalize your hydration goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'We\'ll calculate your daily goal based on this information',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 32),

                  // Weight input
                  CustomTextField(
                    label: 'Weight (kg)',
                    hint: '70',
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}'),
                      ),
                    ],
                    onChanged: (_) => _calculateEstimatedGoal(),
                  ),

                  const SizedBox(height: 24),

                  // Activity level selector
                  ActivitySelector(
                    selectedActivity: _selectedActivity,
                    onChanged: (activity) {
                      setState(() => _selectedActivity = activity);
                      _calculateEstimatedGoal();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Health conditions
                  const Text(
                    'Health Conditions (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Select any that apply to adjust your hydration needs',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        HealthConditionCheckbox(
                          label: 'Diabetic',
                          value: _healthConditions['diabetic']!,
                          onChanged: (val) =>
                              _onHealthConditionChanged('diabetic', val),
                        ),
                        HealthConditionCheckbox(
                          label: 'Pregnant',
                          value: _healthConditions['pregnant']!,
                          onChanged: (val) =>
                              _onHealthConditionChanged('pregnant', val),
                        ),
                        HealthConditionCheckbox(
                          label: 'Kidney Issues',
                          value: _healthConditions['kidney']!,
                          onChanged: (val) =>
                              _onHealthConditionChanged('kidney', val),
                        ),
                        HealthConditionCheckbox(
                          label: 'None',
                          value: _healthConditions['none']!,
                          onChanged: (val) =>
                              _onHealthConditionChanged('none', val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Estimated goal display
                  if (_estimatedGoal != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your estimated daily goal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _estimatedGoal!.toString(),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'ml',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can adjust this anytime in your profile',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Continue button
                  AuthButton(
                    text: 'Continue',
                    onPressed: _handleContinue,
                    isLoading: authState.isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Info text
                  Text(
                    'This information helps us calculate your personalized hydration goal based on scientific recommendations.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
