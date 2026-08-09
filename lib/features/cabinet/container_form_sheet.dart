import 'package:flutter/material.dart';
import 'model.dart'; // Ensure this points to your UserContainer model

class ContainerFormSheet extends StatefulWidget {
  final UserContainer? initialData; // Null = New Manual Entry
  final bool isDraft; // True = came from AI scan
  final Function(String name, int volume, String icon) onSave;
  final VoidCallback? onDelete;

  const ContainerFormSheet({
    super.key,
    this.initialData,
    this.isDraft = false,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ContainerFormSheet> createState() => _ContainerFormSheetState();
}

class _ContainerFormSheetState extends State<ContainerFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _volumeController;
  late String _selectedIcon;

  // Define available icons
  final List<String> _icons = ['bottle', 'cup', 'mug', 'glass', 'tumbler'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?.name ?? '',
    );
    _volumeController = TextEditingController(
      text: widget.initialData != null
          ? widget.initialData!.volume.toString()
          : '',
    );
    _selectedIcon = widget.initialData?.iconType ?? 'bottle';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  // Determine the right title and subtitle for context
  String get _sheetTitle {
    if (widget.isDraft) return "Confirm Container";
    if (widget.initialData != null) return "Edit Container";
    return "New Container";
  }

  String? get _sheetSubtitle {
    if (widget.isDraft) {
      return "We detected this from your photo — adjust anything that looks off.";
    }
    if (widget.initialData == null) {
      return "Add a container manually. You can always scan one instead.";
    }
    return null; // No subtitle needed for plain edits
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        // Important: Push content up when keyboard opens
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            _sheetTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          // Contextual subtitle — explains what's happening
          if (_sheetSubtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              _sheetSubtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 1. Icon Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _icons.map((iconKey) {
                final isSelected = _selectedIcon == iconKey;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade50
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2)
                          : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      ContainerIcons.getIcon(iconKey),
                      color: isSelected ? Colors.blue : Colors.grey,
                      size: 28,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Name Input
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Name",
              hintText: "e.g. Red Hydroflask",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Volume Input
          TextField(
            controller: _volumeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Volume (ml)",
              suffixText: "ml",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 24),

          // 4. Action Buttons
          Row(
            children: [
              // Delete Button (Only if editing existing item)
              if (widget.initialData != null && widget.onDelete != null) ...[
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Save Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final vol =
                        int.tryParse(_volumeController.text.trim()) ?? 0;

                    if (name.isNotEmpty && vol > 0) {
                      widget.onSave(name, vol, _selectedIcon);
                      Navigator.pop(context); // Close sheet
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
