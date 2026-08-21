import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- SERVICE IMPORTS ---
import '../../../services/database_service.dart';

// --- MODEL IMPORTS ---
// Ensure this path points to your actual UserContainer model file
import '../../cabinet/model.dart';
// Ensure this path points to where ContainerIcons is defined (likely repo.dart or model.dart)

// --- CUP FILL VIEW (Task 3 dependency) ---

import '../../water_log/pages/cup_fill_view.dart';
import '../scan_container.dart';

// --- SCAN (Task 4 dependency) ---
// Shared scan-and-analyze pipeline + ContainerRepository, same relative
// path pattern as the existing model.dart import above.
import '../../cabinet/repo.dart';

enum LogMode { cabinet, fruit }

/// Cabinet-mode-only step state. Never referenced when
/// widget.mode == LogMode.fruit — see _buildCabinetBody() /
/// _buildPickListBody() split below.
enum _CabinetStep { pickCup, fillCup }

class SmartLogSheet extends ConsumerStatefulWidget {
  final LogMode mode;

  const SmartLogSheet({super.key, required this.mode});

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

  // --- Cabinet-mode step state (Task 3) ---
  // Only ever read/written when widget.mode == LogMode.cabinet.
  _CabinetStep _step = _CabinetStep.pickCup;
  LoggableItem? _selectedCup;
  double _detectedFillFraction = 0.5;
  int? _detectedCapacity;

