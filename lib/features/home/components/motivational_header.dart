import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MotivationalHeader extends StatelessWidget {
  final String userName;
  final double percentage;

  const MotivationalHeader({
    Key? key,
    required this.userName,
    required this.percentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final message = _getMotivationalMessage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName!',
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Hi';
  }

  String _getMotivationalMessage() {
    if (percentage <= 25) {
      return 'Start Hydrating! A few sips now boost your energy!';
    } else if (percentage <= 50) {
      return 'Keep Sipping! Stay steady to hit your goal!';
    } else if (percentage <= 75) {
      return 'Almost Done! A bit more to crush your goal!';
    } else if (percentage <= 100) {
      return "Hydration Star! You're killing it!";
    }
    return 'Goal Crushed! Amazing work today!';
  }
}
