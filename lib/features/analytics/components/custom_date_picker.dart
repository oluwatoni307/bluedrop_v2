import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime start, DateTime end) onApply;
  final VoidCallback onCancel;

  const CustomDatePicker({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate =
        widget.initialStartDate ?? now.subtract(const Duration(days: 7));
    _endDate = widget.initialEndDate ?? now;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _errorMessage = null;
      });
    }
  }

  void _validateAndApply() {
    // Validation: start must be <= end
    if (_startDate.isAfter(_endDate)) {
      setState(() {
        _errorMessage = 'End date must be after start date';
      });
      return;
    }

    // Validation: range must be <= 365 days
    final daysDifference = _endDate.difference(_startDate).inDays + 1;
    if (daysDifference > 365) {
      setState(() {
        _errorMessage = 'Maximum 365-day range allowed';
      });
      return;
    }

    // Validation: both dates must be <= today
    final today = DateTime.now();
    if (_startDate.isAfter(today) || _endDate.isAfter(today)) {
      setState(() {
        _errorMessage = 'Cannot select future dates';
      });
      return;
    }

    // All validations passed
    widget.onApply(_startDate, _endDate);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _setQuickRange(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      _startDate = now.subtract(Duration(days: days - 1));
      _errorMessage = null;
    });
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
      _errorMessage = null;
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
    setState(() {
      _startDate = lastMonth;
      _endDate = lastDayOfLastMonth;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Custom Date Range',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // From Date
            Text('From Date:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_startDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // To Date
            Text('To Date:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectEndDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_endDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ),

            // Quick Ranges section header (will add buttons in Task 22)
            // Quick range buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickRangeButton(
                  label: 'Last 7 Days',
                  onTap: () => _setQuickRange(7),
                ),
                _QuickRangeButton(
                  label: 'Last 30 Days',
                  onTap: () => _setQuickRange(30),
                ),
                _QuickRangeButton(label: 'This Month', onTap: _setThisMonth),
                _QuickRangeButton(label: 'Last Month', onTap: _setLastMonth),
              ],
            ),
            Text(
              'Quick Ranges:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            // TODO: Add quick range buttons in Task 22
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _validateAndApply,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickRangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickRangeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
