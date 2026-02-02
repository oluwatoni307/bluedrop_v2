import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed, // Keeps all labels visible
      selectedItemColor: const Color(0xFF5DADE2),
      unselectedItemColor: Colors.grey,
      items: const [
        // Index 0
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        // Index 1
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        // Index 2 (NEW)
        BottomNavigationBarItem(
          icon: Icon(Icons.shelves), // Represents a cabinet/shelf
          label: 'Cabinet',
        ),
        // Index 3
        BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
        // Index 4
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
