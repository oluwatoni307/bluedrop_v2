import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../cabinet/model.dart';
import '../cabinet/repo.dart';

/// Shared scan-and-analyze flow, extracted from the original
/// ContainerCabinetPage._handleScan() (Task 4) so ContainerCabinetPage
/// and SmartLogSheet's "Scan New" tile both drive the same
/// source-picker -> image-pick -> analyze pipeline instead of
/// maintaining two copies.
///
/// This function owns only the SHARED PREFIX of the original flow:
/// picking a source, picking an image, reading bytes, calling
/// analyzeContainerImage(), and toggling an "analyzing" flag via
/// [onAnalyzingChanged] for whatever loading UI the caller shows.
///
/// Callers own everything AFTER this returns — ContainerCabinetPage
/// opens a confirm form either way (draft or manual fallback);
/// SmartLogSheet saves the draft directly and advances its own step
/// state. That divergence starts right after this function returns, by
/// design — see each caller's own scan handler for details.
class ScanResult {
  /// The analyzed draft container, if analysis succeeded. Null on
  /// cancellation, on a clean "couldn't read it" analysis failure, and
  /// on an exception — see [cancelled] / [threw] to tell those apart.
  final UserContainer? draft;

  /// True if the user backed out of the source picker or the image
  /// picker before an image was ever selected. Not an error; nothing
  /// should change for the caller.
  final bool cancelled;

  /// True if an exception was thrown during pick/read/analyze. Matches
  /// the original _handleScan()'s catch block, which caught, logged,
  /// and otherwise did nothing — no snackbar, no fallback form. Kept
  /// distinct from a clean "draft == null" result so callers can
  /// preserve that exact silent behavior.
  final bool threw;

  const ScanResult({this.draft, required this.cancelled, this.threw = false});
}

Future<ScanResult> scanContainerImage({
  required BuildContext context,
  required ContainerRepository repo,
  required ValueChanged<bool> onAnalyzingChanged,
  ImagePicker? picker,
}) async {
  final ImagePicker imagePicker = picker ?? ImagePicker();

  // 1. Prompt user to select image source — unchanged from the original
  // ContainerCabinetPage._handleScan().
  final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );

  if (selectedSource == null) {
    return const ScanResult(cancelled: true);
  }

  try {
    // 2. Pick image
    final XFile? photo = await imagePicker.pickImage(
      source: selectedSource,
      imageQuality: 50,
    );

    if (photo == null) {
      return const ScanResult(cancelled: true);
    }

    onAnalyzingChanged(true);

    // 3. Read bytes (cross-platform safe)
    final Uint8List imageBytes = await photo.readAsBytes();

    // 4. Send to AI (repo expects bytes + filename)
    final UserContainer? draft = await repo.analyzeContainerImage(
      imageBytes,
      photo.name,
    );

    onAnalyzingChanged(false);

    return ScanResult(draft: draft, cancelled: false);
  } catch (e) {
    onAnalyzingChanged(false);
    print("Scan error: $e");
    return const ScanResult(cancelled: false, threw: true);
  }
}
