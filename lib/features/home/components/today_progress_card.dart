import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

class TodayProgressCard extends StatelessWidget {
  final int totalAmount;
  final int goalAmount;
  final double percentage;
  final VoidCallback onLogWater;

  const TodayProgressCard({
    Key? key,
    required this.totalAmount,
    required this.goalAmount,
    required this.percentage,
    required this.onLogWater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: WaveWidget(
                config: CustomConfig(
                  colors: [const Color(0x695DCCFC), const Color(0x695DCCFC)],
                  durations: [4000, 3200],
                  heightPercentages: [0.20, 0.25],
                  blur: const MaskFilter.blur(BlurStyle.solid, 10),
                ),
                waveAmplitude: 10,
                size: const Size(double.infinity, 80),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.water_drop,
                        color: Colors.blue,
                        size: 27,
                      ),
                      Text(
                        "Today's Progress ",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 3.0, 0.0, 3.0),
                    child: Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${totalAmount}ml",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: "/ ${goalAmount}ml",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            0.0,
                            0.0,
                            5.0,
                            0.0,
                          ),
                          child: Text(
                            "${percentage.toStringAsFixed(0)}% complete",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onLogWater,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      "Log your water",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
