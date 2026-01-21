import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../water_log.dart';
import '../water_logs_provider.dart';

class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(waterLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Presets'), centerTitle: true),
      body: stateAsync.when(
        data: (state) => state.presets.isEmpty
            ? _buildEmptyState(context, ref)
            : _buildPresetsList(context, ref, state.presets),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(waterLogsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: stateAsync.when(
        data: (state) => state.presets.length >= MAX_PRESETS
            ? null
            : FloatingActionButton(
                onPressed: () => _showAddPresetDialog(context, ref),
                child: const Icon(Icons.add),
              ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No presets yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first preset',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsList(
    BuildContext context,
    WidgetRef ref,
    List<WaterPreset> presets,
  ) {
    return Column(
      children: [
        // Instruction banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Long press and drag to reorder',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
        // Reorderable list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: presets.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.mediumImpact();
              _handleReorder(ref, presets, oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Material(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final preset = presets[index];
              return Card(
                key: ValueKey(preset.id),
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.drag_handle,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(preset.icon, style: const TextStyle(fontSize: 32)),
                    ],
                  ),
                  title: Text(
                    preset.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${preset.amount}ml ${DRINK_TYPE_LABELS[preset.drinkType] ?? preset.drinkType}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showEditPresetDialog(context, ref, preset),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, ref, preset),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleReorder(
    WidgetRef ref,
    List<WaterPreset> presets,
    int oldIndex,
    int newIndex,
  ) {
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Create new list with reordered items
    final updatedPresets = List<WaterPreset>.from(presets);
    final item = updatedPresets.removeAt(oldIndex);
    updatedPresets.insert(newIndex, item);

    // Update the order in the provider
    ref.read(waterLogsProvider.notifier).reorderPresets(updatedPresets);
  }

  void _showAddPresetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _PresetDialog(
        onSave: (label, amount, type) async {
          try {
            final preset = WaterPreset(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              label: label,
              amount: amount,
              drinkType: type,
            );
            await ref.read(waterLogsProvider.notifier).addPreset(preset);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preset added'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditPresetDialog(
    BuildContext context,
    WidgetRef ref,
    WaterPreset preset,
  ) {
    showDialog(
      context: context,
      builder: (_) => _PresetDialog(
        existingPreset: preset,
        onSave: (label, amount, type) async {
          try {
            final updated = WaterPreset(
              id: preset.id,
              label: label,
              amount: amount,
              drinkType: type,
            );
            await ref
                .read(waterLogsProvider.notifier)
                .updatePreset(preset.id, updated);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preset updated'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WaterPreset preset) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: Text('Remove "${preset.label}" from your presets?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(), // ✅ UPDATED
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop(); // ✅ UPDATED
              try {
                await ref
                    .read(waterLogsProvider.notifier)
                    .deletePreset(preset.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preset deleted'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ========== PRESET DIALOG (ADD/EDIT) ==========

class _PresetDialog extends StatefulWidget {
  final WaterPreset? existingPreset;
  final Function(String label, int amount, String type) onSave;

  const _PresetDialog({this.existingPreset, required this.onSave});

  @override
  State<_PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends State<_PresetDialog> {
  late TextEditingController _labelController;
  late TextEditingController _amountController;
  late String _selectedType;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.existingPreset?.label ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingPreset?.amount.toString() ?? '',
    );
    _selectedType = widget.existingPreset?.drinkType ?? 'water';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final label = _labelController.text.trim();
    final amountText = _amountController.text.trim();

    if (label.isEmpty) {
      setState(() => _errorMessage = 'Please enter a label');
      return;
    }

    if (amountText.isEmpty) {
      setState(() => _errorMessage = 'Please enter amount');
      return;
    }

    final amount = int.tryParse(amountText);

    if (amount == null) {
      setState(() => _errorMessage = 'Invalid amount');
      return;
    }

    if (amount < 50) {
      setState(() => _errorMessage = 'Minimum 50ml');
      return;
    }

    if (amount > 2000) {
      setState(() => _errorMessage = 'Maximum 2000ml');
      return;
    }

    context.pop(); // ✅ UPDATED
    widget.onSave(label, amount, _selectedType);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingPreset == null ? 'Add Preset' : 'Edit Preset'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Label',
              hintText: 'e.g., Morning Water',
              border: const OutlineInputBorder(),
              errorText: _errorMessage?.contains('label') == true
                  ? _errorMessage
                  : null,
            ),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Amount (ml)',
              hintText: '250',
              border: const OutlineInputBorder(),
              suffixText: 'ml',
              errorText:
                  _errorMessage?.contains('amount') == true ||
                      _errorMessage?.contains('ml') == true
                  ? _errorMessage
                  : null,
            ),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Drink Type',
              border: OutlineInputBorder(),
            ),
            items: DRINK_TYPES.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(DRINK_TYPE_LABELS[type] ?? type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(), // ✅ UPDATED
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _handleSave, child: const Text('Save')),
      ],
    );
  }
}
