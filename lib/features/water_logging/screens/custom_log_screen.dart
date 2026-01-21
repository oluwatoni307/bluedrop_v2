import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../water_log.dart';

class CustomLogScreen extends StatefulWidget {
  // ✅ UPDATED: Make onLog optional to support both callback and pop-with-result patterns
  final Function(int amount, String drinkType)? onLog;

  const CustomLogScreen({super.key, this.onLog});

  @override
  State<CustomLogScreen> createState() => _CustomLogScreenState();
}

class _CustomLogScreenState extends State<CustomLogScreen> {
  String _displayAmount = '0';
  String _selectedType = 'water';
  bool _hasError = false;
  String? _errorMessage;

  void _onNumberTap(String number) {
    setState(() {
      _hasError = false;
      _errorMessage = null;

      if (_displayAmount == '0') {
        _displayAmount = number;
      } else if (_displayAmount.length < 4) {
        // Max 4 digits (9999ml)
        _displayAmount += number;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _hasError = false;
      _errorMessage = null;

      if (_displayAmount.length > 1) {
        _displayAmount = _displayAmount.substring(0, _displayAmount.length - 1);
      } else {
        _displayAmount = '0';
      }
    });
  }

  void _onClear() {
    setState(() {
      _displayAmount = '0';
      _hasError = false;
      _errorMessage = null;
    });
  }

  void _onQuickAmount(int amount) {
    setState(() {
      _displayAmount = amount.toString();
      _hasError = false;
      _errorMessage = null;
    });
  }

  void _onLog() {
    final amount = int.tryParse(_displayAmount);

    if (amount == null || amount == 0) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter an amount';
      });
      return;
    }

    if (amount < 50) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Minimum 50ml';
      });
      return;
    }

    if (amount > 2000) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Maximum 2000ml';
      });
      return;
    }

    // ✅ UPDATED: Support both patterns
    if (widget.onLog != null) {
      // Old pattern: Use callback (backward compatible)
      widget.onLog!(amount, _selectedType);
    } else {
      // New pattern: Pop with result for GoRouter
      context.pop({'amount': amount, 'type': _selectedType});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Amount'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Display Area
                      _buildDisplay(theme),
                      const SizedBox(height: 32),

                      // Drink Type Selector
                      _buildDrinkTypeSelector(),
                      const SizedBox(height: 32),

                      // Number Pad
                      _buildNumberPad(theme),
                      const SizedBox(height: 24),

                      // Quick Amount Buttons
                      _buildQuickAmounts(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions
            _buildBottomActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _hasError
            ? Colors.red.shade50
            : theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasError ? Colors.red : theme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _displayAmount,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: _hasError ? Colors.red : theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ml',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: _hasError
                      ? Colors.red.shade300
                      : theme.primaryColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          if (_hasError && _errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrinkTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: DRINK_TYPES.map((type) {
            final label = DRINK_TYPE_LABELS[type] ?? type;
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Text(_getIcon(type), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(label, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
            }
          },
        ),
      ),
    );
  }

  String _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'water':
        return '💧';
      case 'tea':
        return '🍵';
      case 'coffee':
        return '☕';
      case 'juice':
        return '🧃';
      case 'others':
        return '🥤';
      default:
        return '💧';
    }
  }

  Widget _buildNumberPad(ThemeData theme) {
    return Column(
      children: [
        _buildNumberRow(['1', '2', '3'], theme),
        const SizedBox(height: 12),
        _buildNumberRow(['4', '5', '6'], theme),
        const SizedBox(height: 12),
        _buildNumberRow(['7', '8', '9'], theme),
        const SizedBox(height: 12),
        _buildNumberRow(['⌫', '0', 'C'], theme),
      ],
    );
  }

  Widget _buildNumberRow(List<String> numbers, ThemeData theme) {
    return Row(
      children: numbers.map((number) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildNumberButton(number, theme),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberButton(String value, ThemeData theme) {
    final isBackspace = value == '⌫';
    final isClear = value == 'C';
    final isSpecial = isBackspace || isClear;

    return Material(
      color: isSpecial ? Colors.grey.shade200 : Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (isBackspace) {
            _onBackspace();
          } else if (isClear) {
            _onClear();
          } else {
            _onNumberTap(value);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 72,
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSpecial ? 24 : 32,
              fontWeight: FontWeight.w600,
              color: isSpecial ? Colors.grey.shade700 : theme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmounts() {
    final amounts = [250, 500, 750, 1000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick amounts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amounts.map((amount) {
            final isSelected = _displayAmount == amount.toString();
            return Material(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _onQuickAmount(amount),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Text(
                    '${amount}ml',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(), // ✅ UPDATED: Use context.pop()
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _onLog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log Water',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
