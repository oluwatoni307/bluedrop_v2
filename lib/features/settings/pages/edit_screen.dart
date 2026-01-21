// features/settings/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_profile_repo.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // --- DATA LOADING ---

  Future<void> _loadProfileData() async {
    // Fetch data directly from DB Service (Bypassing AuthProvider to avoid router resets)
    final data = await ref.read(userDbServiceProvider).getUserProfile();

    if (mounted) {
      setState(() {
        _profile = data ?? {};
        _isLoading = false;
      });
    }
  }

  // --- SAVE ACTIONS ---

  Future<void> _updateField(Map<String, dynamic> updates) async {
    setState(() => _isLoading = true);
    try {
      // 1. Save to DB
      await ref.read(userDbServiceProvider).updateUserProfile(updates);

      // 2. Update Local State (So UI refreshes instantly)
      if (mounted) {
        setState(() {
          _profile = {..._profile, ...updates};
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- HELPER: GOAL CALCULATION ---
  int _calculateGoal({
    required double weight,
    required String activityLevel,
    required List<String> conditions,
  }) {
    // Base: 35ml per kg
    double goal = weight * 35;

    // Activity Multiplier
    if (activityLevel == 'moderate') goal += 500;
    if (activityLevel == 'high') goal += 1000;

    // Health Conditions
    if (conditions.contains('pregnant')) goal += 300;

    return goal.round();
  }

  // --- DIALOGS ---

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _profile['name'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().length < 2) return;
              Navigator.pop(context);
              _updateField({'name': controller.text.trim()});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditWeightDialog() {
    final currentWeight = _profile['weight']?.toString() ?? '';
    final controller = TextEditingController(text: currentWeight);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight == null || weight < 20 || weight > 300) return;

              Navigator.pop(context);
              _updateField({'weight': weight});

              // Trigger recalculation check
              _checkRecalculation(
                weight,
                _profile['activityLevel'] ?? 'moderate',
                [],
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditActivityDialog() {
    String selected = _profile['activityLevel'] ?? 'moderate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Activity Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadio(
                setDialogState,
                'Low (Sedentary)',
                'low',
                selected,
                (val) => selected = val,
              ),
              _buildRadio(
                setDialogState,
                'Moderate (Active)',
                'moderate',
                selected,
                (val) => selected = val,
              ),
              _buildRadio(
                setDialogState,
                'High (Very Active)',
                'high',
                selected,
                (val) => selected = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateField({'activityLevel': selected});

                // Trigger recalculation check
                final weight = (_profile['weight'] as num?)?.toDouble() ?? 70.0;
                _checkRecalculation(weight, selected, []);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog() {
    final currentGoal = _profile['dailyGoal']?.toString() ?? '2000';
    final controller = TextEditingController(text: currentGoal);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Daily Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended: 2000 - 3000 ml',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Goal (ml)',
                border: OutlineInputBorder(),
                suffixText: 'ml',
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val == null || val < 500 || val > 10000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid goal (500-10000)'),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              _updateField({'dailyGoal': val});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(
    StateSetter setDialogState,
    String title,
    String value,
    String groupValue,
    Function(String) onChanged,
  ) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        setDialogState(() => onChanged(val!));
      },
    );
  }

  // --- RECALCULATION LOGIC ---

  void _checkRecalculation(
    double weight,
    String activity,
    List<String> conditions,
  ) {
    final currentGoal = (_profile['dailyGoal'] as num?)?.toInt() ?? 2000;
    final newGoal = _calculateGoal(
      weight: weight,
      activityLevel: activity,
      conditions: conditions,
    );

    // Only prompt if the difference is significant (> 100ml)
    if ((currentGoal - newGoal).abs() > 100) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showRecalculateDialog(currentGoal, newGoal);
      });
    }
  }

  void _showRecalculateDialog(int oldGoal, int newGoal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Goal?'),
        content: Text(
          'Based on your new profile, your recommended hydration goal is $newGoal ml (was $oldGoal ml).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Old'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateField({'dailyGoal': newGoal});
            },
            child: const Text('Update Goal'),
          ),
        ],
      ),
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Safely extract values
    final name = _profile['name'] as String? ?? 'User';
    final email = _profile['email'] as String? ?? 'No Email';
    final weight = _profile['weight']?.toString() ?? 'Not set';
    final activity = _profile['activityLevel'] ?? 'moderate';
    final goal = _profile['dailyGoal']?.toString() ?? '2000';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            _buildProfileHeader(name, email),
            const SizedBox(height: 32),

            // Personal Info Section
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    'Name',
                    name,
                    Icons.person_outline,
                    _showEditNameDialog,
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    'Weight',
                    '$weight kg',
                    Icons.monitor_weight_outlined,
                    _showEditWeightDialog,
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    'Activity Level',
                    activity.toString().toUpperCase(),
                    Icons.directions_run,
                    _showEditActivityDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hydration Goals Section
            _buildSectionTitle('Hydration Goals'),
            const SizedBox(height: 12),

            // Tappable Goal Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showEditGoalDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Side: Label + Edit Icon
                      Row(
                        children: [
                          const Text(
                            'Daily Goal',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),

                      // Right Side: Big Number
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            goal,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            ' ml',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20)
          : null,
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade300);
}
