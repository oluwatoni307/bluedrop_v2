// lib/features/auth/screens/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../auth_widgets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _weightController = TextEditingController();

  // State
  String _selectedActivity = 'moderate';
  String _selectedClimate = 'moderate'; // Default

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

    final selectedConditions = _healthConditions.entries
        .where((e) => e.value && e.key != 'none')
        .map((e) => e.key)
        .toList();

    // Passing the new 'climate' param
    final goal = ref
        .read(authProvider.notifier)
        .calculateDailyGoal(
          weight: weight,
          activityLevel: _selectedActivity,
          healthConditions: selectedConditions,
          climate: _selectedClimate,
        );

    setState(() => _estimatedGoal = goal);
  }

  void _onHealthConditionChanged(String condition, bool? value) {
    setState(() {
      if (condition == 'none') {
        if (value == true) {
          _healthConditions.forEach((key, _) {
            _healthConditions[key] = key == 'none';
          });
        }
      } else {
        _healthConditions[condition] = value ?? false;
        if (value == true) {
          _healthConditions['none'] = false;
        }

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

    final selectedConditions = _healthConditions.entries
        .where((e) => e.value && e.key != 'none')
        .map((e) => e.key)
        .toList();

    // Passing climate to complete setup
    final success = await ref
        .read(authProvider.notifier)
        .completeProfileSetup(
          weight: weight,
          activityLevel: _selectedActivity,
          healthConditions: selectedConditions,
          climate: _selectedClimate,
        );

    if (success && mounted) {
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile Setup',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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

                  // 1. Weight
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

                  // 2. Activity
                  ActivitySelector(
                    selectedActivity: _selectedActivity,
                    onChanged: (activity) {
                      setState(() => _selectedActivity = activity);
                      _calculateEstimatedGoal();
                    },
                  ),

                  const SizedBox(height: 24),

                  // 3. CLIMATE SELECTOR (Updated 3-State Logic)
                  const Text(
                    'Climate / Environment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temperature affects hydration needs',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // Option A: Moderate
                        RadioListTile<String>(
                          title: const Text('Moderate'),
                          subtitle: const Text('Standard conditions'),
                          value: 'moderate',
                          groupValue: _selectedClimate,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            setState(() => _selectedClimate = val!);
                            _calculateEstimatedGoal();
                          },
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),

                        // Option B: Hot
                        RadioListTile<String>(
                          title: const Text('Hot / Tropical'),
                          subtitle: const Text('High heat or humidity'),
                          value: 'hot',
                          groupValue: _selectedClimate,
                          activeColor: Colors.orange,
                          secondary: const Icon(
                            Icons.wb_sunny_outlined,
                            color: Colors.orange,
                          ),
                          onChanged: (val) {
                            setState(() => _selectedClimate = val!);
                            _calculateEstimatedGoal();
                          },
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),

                        // Option C: Cold (NEW)
                        RadioListTile<String>(
                          title: const Text('Cold / Dry'),
                          subtitle: const Text('Winter or heavy AC'),
                          value: 'cold',
                          groupValue: _selectedClimate,
                          activeColor: Colors.cyan,
                          secondary: const Icon(
                            Icons.ac_unit,
                            color: Colors.cyan,
                          ),
                          onChanged: (val) {
                            setState(() => _selectedClimate = val!);
                            _calculateEstimatedGoal();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Health
                  const Text(
                    'Health Conditions (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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

                  // 5. Goal Display
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
                            'Calculated based on weight, activity, and climate.',
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

                  AuthButton(
                    text: 'Continue',
                    onPressed: _handleContinue,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: 20),
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