  // --- Cabinet-mode scan state (Task 4) ---
  // Only ever read/written when widget.mode == LogMode.cabinet.
  final ContainerRepository _repo = ContainerRepository();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    // UNCHANGED — do not touch per task brief.
    if (widget.mode == LogMode.fruit) {
      // --- LOAD FRUITS ---
      if (mounted) {
        setState(() {
          _items = NIGERIAN_FRUITS;
          if (_items.isNotEmpty) _selectedItem = _items.first;
          _isLoading = false;
        });
      }
    } else {
      // --- LOAD CABINET ---
      final db = DatabaseService();
      try {
        // FIX 1: Changed collection name to match ContainerRepository ('user_containers')
        final data = await db.getAllFromCollection('user_containers');

        print("📦 Debug: Found ${data.length} items in DB");

        if (mounted) {
          setState(() {
            _items = data.map((e) {
              // Convert DB Map -> UserContainer Model
              final container = UserContainer.fromMap(e);

              // Convert Model -> LoggableItem (for this sheet)
              return LoggableItem(
                id: container.id,
                name: container.name,
                amount: container.volume,
                // Use the helper from your repo to get the IconData
                icon: ContainerIcons.getIcon(container.iconType),
                iconColor: ContainerIcons.getColor(container.iconType),
                isVariableType: true,
              );
            }).toList();

            if (_items.isNotEmpty) _selectedItem = _items.first;
            _isLoading = false;
          });
        }
      } catch (e) {
        print("❌ Error loading cabinet: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleLog() {
    // UNCHANGED — do not touch per task brief.
    //
    // Fruit-mode only in practice: the button calling this is gated behind
    // `if (widget.mode == LogMode.fruit)` in _buildPickListBody(), so
    // cabinet mode can't reach it through the UI as written. Correcting an
    // earlier comment that claimed otherwise, so nobody chases a dead path.
    if (_selectedItem == null) return;

    final totalAmount = _selectedItem!.amount * _count;
    final finalType = widget.mode == LogMode.fruit
        ? 'Fruit'
        : _selectedDrinkType;

    // Return result to parent
    context.pop({'amount': totalAmount, 'type': finalType});
  }

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox caps how tall the sheet can ever get. Without this,
    // the outer Column (mainAxisSize.min) just grows to fit whatever
    // content is inside it — fine for the short pick-list, but
    // CupFillView's fixed heights (cup zone + slider + presets + toggle +
    // button + safe-area padding) can add up to more than a given
    // device's viewport, which is exactly the 41px overflow seen on cup
    // tap. Wrapping the content area below in Flexible + SingleChildScrollView
    // means that if content still doesn't fit inside this cap, it scrolls
    // instead of overflowing — robust across device heights and text-scale
    // settings, rather than tuned to one screenshot.
    final Widget sheet = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header — suppressed once cabinet mode reaches the
            // fillCup step, since CupFillView renders its own "How much
            // water?" title + close button right below it. Without this,
            // the sheet showed two stacked headers with two close buttons
            // that did the exact same thing (pop the whole sheet) — pure
            // duplication, and the main reason the sheet was overflowing:
            // this row (IconButton alone has a ~48px min tap target) plus
            // its spacing was eating space CupFillView's own content
            // needed.
            if (!(widget.mode == LogMode.cabinet &&
                _step == _CabinetStep.fillCup)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.mode == LogMode.fruit
                        ? 'Log Fruit'
                        : 'Log from Cabinet',
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
            ],

            // 2. Content Area — Flexible + SingleChildScrollView so that if
            // the content is taller than the ConstrainedBox's cap, it
            // scrolls internally rather than overflowing past the sheet.
            Flexible(
              child: SingleChildScrollView(
                child: _isLoading
                    ? const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : widget.mode == LogMode.cabinet
                    ? (_items.isEmpty && _step == _CabinetStep.pickCup
                          ? _buildEmptyState()
                          : _buildCabinetBody())
                    : _items.isEmpty
                    ? _buildEmptyState()
                    : _buildPickListBody(),
              ),
            ),
          ],
        ),
      ),
    );

    // Task 4: analyzing overlay, cabinet mode only. Fruit mode returns
    // `sheet` directly — same widget tree as before this task, unchanged.
    if (widget.mode != LogMode.cabinet) return sheet;

    return Stack(children: [sheet, if (_isAnalyzing) _buildScanningOverlay()]);
  }

  /// Mirrors ContainerCabinetPage's analyzing overlay copy/style for
  /// visual consistency. Presentational duplication only (not the scan
  /// logic itself, which is shared via container_scan.dart) — didn't
  /// seem worth extracting a shared widget for a few lines of styled
  /// text, but flagging the duplication since the brief emphasized
  /// "extract, don't duplicate."
  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
    );
  }

  // --- CABINET MODE ONLY (Task 3) ---

  /// Swaps between the (unchanged) pick-list UI and CupFillView based on
  /// _step. Only ever built when widget.mode == LogMode.cabinet — fruit
  /// mode never enters this method.
  Widget _buildCabinetBody() {
    // AnimatedSize eases the sheet's own height between the short pick-list
    // and the taller CupFillView. AnimatedSwitcher alone only cross-fades
    // content — it doesn't animate the container around it, which is what
    // was producing the snap when _step flipped.
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: (_step == _CabinetStep.fillCup && _selectedCup != null)
            ? CupFillView(
                key: const ValueKey('cupFill'),
                cupVolumeMl: _detectedCapacity ?? _selectedCup!.amount,
                initialFillFraction: _detectedFillFraction,
                onComplete: (ml) =>
                    context.pop({'amount': ml, 'type': _selectedDrinkType}),
                // Closes the whole sheet (not just a return to the cup
                // picker) — confirmed decision, overrides the brief's
                // original "return to picker" instruction.
                onClose: () => context.pop(),
              )
            : KeyedSubtree(
                key: const ValueKey('pickList'),
                child: _buildPickListBody(),
              ),
      ),
    );
  }

  // --- SHARED PICK-LIST UI ---
  //
  // Extracted verbatim from the original inline build() Column — content
  // is unchanged. Fruit mode calls this directly and exclusively, so its
  // rendered output is guaranteed identical to pre-refactor behavior.
  // Cabinet mode reuses it for the pickCup step only.
  Widget _buildPickListBody() {
    return Column(
      children: [
        // A. Horizontal Scroll List
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // Task 4: cabinet mode gets one extra trailing slot for the
            // "Scan New" tile. Fruit mode's itemCount is unchanged
            // (+ 0), so its list renders identically to before.
            itemCount: _items.length + (widget.mode == LogMode.cabinet ? 1 : 0),
            itemBuilder: (context, index) {
              if (widget.mode == LogMode.cabinet && index == _items.length) {
                return _buildScanNewCard();
              }
              final item = _items[index];
              final isSelected = item.id == _selectedItem?.id;
              return _buildItemCard(item, isSelected);
            },
          ),
        ),

        // B/C. Control panel + submit button — fruit mode only.
        // Cabinet mode's action is the cup tap itself (handled in
        // _buildItemCard -> _step transition -> CupFillView); showing a
        // second, differently-computed "Log" path here would let a user
        // log an amount without ever touching the fill screen. Fruit
        // mode is unaffected: this block renders exactly as before.
        if (widget.mode == LogMode.fruit) ...[
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          if (_selectedItem != null) _buildControlPanel(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedItem == null ? null : _handleLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _selectedItem == null
                  ? 'Select Item'
                  : 'Log ${(_selectedItem!.amount * _count)}ml',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  // --- WIDGETS ---

  Widget _buildItemCard(LoggableItem item, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // Consolidated into a single setState — previously this fired two
        // separate setState calls in cabinet mode (one for _selectedItem,
        // one for _selectedCup/_step), causing an extra, wasted rebuild
        // before the AnimatedSwitcher/AnimatedSize transition even began.
        setState(() {
          _selectedItem = item;

          // ADDED — cabinet-mode-only branch. Fruit mode
          // (widget.mode == LogMode.fruit) never executes this block, so
          // fruit-mode tap behavior is unchanged in effect.
          //
          // FLAGGED: this is a deviation from "do not touch _buildItemCard()"
          // (task brief requirement 6). There was no way to hook the
          // pickCup -> fillCup transition on cup-tap without editing the
          // one place selection happens. Flagging per instructions rather
          // than silently leaving it out or silently rewriting the method
          // more broadly.
          if (widget.mode == LogMode.cabinet) {
            _selectedCup = item;
            _step = _CabinetStep.fillCup;
          }
        });
      },
      child: Container(
        width: 120,
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
                        color: item.iconColor ??
                    (isSelected ? Colors.blue : Colors.grey),
                  )
                : Text(item.emojiOrIcon, style: const TextStyle(fontSize: 32)),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
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

  // --- SCAN NEW (Task 4, cabinet mode only) ---

  /// Same width/shape/margin as _buildItemCard's cards, camera icon and
  /// blue tint to read as an action tile rather than a selectable item.
  Widget _buildScanNewCard() {
    return GestureDetector(
      onTap: _isAnalyzing
          ? null
          : _handleScanFromSheet,
      child: Container(
            width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 32, color: Colors.blue.shade400),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Scan Fill',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScanFromSheet() async {
    final ScanResult result = await scanContainerImage(
      context: context,
      repo: _repo,
      onAnalyzingChanged: (analyzing) {
        if (mounted) setState(() => _isAnalyzing = analyzing);
      },
      estimateWaterLevel: true,
    );

    // Cancelled: user backed out intentionally — stay silent, no message.
    if (result.cancelled) return;

    // Threw or a clean "couldn't read it" analysis failure — both now
    // surface a message so the user isn't left wondering why nothing
    // happened. Still stays on pickCup, no other state change.
    //
    // FLAGGED (requirement 4, still applies): this does NOT fall back to
    // manual entry the way ContainerCabinetPage does — just an error
    // message, then back to the picker. Confirmed as sufficient per your
    // last message; flagging only so it's on record that manual-entry
    // fallback was considered and intentionally left out here.
    if (result.threw || result.fillFraction == null || result.capacity == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't read that one — try a clearer photo."),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _detectedFillFraction = result.fillFraction!;
      _detectedCapacity = result.capacity;
      _selectedCup = _selectedItem ?? LoggableItem(
        id: 'scanned-${DateTime.now().microsecondsSinceEpoch}',
        name: 'Scanned container',
        amount: result.capacity!,
        icon: Icons.local_drink,
        iconColor: ContainerIcons.getColor('bottle'),
        isVariableType: true,
      );
      _step = _CabinetStep.fillCup;
    });
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
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (widget.mode == LogMode.cabinet) {
      return Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.camera_alt, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Scan a container to log it',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _handleScanFromSheet,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Container'),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.shelves, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'Your cabinet is empty!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            // FIX 2: Correct Navigation Logic
            context.pop(); // 1. Close the bottom sheet
            context.go('/cabinet'); // 2. Switch tabs to Cabinet
          },
          child: const Text('Add Container', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 20),
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
                leading: const Icon(Icons.local_drink),
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
  final Color? iconColor;
  final String? emoji;
  final bool isVariableType;

  LoggableItem({
    required this.id,
    required this.name,
    required this.amount,
    this.icon,
    this.iconColor,
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
