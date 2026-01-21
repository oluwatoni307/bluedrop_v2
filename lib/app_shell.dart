import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_bottom_nav_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({Key? key, required this.child}) : super(key: key);

  void _onTap(BuildContext context, int index) {
    // Navigate to corresponding route
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/analytics');
        break;
      case 2:
        context.go('/goals');
        break;
      case 3:
        context.go('/setting');
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/analytics')) return 1;
    if (location.startsWith('/goals')) return 2;
    if (location.startsWith('/setting')) return 3;
    return 0; // default to home
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
