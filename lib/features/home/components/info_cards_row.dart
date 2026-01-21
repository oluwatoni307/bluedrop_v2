import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class InfoCardsRow extends StatelessWidget {
  final double glassLevel;
  final String lastLogTime;
  final int lastLogAmount;
  final int activeChallengesCount;

  const InfoCardsRow({
    Key? key,
    required this.glassLevel,
    required this.lastLogTime,
    required this.lastLogAmount,
    required this.activeChallengesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. GLASS WIDGET (Unchanged)
        SizedBox(
          width: 115,
          height: 115,
          child: ElegantGlassWidget(
            level: glassLevel,
            waterColor: const Color(0xFF5DADE2),
          ),
        ),
        const SizedBox(width: 20),

        // 2. RIGHT COLUMN
        Column(
          children: [
            // A. LAST LOG CARD (Unchanged)
            _buildCard(
              title: "Last Log",
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        lastLogTime,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: glassLevel,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF5DADE2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${lastLogAmount}ml",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5DADE2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${(glassLevel * 100).round()}%",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // B. ACTIVE GOALS CARD (Imitating Challenge Page Style)
            _buildCard(
              title: "Side Quests",
              content: Row(
                // 🔥 CHANGE 1: Start alignment (No more spaceBetween)
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 🔥 CHANGE 2: Icon First (Like Challenge Row)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5), // Light Purple
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      size: 18,
                      color: Color(0xFF8E24AA), // Deep Purple
                    ),
                  ),

                  // 🔥 CHANGE 3: Fixed Gap
                  const SizedBox(width: 12),

                  // Number
                  Text(
                    "$activeChallengesCount",
                    style: GoogleFonts.poppins(
                      fontSize: 22, // Slightly larger for emphasis
                      color: Colors.blueGrey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Optional label next to number
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0), // Align baseline
                    child: Text(
                      activeChallengesCount == 1 ? "Goal" : "Goals",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper Widget for Cards
  Widget _buildCard({required String title, required Widget content}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 8), // Slightly more spacing for cleaner look
          content,
        ],
      ),
    );
  }
}

// ... (ElegantGlassWidget code remains unchanged below)

// Elegant Glass Widget with animated water effect
class ElegantGlassWidget extends StatefulWidget {
  final double level;
  final Color waterColor;

  const ElegantGlassWidget({
    Key? key,
    required this.level,
    this.waterColor = Colors.lightBlueAccent,
  }) : super(key: key);

  @override
  State<ElegantGlassWidget> createState() => _ElegantGlassWidgetState();
}

class _ElegantGlassWidgetState extends State<ElegantGlassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ElegantGlassPainter(
            level: widget.level,
            wavePhase: _waveController.value,
            waterColor: widget.waterColor,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ElegantGlassPainter extends CustomPainter {
  final double level;
  final double wavePhase;
  final Color waterColor;

  _ElegantGlassPainter({
    required this.level,
    required this.wavePhase,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double topWidth = size.width * 0.9;
    final double bottomWidth = size.width * 0.6;
    final double height = size.height;

    final double topX = (size.width - topWidth) / 2;
    final double bottomX = (size.width - bottomWidth) / 2;

    final Path glassPath = Path()
      ..moveTo(topX, 0)
      ..quadraticBezierTo(topX, height * 0.5, bottomX, height)
      ..lineTo(bottomX + bottomWidth, height)
      ..quadraticBezierTo(topX + topWidth, height * 0.5, topX + topWidth, 0)
      ..close();

    // Glass gradient
    final Paint glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(glassPath, glassPaint);

    // Glass outline
    final Paint outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.7), Colors.grey.withOpacity(0.5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(glassPath, outlinePaint);

    // Clip water to glass
    canvas.save();
    canvas.clipPath(glassPath);

    final double fillHeight = height * level;
    final double waterTop = height - fillHeight;

    final Path wavePath = Path();
    final int waveCount = 2;
    final double amplitude = size.height * 0.025;
    final double wavelength = size.width / waveCount;

    wavePath.moveTo(0, waterTop);

    for (double x = 0; x <= size.width; x++) {
      double y =
          waterTop +
          math.sin((x / wavelength + wavePhase * 2 * math.pi)) * amplitude;
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    final Paint waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [waterColor.withOpacity(0.9), waterColor.withOpacity(0.6)],
      ).createShader(Rect.fromLTWH(0, waterTop, size.width, fillHeight));

    canvas.drawPath(wavePath, waterPaint);

    canvas.restore();

    // Shimmer
    final Paint shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.2), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.3, size.height));

    final Path shimmer = Path()
      ..moveTo(topX + topWidth * 0.3, 0)
      ..lineTo(topX + topWidth * 0.35, 0)
      ..lineTo(bottomX + bottomWidth * 0.45, height)
      ..lineTo(bottomX + bottomWidth * 0.4, height)
      ..close();

    canvas.drawPath(shimmer, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
