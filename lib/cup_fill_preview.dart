import 'package:flutter/material.dart';
import 'package:bluedrop_v2/theme.dart';
import 'features/water_log/pages/cup_fill_view.dart';

void main() {
  runApp(const CupFillPreviewApp());
}

class CupFillPreviewApp extends StatelessWidget {
  const CupFillPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cup Fill Preview',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              height: 700,
              child: CupFillView(
                cupVolumeMl: 350,
                onComplete: (ml) {
                  debugPrint('Confirmed ml: $ml');
                },
                onClose: () {
                  debugPrint('Closed');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
