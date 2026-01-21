// lib/features/auth/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../auth_model.dart';
import '../auth_widgets.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile when screen opens
    Future.microtask(() => ref.read(authProvider.notifier).loadProfile());
  }

  void _showEditWeightDialog(UserProfile profile) {
    final controller = TextEditingController(
      text: profile.weight?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Weight'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: '70',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(controller.text);
              if (weight == null || weight < 20 || weight > 300) {
                _showError('Weight must be between 20 and 300 kg');
                return;
              }

              Navigator.pop(context);

              // Store old profile for comparison
              final oldProfile = profile;

              // Update weight
              final success = await ref
                  .read(authProvider.notifier)
                  .updateProfile({'weight': weight});

              if (success && mounted) {
                _showSuccess('Weight updated');

                // Check if recalculation prompt is needed
                final newProfile = ref.read(authProvider).value?.profile;
                if (newProfile != null &&
                    ref
                        .read(authProvider.notifier)
                        .shouldPromptRecalculation(oldProfile)) {
                  _showRecalculationPrompt(oldProfile.dailyGoal ?? 0);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditActivityDialog(UserProfile profile) {
    String selectedActivity = profile.activityLevel ?? 'moderate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Activity Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Low (Sedentary)'),
                subtitle: const Text('Little to no exercise'),
                value: 'low',
                groupValue: selectedActivity,
                onChanged: (val) {
                  setDialogState(() => selectedActivity = val!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Moderate (Active)'),
                subtitle: const Text('Exercise 3-5 days/week'),
                value: 'moderate',
                groupValue: selectedActivity,
                onChanged: (val) {
                  setDialogState(() => selectedActivity = val!);
                },
              ),
              RadioListTile<String>(
                title: const Text('High (Very Active)'),
                subtitle: const Text('Intense exercise 6-7 days/week'),
                value: 'high',
                groupValue: selectedActivity,
                onChanged: (val) {
                  setDialogState(() => selectedActivity = val!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                // Store old profile for comparison
                final oldProfile = profile;

                // Update activity level
                final success = await ref
                    .read(authProvider.notifier)
                    .updateProfile({'activityLevel': selectedActivity});

                if (success && mounted) {
                  _showSuccess('Activity level updated');

                  // Check if recalculation prompt is needed
                  final newProfile = ref.read(authProvider).value?.profile;
                  if (newProfile != null &&
                      ref
                          .read(authProvider.notifier)
                          .shouldPromptRecalculation(oldProfile)) {
                    _showRecalculationPrompt(oldProfile.dailyGoal ?? 0);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHealthDialog(UserProfile profile) {
    final Map<String, bool> conditions = {
      'diabetic': profile.healthConditions.contains('diabetic'),
      'pregnant': profile.healthConditions.contains('pregnant'),
      'kidney': profile.healthConditions.contains('kidney'),
      'none': profile.healthConditions.isEmpty,
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Health Conditions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Diabetic'),
                value: conditions['diabetic'],
                onChanged: (val) {
                  setDialogState(() {
                    conditions['diabetic'] = val ?? false;
                    if (val == true) conditions['none'] = false;
                    if (!conditions.values.any((v) => v)) {
                      conditions['none'] = true;
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Pregnant'),
                value: conditions['pregnant'],
                onChanged: (val) {
                  setDialogState(() {
                    conditions['pregnant'] = val ?? false;
                    if (val == true) conditions['none'] = false;
                    if (!conditions.values.any((v) => v)) {
                      conditions['none'] = true;
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Kidney Issues'),
                value: conditions['kidney'],
                onChanged: (val) {
                  setDialogState(() {
                    conditions['kidney'] = val ?? false;
                    if (val == true) conditions['none'] = false;
                    if (!conditions.values.any((v) => v)) {
                      conditions['none'] = true;
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('None'),
                value: conditions['none'],
                onChanged: (val) {
                  setDialogState(() {
                    if (val == true) {
                      conditions.forEach((key, _) {
                        conditions[key] = key == 'none';
                      });
                    }
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                // Get selected conditions (excluding "none")
                final selected = conditions.entries
                    .where((e) => e.value && e.key != 'none')
                    .map((e) => e.key)
                    .toList();

                // Store old profile for comparison
                final oldProfile = profile;

                // Update health conditions
                final success = await ref
                    .read(authProvider.notifier)
                    .updateProfile({'healthConditions': selected});

                if (success && mounted) {
                  _showSuccess('Health conditions updated');

                  // Check if recalculation prompt is needed
                  final newProfile = ref.read(authProvider).value?.profile;
                  if (newProfile != null &&
                      ref
                          .read(authProvider.notifier)
                          .shouldPromptRecalculation(oldProfile)) {
                    _showRecalculationPrompt(oldProfile.dailyGoal ?? 0);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecalculationPrompt(int oldGoal) {
    final authAsync = ref.read(authProvider);

    authAsync.whenData((authState) {
      final profile = authState.profile;
      if (profile == null) return;

      // Calculate estimated new goal
      final estimatedNewGoal = ref
          .read(authProvider.notifier)
          .calculateDailyGoal(
            weight: profile.weight ?? 70,
            activityLevel: profile.activityLevel ?? 'moderate',
            healthConditions: profile.healthConditions,
          );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recalculate Goal?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your profile has changed. Would you like to recalculate your daily hydration goal?',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current goal:'),
                        Text(
                          '${oldGoal}ml',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated new goal:'),
                        Text(
                          '${estimatedNewGoal}ml',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _handleRecalculateGoal();
              },
              child: const Text('Yes, Recalculate'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _handleRecalculateGoal() async {
    final success = await ref
        .read(authProvider.notifier)
        .recalculateDailyGoal();

    if (success && mounted) {
      final authAsync = ref.read(authProvider);
      authAsync.whenData((state) {
        final newGoal = state.profile?.dailyGoal;
        _showSuccess('Goal updated to ${newGoal}ml');
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();

      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: authAsync.when(
        data: (authState) {
          final profile = authState.profile;

          if (authState.isLoading && profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profile == null) {
            return const Center(child: Text('No profile data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header
                _buildProfileHeader(profile),

                const SizedBox(height: 32),

                // Personal Information section
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 12),
                _buildInfoCard(profile),

                const SizedBox(height: 24),

                // Hydration Goals section
                _buildSectionTitle('Hydration Goals'),
                const SizedBox(height: 12),
                _buildGoalsCard(profile),

                const SizedBox(height: 32),

                // Logout button
                AuthButton(
                  text: 'Logout',
                  onPressed: _handleLogout,
                  backgroundColor: Colors.red,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            'Weight',
            '${profile.weight?.toStringAsFixed(1) ?? 'Not set'} kg',
            Icons.monitor_weight_outlined,
            () => _showEditWeightDialog(profile),
          ),
          _buildDivider(),
          _buildInfoTile(
            'Activity Level',
            profile.activityDisplayName,
            Icons.directions_run,
            () => _showEditActivityDialog(profile),
          ),
          _buildDivider(),
          _buildInfoTile(
            'Health Conditions',
            profile.healthConditionsDisplay,
            Icons.health_and_safety_outlined,
            () => _showEditHealthDialog(profile),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Goal',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${profile.dailyGoal ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'ml',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleRecalculateGoal,
              icon: const Icon(Icons.refresh),
              label: const Text('Recalculate Goal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade300);
  }
}
