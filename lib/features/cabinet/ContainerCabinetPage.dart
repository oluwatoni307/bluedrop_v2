import 'package:flutter/material.dart';

import '../water_logging/scan_container.dart';
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
  //
  // Task 4: the source-picker -> image-pick -> analyze pipeline now lives
  // in the shared scanContainerImage() (container_scan.dart), reused by
  // SmartLogSheet's "Scan New" tile. This handler owns only what happens
  // with the result — identical to the original inline logic.

  Future<void> _handleScan() async {
    final ScanResult result = await scanContainerImage(
      context: context,
      repo: _repo,
      onAnalyzingChanged: (analyzing) {
        if (mounted) setState(() => _isAnalyzing = analyzing);
      },
    );

    // Cancelled or threw: preserves original behavior exactly. Both the
    // original "user dismissed source picker" / "user backed out of
    // image picker" paths, and the original catch block, did nothing
    // further — no snackbar, no fallback form.
    if (result.cancelled || result.threw) return;

    if (result.draft != null) {
      // Pass isDraft: true to force a new database entry
      if (mounted) {
        _showContainerForm(initialData: result.draft, isDraft: true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't read that one — let's add it manually."),
          ),
        );
        _showContainerForm(); // Fallback to manual
      }
    }
  }

  // Added isDraft parameter to differentiate new AI scans from existing database records
  void _showContainerForm({UserContainer? initialData, bool isDraft = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContainerFormSheet(
        initialData: initialData,
        isDraft: isDraft,

        // 1. Pass Delete Logic (Only for existing items, never for drafts)
        onDelete: (initialData == null || initialData.id.isEmpty || isDraft)
            ? null
            : () {
                Navigator.pop(context); // Close sheet
                _confirmDelete(initialData.id);
              },

        // 2. Pass Save/Update Logic
        onSave: (name, volume, icon) async {
          // Check if we are updating an existing item (has ID and is NOT a draft)
          if (initialData != null &&
              initialData.id.isNotEmpty &&
              isDraft == false) {
            // --- UPDATE ---
            final updatedContainer = UserContainer(
              id: initialData.id,
              name: name,
              volume: volume,
              iconType: icon,
              iconColor: initialData.iconColor,
              createdAt: initialData.createdAt,
            );
            await _repo.updateContainer(updatedContainer);
          } else {
            // --- CREATE ---
            final newContainer = UserContainer.create(
              name: name,
              volume: volume,
              iconType: icon,
              iconColor: initialData?.iconColor,
            );
            await _repo.saveContainer(newContainer);
          }

          // Confirm the save to the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$name saved to your cabinet.")),
            );
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
        title: const Text("Remove this container?"),
        content: const Text("Your past logs won't be affected."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descriptor block — always visible, explains purpose and interactions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Save your bottles, cups, and glasses once. They'll appear as quick-log shortcuts so you never have to guess your container's size again.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap any container to edit it. Long press to remove it.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider to separate descriptor from content
              Divider(height: 1, color: Colors.grey.shade100),

              // Content area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _containers.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
              ),
            ],
          ),

          // 2. Analyzing Overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Reading your container...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "We'll fill in the details for you.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleScan,
        label: const Text("Add Container"),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          onTap: () => _showContainerForm(initialData: item),
          onLongPress: () => _confirmDelete(item.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // 1. Icon (Left Aligned)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ContainerIcons.getColor(
                      item.iconType,
                      item.iconColor,
                    ).withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    ContainerIcons.getIcon(item.iconType),
                    size: 18,
                    color: ContainerIcons.getColor(
                      item.iconType,
                      item.iconColor,
                    ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shelves, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Build your cabinet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Scan your bottles and cups once. They'll appear as quick-log shortcuts every time you drink — no more guessing sizes.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Tap \"Add Container\" below to get started.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
