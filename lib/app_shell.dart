import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_bottom_nav_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({Key? key, required this.child}) : super(key: key);

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break; // Home
      case 1:
        context.go('/analytics');
        break; // Analytics
      case 2:
        context.go('/cabinet');
        break; // ✅ NEW Cabinet Tab
      case 3:
        context.go('/goals');
        break; // Goals
      case 4:
        context.go('/setting');
        break; // Settings
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/analytics')) return 1;
    if (location.startsWith('/cabinet')) return 2; // ✅ NEW
    if (location.startsWith('/goals')) return 3;
    if (location.startsWith('/setting')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
