import 'package:flutter/material.dart';
import '../../models/drink_preset.dart';

class AddPresetDialog extends StatefulWidget {
  final DrinkPreset? preset;

  const AddPresetDialog({super.key, this.preset});

  @override
  State<AddPresetDialog> createState() => _AddPresetDialogState();
}

class _AddPresetDialogState extends State<AddPresetDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String _selectedIcon = '💧';
  String? _errorMessage;

  final List<String> _availableIcons = [
    '💧',
    '🥛',
    '🍶',
    '🍵',
    '☕',
    '🧃',
    '🥤',
    '🏋️',
    '⚽',
    '🏃',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _amountController = TextEditingController(
      text: widget.preset?.amount.toInt().toString() ?? '',
    );
    _selectedIcon = widget.preset?.icon ?? '💧';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.preset == null ? 'Add Preset' : 'Edit Preset'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'My Bottle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (ml)',
                hintText: '500',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Icon',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text(widget.preset == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _handleSave() {
    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();

    if (name.isEmpty || name.length < 2) {
      setState(() {
        _errorMessage = 'Name must be at least 2 characters';
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    if (amount < 50 || amount > 2000) {
      setState(() {
        _errorMessage = 'Amount must be between 50ml and 2000ml';
      });
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'amount': amount,
      'icon': _selectedIcon,
    });
  }
}
