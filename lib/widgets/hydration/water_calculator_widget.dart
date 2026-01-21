import 'package:flutter/material.dart';

class WaterCalculatorWidget extends StatefulWidget {
  final Function(double) onLog;
  final VoidCallback? onCancel;
  final List<double> quickSuggestions;

  const WaterCalculatorWidget({
    super.key,
    required this.onLog,
    this.onCancel,
    this.quickSuggestions = const [250, 500, 750],
  });

  @override
  State<WaterCalculatorWidget> createState() => _WaterCalculatorWidgetState();
}

class _WaterCalculatorWidgetState extends State<WaterCalculatorWidget> {
  String _currentInput = '0';
  String? _errorMessage;

  bool get _isValid {
    final amount = double.tryParse(_currentInput);
    return amount != null && amount >= 50 && amount <= 2000;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSuggestions(),
            const SizedBox(height: 16),
            _buildDisplay(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            _buildNumberPad(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.quickSuggestions.map((amount) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ActionChip(
            label: Text('${amount.toInt()}ml'),
            onPressed: () => _setSuggestion(amount),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isValid ? Colors.green : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$_currentInput ml',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildNumberRow(['7', '8', '9', '⌫']),
        const SizedBox(height: 8),
        _buildNumberRow(['4', '5', '6', 'C']),
        const SizedBox(height: 8),
        _buildNumberRow(['1', '2', '3', '']),
        const SizedBox(height: 8),
        _buildNumberRow(['0', '00', '.', '']),
      ],
    );
  }

  Widget _buildNumberRow(List<String> labels) {
    return Row(
      children: labels.map((label) {
        if (label.isEmpty) {
          return const Expanded(child: SizedBox());
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _buildButton(label),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton(String label) {
    return InkWell(
      onTap: () => _handleButtonPress(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel ?? () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isValid ? _handleLog : null,
            child: const Text('Log'),
          ),
        ),
      ],
    );
  }

  void _handleButtonPress(String label) {
    setState(() {
      if (label == '⌫') {
        if (_currentInput.length > 1) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        } else {
          _currentInput = '0';
        }
      } else if (label == 'C') {
        _currentInput = '0';
        _errorMessage = null;
      } else if (label == '.') {
        if (!_currentInput.contains('.')) {
          _currentInput += '.';
        }
      } else {
        if (_currentInput == '0') {
          _currentInput = label;
        } else {
          _currentInput += label;
        }
      }
      _validate();
    });
  }

  void _validate() {
    final amount = double.tryParse(_currentInput);

    if (amount == null) {
      _errorMessage = 'Invalid amount';
    } else if (amount < 50) {
      _errorMessage = 'Minimum 50ml';
    } else if (amount > 2000) {
      _errorMessage = 'Maximum 2000ml';
    } else {
      _errorMessage = null;
    }
  }

  void _setSuggestion(double amount) {
    setState(() {
      _currentInput = amount.toInt().toString();
      _validate();
    });
  }

  void _handleLog() {
    final amount = double.parse(_currentInput);
    widget.onLog(amount);
  }
}
