import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/database_service.dart';
// Adjust this import path to where your UserContainer file actually lives
import '../../cabinet/model.dart';

enum LogMode { cabinet, fruit }

class SmartLogSheet extends ConsumerStatefulWidget {
  final LogMode mode;

  const SmartLogSheet({Key? key, required this.mode}) : super(key: key);

  @override
  ConsumerState<SmartLogSheet> createState() => _SmartLogSheetState();
}

class _SmartLogSheetState extends ConsumerState<SmartLogSheet> {
  // Data State
  bool _isLoading = true;
  List<LoggableItem> _items = [];

  // Selection State
  LoggableItem? _selectedItem;
  int _count = 1;
  String _selectedDrinkType = 'water';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (widget.mode == LogMode.fruit) {
      // Load Static Fruits
      if (mounted) {
        setState(() {
          _items = NIGERIAN_FRUITS;
          _selectedItem = _items.isNotEmpty ? _items.first : null;
          _isLoading = false;
        });
      }
    } else {
      // Load Cabinet from DB
      final db = DatabaseService();
      try {
        final data = await db.getAllFromCollection('containers');

        // ✅ UPDATED: Use your UserContainer class
        final containers = data.map((e) => UserContainer.fromMap(e)).toList();

        if (mounted) {
          setState(() {
            // ✅ UPDATED: Map UserContainer properties correctly
            _items = containers
                .map(
                  (c) => LoggableItem(
                    id: c.id,
                    name: c.name,
                    amount: c.volume, // using .volume instead of .capacity
                    icon: ContainerIcons.getIcon(
                      c.iconType,
                    ), // using your Icon Helper
                    isVariableType: true,
                  ),
                )
                .toList();

            if (_items.isNotEmpty) _selectedItem = _items.first;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleLog() {
    if (_selectedItem == null) return;

    final totalAmount = _selectedItem!.amount * _count;
    final finalType = widget.mode == LogMode.fruit
        ? 'Fruit'
        : _selectedDrinkType;

    context.pop({'amount': totalAmount, 'type': finalType});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.mode == LogMode.fruit ? 'Log Fruit' : 'Log from Cabinet',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_items.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: [
                // A. Horizontal Scroll List
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = item.id == _selectedItem?.id;
                      return _buildItemCard(item, isSelected);
                    },
                  ),
                ),

                const SizedBox(height: 24),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 24),

                // B. Control Panel
                if (_selectedItem != null) _buildControlPanel(),

                const SizedBox(height: 24),

                // C. Submit Button
                ElevatedButton(
                  onPressed: _selectedItem == null ? null : _handleLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedItem == null
                        ? 'Select Item'
                        : 'Log ${(_selectedItem!.amount * _count)}ml',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildItemCard(LoggableItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedItem = item),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logic to display either Icon or Emoji
            item.icon != null
                ? Icon(
                    item.icon,
                    size: 32,
                    color: isSelected ? Colors.blue : Colors.grey,
                  )
                : Text(item.emojiOrIcon, style: const TextStyle(fontSize: 32)),

            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
            Text(
              '${item.amount}ml',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue.shade700 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Counter (Left)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              _CircleBtn(
                icon: Icons.remove,
                onTap: () {
                  if (_count > 1) setState(() => _count--);
                },
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$_count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _CircleBtn(
                icon: Icons.add,
                onTap: () {
                  if (_count < 10) setState(() => _count++);
                },
              ),
            ],
          ),
        ),

        const Spacer(),

        // Info Stack (Right)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.mode == LogMode.cabinet)
              GestureDetector(
                onTap: _showDrinkTypePicker,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedDrinkType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: Colors.blue.shade800,
                      ),
                    ],
                  ),
                ),
              ),

            Row(
              children: [
                Text(
                  _selectedItem!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                // Display Icon for Cabinet items
                if (widget.mode == LogMode.cabinet &&
                    _selectedItem!.icon != null)
                  Icon(_selectedItem!.icon, color: Colors.grey),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const Icon(Icons.shelves, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        const Text('Your cabinet is empty!'),
        TextButton(
          onPressed: () {
            context.pop();
            context.push('/cabinet');
          },
          child: const Text('Add Container'),
        ),
      ],
    );
  }

  void _showDrinkTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: ['water', 'tea', 'coffee', 'juice', 'soda']
            .map(
              (type) => ListTile(
                title: Text(type.toUpperCase()),
                onTap: () {
                  setState(() => _selectedDrinkType = type);
                  Navigator.pop(ctx);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

// --- DATA CLASSES ---

class LoggableItem {
  final String id;
  final String name;
  final int amount;
  final IconData? icon;
  final String? emoji;
  final bool isVariableType;

  LoggableItem({
    required this.id,
    required this.name,
    required this.amount,
    this.icon,
    this.emoji,
    required this.isVariableType,
  });

  String get emojiOrIcon => emoji ?? '';
}

// --- STATIC FRUIT DATA (NIGERIAN CONTEXT) ---
final List<LoggableItem> NIGERIAN_FRUITS = [
  LoggableItem(
    id: 'melon',
    name: 'Watermelon',
    amount: 250,
    emoji: '🍉',
    isVariableType: false,
  ),
  LoggableItem(
    id: 'coco',
    name: 'Coconut Water',
    amount: 300,
    emoji: '🥥',
    isVariableType: false,
  ),
  LoggableItem(
    id: 'cuke',
    name: 'Cucumber',
    amount: 150,
    emoji: '🥒',
    isVariableType: false,
  ),
  LoggableItem(
    id: 'orange',
    name: 'Orange',
    amount: 100,
    emoji: '🍊',
    isVariableType: false,
  ),
  LoggableItem(
    id: 'pine',
    name: 'Pineapple',
    amount: 120,
    emoji: '🍍',
    isVariableType: false,
  ),
];
