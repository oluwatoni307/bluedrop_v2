import 'package:flutter/material.dart';
import '../../../services/device_utility.dart';

class BatteryWarningCard extends StatelessWidget {
  const BatteryWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: DeviceUtility.isChineseRom(),
      builder: (context, snapshot) {
        // 1. If loading or not a restrictive phone, hide completely
        if (!snapshot.hasData || snapshot.data == false) {
          return const SizedBox.shrink();
        }

        // 2. If restrictive phone detected, show the Warning Card
        return Card(
          color: Colors.orange.shade50,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Setup Required",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Your phone may block reminders to save battery. Please enable 'Auto-Start' to ensure reliability.",
                  style: TextStyle(color: Colors.orange.shade900),
                ),
                const SizedBox(height: 12),

                // The "Fix It" Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                      elevation: 0,
                    ),
                    onPressed: () =>
                        DeviceUtility.openAutoStartSettings(context),
                    child: const Text("Fix Settings Now"),
                  ),
                ),

                // Special Tecno/Infinix Instruction
                FutureBuilder<bool>(
                  future: _isTecnoOrInfinix(),
                  builder: (ctx, snap) {
                    if (snap.data == true) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Tip: Also open Recent Apps and 'Lock' this app.",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _isTecnoOrInfinix() async {
    // Re-using logic to detect Transsion brands specifically for the extra tip
    // You could move this into DeviceUtility to keep it clean
    final isChinese = await DeviceUtility.isChineseRom();
    if (!isChinese) return false;
    // This is a quick hack for the UI; ideally add isTranssion() to DeviceUtility
    return true;
  }
}
