import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'container_form_sheet.dart';
import 'model.dart';
import 'repo.dart';

class ContainerCabinetPage extends StatefulWidget {
  const ContainerCabinetPage({super.key});

  @override
  State<ContainerCabinetPage> createState() => _ContainerCabinetPageState();
}

class _ContainerCabinetPageState extends State<ContainerCabinetPage> {
  final ContainerRepository _repo = ContainerRepository();
  final ImagePicker _picker = ImagePicker();

  List<UserContainer> _containers = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    setState(() => _isLoading = true);
    final data = await _repo.getAllContainers();
    setState(() {
      _containers = data;
      _isLoading = false;
    });
  }

  // ===========================================================================
  // 📸 SCANNING LOGIC
  // ===========================================================================

  Future<void> _handleScan() async {
    try {
      // 1. Pick Image
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (photo == null) return;

      setState(() => _isAnalyzing = true);

      // 2. Read bytes (Cross-platform safe)
      final Uint8List imageBytes = await photo.readAsBytes();

      // 3. Send to AI (Repo expects bytes + filename)
      final UserContainer? draft = await _repo.analyzeContainerImage(
        imageBytes,
        photo.name,
      );

      setState(() => _isAnalyzing = false);

      if (draft != null) {
        if (mounted) _showContainerForm(initialData: draft);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not analyze image. Try manual entry."),
            ),
          );
          _showContainerForm(); // Fallback to manual
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      print("Scan error: $e");
    }
  }

  void _showContainerForm({UserContainer? initialData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContainerFormSheet(
        initialData: initialData,

        // 1. Pass Delete Logic (Only for existing items)
        onDelete: initialData == null || initialData.id.isEmpty
            ? null
            : () {
                Navigator.pop(context); // Close sheet
                _confirmDelete(initialData.id);
              },

        // 2. Pass Save/Update Logic
        onSave: (name, volume, icon) async {
          // Check if we are updating an existing item (has ID) or creating new
          // Note: Drafts from AI usually have empty IDs or temp IDs depending on your model logic.
          // We assume if it came from DB, it has a valid ID.

          if (initialData != null && initialData.id.isNotEmpty) {
            // --- UPDATE ---
            final updatedContainer = UserContainer(
              id: initialData.id,
              name: name,
              volume: volume,
              iconType: icon,
              createdAt: initialData.createdAt,
            );
            await _repo.updateContainer(updatedContainer);
          } else {
            // --- CREATE ---
            final newContainer = UserContainer.create(
              name: name,
              volume: volume,
              iconType: icon,
            );
            await _repo.saveContainer(newContainer);
          }

          _loadContainers(); // Refresh grid
        },
      ),
    );
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================

  Future<void> _confirmDelete(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Container?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteContainer(id);
      _loadContainers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Cabinet", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // 1. Main Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _containers.isEmpty
              ? _buildEmptyState()
              : _buildGrid(),

          // 2. Analyzing Overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Analyzing Container...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleScan,
        label: const Text("Scan New"),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildGrid() {
    // FIX: Using Column + Expanded to avoid "unbounded height" crash
    return Column(
      children: [
        // Top Hint Text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            "Long press a container to delete it.",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),

        // The Grid fills remaining space
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2, // Wide cards
            ),
            itemCount: _containers.length,
            itemBuilder: (context, index) {
              final item = _containers[index];
              return _buildCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(UserContainer item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showContainerForm(initialData: item), // Tap to Edit
          onLongPress: () => _confirmDelete(item.id), // Long press to Delete
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // 1. Icon (Left Aligned)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    ContainerIcons.getIcon(item.iconType),
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(width: 10),

                // 2. Text Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${item.volume} ml",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shelves, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Your cabinet is empty",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Scan a bottle or cup to get started!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
