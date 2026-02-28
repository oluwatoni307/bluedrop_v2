import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Dummy constants for the sake of a complete, runnable file
const List<String> DRINK_TYPES = ['water', 'tea', 'coffee', 'juice', 'others'];
const Map<String, String> DRINK_TYPE_LABELS = {
  'water': 'Water',
  'tea': 'Tea',
  'coffee': 'Coffee',
  'juice': 'Juice',
  'others': 'Others',
};

class CustomLogScreen extends StatefulWidget {
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

    if (widget.onLog != null) {
      widget.onLog!(amount, _selectedType);
    } else {
      context.pop({'amount': amount, 'type': _selectedType});
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Custom Amount',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildDisplay(theme),
                      const SizedBox(height: 32),

                      // 🌟 CHANGED: Horizontal Drink Selector instead of Dropdown
                      _buildDrinkTypeSelector(theme),
                      const SizedBox(height: 32),

                      // 🌟 CHANGED: Quick Amounts moved ABOVE the Numpad
                      _buildQuickAmounts(theme),
                      const SizedBox(height: 32),

                      // 🌟 CHANGED: Flat, modern number pad
                      _buildNumberPad(theme),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay(ThemeData theme) {
    // 🌟 CHANGED: Removed borders, increased border radius, added min height for error prevention
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: _hasError
            ? Colors.red.withOpacity(0.08)
            : theme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          32,
        ), // More modern, pill-like rounding
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _displayAmount,
                style: TextStyle(
                  fontSize: 64, // Slightly larger for impact
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  color: _hasError ? Colors.red : theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ml',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _hasError
                      ? Colors.red.withOpacity(0.6)
                      : theme.primaryColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          // Reserved space for error so UI doesn't jump
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _hasError ? 24 : 0,
            margin: EdgeInsets.only(top: _hasError ? 8 : 0),
            child: _hasError
                ? Text(
                    _errorMessage ?? '',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beverage Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: DRINK_TYPES.map((type) {
              final isSelected = _selectedType == type;
              final label = DRINK_TYPE_LABELS[type] ?? type;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        100,
                      ), // Fully rounded pill
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getIcon(type),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAmounts(ThemeData theme) {
    final amounts = [250, 500, 750, 1000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: amounts.map((amount) {
            final isSelected = _displayAmount == amount.toString();
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: amount != amounts.last ? 8.0 : 0.0,
                ), // Space between
                child: GestureDetector(
                  onTap: () => _onQuickAmount(amount),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${amount}ml',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.grey.shade700,
                      ),
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

  Widget _buildNumberPad(ThemeData theme) {
    return Column(
      children: [
        _buildNumberRow(['1', '2', '3'], theme),
        const SizedBox(height: 12),
        _buildNumberRow(['4', '5', '6'], theme),
        const SizedBox(height: 12),
        _buildNumberRow(['7', '8', '9'], theme),
        const SizedBox(height: 12),
        _buildNumberRow([
          'C',
          '0',
          '⌫',
        ], theme), // Flipped C and Backspace for better thumb reach
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

    // 🌟 CHANGED: Removed Material elevation. Using flat, soft tonal colors.
    return InkWell(
      onTap: () {
        if (isBackspace) {
          _onBackspace();
        } else if (isClear) {
          _onClear();
        } else {
          _onNumberTap(value);
        }
      },
      borderRadius: BorderRadius.circular(24),
      highlightColor: theme.primaryColor.withOpacity(0.1),
      splashColor: theme.primaryColor.withOpacity(0.2),
      child: Container(
        height: 64, // Slightly shorter to fit the screen better
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSpecial ? Colors.grey.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: isSpecial ? 24 : 32,
            fontWeight: FontWeight.w500,
            color: isSpecial
                ? Colors.grey.shade800
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    // Dynamically get the label for the button
    final drinkLabel = DRINK_TYPE_LABELS[_selectedType] ?? 'Drink';

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                shape: const StadiumBorder(), // 🌟 CHANGED: Fully rounded pills
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _onLog,
              style: ElevatedButton.styleFrom(
                elevation: 0, // Flat modern look
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(), // 🌟 CHANGED: Fully rounded pills
              ),
              child: Text(
                'Log $drinkLabel', // 🌟 CHANGED: Dynamic button text
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
