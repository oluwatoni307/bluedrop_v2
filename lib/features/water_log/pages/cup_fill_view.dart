import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme.dart';

// =============================================================================
// PUBLIC CONTRACT — unchanged. SmartLogSheet (Task 3) already integrates
// against this exact signature; do not change it without updating that call
// site too.
//
// CupFillView(
//   cupVolumeMl: 350,
//   initialMode: FillMode.left,       // optional, defaults to FillMode.left
//   onComplete: (ml) { ... },         // called on confirm tap, returns final ml
//   onClose: () { ... },              // called on close tap — closes the
//                                      // whole sheet, per confirmed decision
// )
// =============================================================================

enum FillMode { left, drunk }

class _PresetDef {
  final String label;
  final double value;
  const _PresetDef(this.label, this.value);
}

class CupFillView extends StatefulWidget {
  final int cupVolumeMl;
  final FillMode initialMode;
  final ValueChanged<int> onComplete;
  final VoidCallback onClose;

  const CupFillView({
    super.key,
    required this.cupVolumeMl,
    required this.onComplete,
    required this.onClose,
    this.initialMode = FillMode.left,
  });

  @override
  State<CupFillView> createState() => _CupFillViewState();
}

class _CupFillViewState extends State<CupFillView>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------

  double _fraction = 0.5;
  FillMode _mode = FillMode.left;

  static const List<_PresetDef> _presets = [
    _PresetDef('¼', 0.25),
    _PresetDef('⅓', 1 / 3),
    _PresetDef('⅔', 2 / 3),
    _PresetDef('¾', 0.75),
    _PresetDef('Full', 1.0),
  ];

  late AnimationController _settleController;
  Animation<double>? _settleAnimation;

  /// Drives the continuously-looping liquid-surface wave. Unlike
  /// _settleController (which runs once per preset tap), this repeats
  /// indefinitely for as long as the sheet is open.
  late AnimationController _waveController;

  /// Guards against starting _waveController more than once —
  /// didChangeDependencies() can fire multiple times (e.g. on theme or
  /// MediaQuery changes), but we only want to kick off the repeat() once.
  bool _waveStarted = false;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _settleController = AnimationController(vsync: this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    // NOTE: starting the wave here would crash — MediaQuery (needed by
    // _reduceMotion) isn't available yet inside initState(). See
    // didChangeDependencies() below, which is the correct place for any
    // InheritedWidget-dependent setup that needs to run once at startup.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_waveStarted && !_reduceMotion) {
      _waveStarted = true;
      _waveController.repeat();
    }
  }

  @override
  void dispose() {
    _settleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // INPUT HANDLERS
  // ---------------------------------------------------------------------

  void _onSliderChanged(double value) {
    if (_settleController.isAnimating) _settleController.stop();
    setState(() => _fraction = value.clamp(0.0, 1.0));
  }

  void _onPresetTapped(double target) {
    final double from = _settleAnimation?.value ?? _fraction;

    if (_reduceMotion) {
      _settleController
        ..stop()
        ..duration = const Duration(milliseconds: 150);
      _settleAnimation = Tween<double>(begin: from, end: target).animate(
        CurvedAnimation(parent: _settleController, curve: Curves.easeOut),
      )..addListener(() => setState(() => _fraction = _settleAnimation!.value));
      _settleController
        ..reset()
        ..forward();
      return;
    }

    const double overshootFraction = 0.015;
    final double overshootTarget =
        (target + (target >= from ? overshootFraction : -overshootFraction))
            .clamp(0.0, 1.0);

    _settleController
      ..stop()
      ..duration = const Duration(milliseconds: 350);

    final sequence = TweenSequence<double>([
      TweenSequenceItem(
        weight: 65,
        tween: Tween<double>(
          begin: from,
          end: overshootTarget,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      TweenSequenceItem(
        weight: 35,
        tween: Tween<double>(
          begin: overshootTarget,
          end: target,
        ).chain(CurveTween(curve: Curves.easeInOutBack)),
      ),
    ]);

    _settleAnimation = sequence.animate(_settleController)
      ..addListener(() => setState(() => _fraction = _settleAnimation!.value));

    _settleController
      ..reset()
      ..forward();
  }

  double get _settleIntensity {
    if (!_settleController.isAnimating) return 0.0;
    final t = _settleController.value;
    return (1 - (2 * t - 1).abs()).clamp(0.0, 1.0);
  }

  void _onModeToggled(FillMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    // Per spec: toggling never touches the cup fill, only the readout.
  }

  int get _resolvedMl {
    final raw =
        widget.cupVolumeMl *
        (_mode == FillMode.drunk ? _fraction : (1 - _fraction));
    return raw.round();
  }

  void _onConfirm() => widget.onComplete(_resolvedMl);

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const Color indigo = AppTheme.primaryAction;
    const Color outline = Color(0xFFCBD5E1);
    const Color warmNeutral = AppTheme.surfaceMuted;
    const Color darkText = AppTheme.darkText;
    const Color lightText = AppTheme.lightText;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(darkText, lightText),
          const SizedBox(height: 4),

          // --- Cup zone ---
          // Was Expanded + LayoutBuilder, sizing off whatever ambient
          // constraint it received. Inside AnimatedSwitcher's Stack-based
          // layout that constraint isn't reliably bounded — if it resolved
          // to Infinity, cupHeight/cupWidth went infinite and fed straight
          // into CustomPaint's canvas calls, which lines up with the
          // blank-then-crash on cup tap. MediaQuery-based sizing is
          // deterministic regardless of ambient layout, and gives
          // CupFillView a real intrinsic height — which is also what lets
          // the AnimatedSize wrapper in smart_log_sheet.dart ease the
          // sheet's height instead of snapping it.
          _buildCupZone(indigo, outline),

          const SizedBox(height: 16),

          // --- Slider ---
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: _fraction,
              onChanged: _onSliderChanged,
              min: 0.0,
              max: 1.0,
              activeColor: indigo,
              inactiveColor: outline.withValues(alpha: 0.4),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$_resolvedMl ml',
            style:
                theme.textTheme.headlineSmall?.copyWith(
                  color: darkText,
                  fontWeight: FontWeight.w800,
                ) ??
                const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
          ),

          const SizedBox(height: 20),

          // --- Preset chips (replaces the old cup-edge tick marks —
          // simpler, more legible, and matches the finalized mockup) ---
          _buildPresetsRow(indigo, outline, darkText),

          const SizedBox(height: 20),

          // --- Mode toggle — TEXT labels, not icons. The original
          // icon-based toggle (a drop glyph vs a cup glyph) tested as an
          // unclear signifier; plain text removes the ambiguity. ---
          _buildModeToggle(indigo, warmNeutral, lightText),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: const Text(
                'Log this',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color darkText, Color lightText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'How much water?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: lightText),
          onPressed: widget.onClose, // closes the whole sheet — confirmed
        ),
      ],
    );
  }

  /// Bounded, deterministic sizing for the cup drawing area. Height is a
  /// fraction of screen height (clamped so it stays sane on very short or
  /// very tall devices) rather than derived from an Expanded/LayoutBuilder
  /// constraint that could resolve unbounded inside AnimatedSwitcher's
  /// layout. See the call site comment in build() for why this replaced
  /// the previous Expanded-based approach.
  Widget _buildCupZone(Color indigo, Color outline) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double cupHeight = (screenHeight * 0.32).clamp(200.0, 340.0);
    final double cupWidth = cupHeight * 0.52;

    return SizedBox(
      height: cupHeight,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_waveController]),
          builder: (context, _) {
            return CustomPaint(
              size: Size(cupWidth, cupHeight),
              painter: _CupPainter(
                fraction: _fraction,
                liquidColor: indigo,
                strokeColor: outline,
                settleIntensity: _settleIntensity,
                wavePhase: _reduceMotion
                    ? 0.0
                    : _waveController.value * 2 * math.pi,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresetsRow(Color indigo, Color outline, Color darkText) {
    return Row(
      children: _presets.map((p) {
        final bool isActive = (_fraction - p.value).abs() < 0.006;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => _onPresetTapped(p.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? indigo : Colors.white,
                  border: Border.all(
                    color: isActive ? indigo : outline,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : darkText,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeToggle(Color indigo, Color muted, Color lightText) {
    return Container(
      decoration: BoxDecoration(
        color: muted,
        borderRadius: BorderRadius.circular(99),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton('Left', FillMode.left, indigo, lightText),
          _modeButton('Drunk', FillMode.drunk, indigo, lightText),
        ],
      ),
    );
  }

  Widget _modeButton(
    String label,
    FillMode mode,
    Color indigo,
    Color lightText,
  ) {
    final bool selected = _mode == mode;
    return GestureDetector(
      onTap: () => _onModeToggled(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : lightText,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CUP PAINTER
// =============================================================================
//
// Rewritten again after the user's direct "I don't like it" on the previous
// static-meniscus version. This pass ports the two techniques that were
// explicitly asked to survive from the HTML reference: a continuously
// animated wave surface (instead of a static curve) and an elliptical rim
// for a 3D, "looking down into a glass" read.

class _CupPainter extends CustomPainter {
  final double fraction;
  final Color liquidColor;
  final Color strokeColor;
  final double settleIntensity;

  /// 0..2π, advances continuously — drives the horizontal phase of the
  /// liquid surface wave. Frozen at 0.0 by the caller when reduced-motion
  /// is enabled.
  final double wavePhase;

  static const double strokeWidth = 3.0;
  static const double fillInset = 4.0;
  static const double _waveAmplitudeA = 3.5;
  static const double _waveAmplitudeB = 2.2;

  const _CupPainter({
    required this.fraction,
    required this.liquidColor,
    required this.strokeColor,
    required this.wavePhase,
    this.settleIntensity = 0.0,
  });

  static double liquidTopYFor({
    required double fraction,
    required double height,
    required double inset,
  }) {
    final fillableHeight = height - inset * 2;
    return inset + fillableHeight * (1 - fraction.clamp(0.0, 1.0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path cupPath = _buildCupSilhouette(size);

    _paintGroundShadow(canvas, size);

    canvas.save();
    canvas.clipPath(cupPath);
    _paintGlassBody(canvas, size);
    _paintLiquid(canvas, size);
    canvas.restore();

    _paintGlassHighlight(canvas, size, cupPath);
    _paintInnerBaseShadow(canvas, size, cupPath);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(cupPath, strokePaint);

    _paintRimEllipses(canvas, size);
  }

  Path _buildCupSilhouette(Size size) {
    final w = size.width;
    final h = size.height;
    const cornerRadius = 16.0;
    const taper = 0.08;

    final bottomLeftX = w * taper;
    final bottomRightX = w * (1 - taper);

    return Path()
      ..moveTo(0, 0)
      ..lineTo(bottomLeftX, h - cornerRadius)
      ..quadraticBezierTo(bottomLeftX, h, bottomLeftX + cornerRadius, h)
      ..lineTo(bottomRightX - cornerRadius, h)
      ..quadraticBezierTo(bottomRightX, h, bottomRightX, h - cornerRadius)
      ..lineTo(w, 0)
      ..close();
  }

  /// Two thin stroked ellipses near the rim — the "looking down into a
  /// round glass" cue ported from the HTML reference. The main body stays
  /// a simple tapered silhouette; these two rings do the 3D work.
  void _paintRimEllipses(Canvas canvas, Size size) {
    final outerRim = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.045),
      width: size.width * 0.99,
      height: size.height * 0.065,
    );
    final innerRim = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.085),
      width: size.width * 0.87,
      height: size.height * 0.05,
    );

    final outerPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final innerPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(outerRim, outerPaint);
    canvas.drawOval(innerRim, innerPaint);
  }

  void _paintGlassBody(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          liquidColor.withValues(alpha: 0.05),
          liquidColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// Liquid surface is now a continuously animated double-sine wave
  /// (replacing the old static quadratic meniscus curve), matching the
  /// reference mockup's turbulence-driven surface — approximated here
  /// with two overlapping sine layers rather than true SVG noise, which
  /// isn't practical to replicate in CustomPainter but reads just as
  /// alive at this scale.
  void _paintLiquid(Canvas canvas, Size size) {
    if (fraction <= 0.0) return; // true empty — no liquid painted.

    final liquidTopY = liquidTopYFor(
      fraction: fraction,
      height: size.height,
      inset: fillInset,
    );

    final ampBoost = 1.0 + settleIntensity * 0.6;
    final wavelengthA = size.width / 1.6;
    final wavelengthB = size.width / 2.3;

    Path buildWavePath(double amplitude, double wavelength, double phase) {
      final path = Path()..moveTo(fillInset, size.height - fillInset);
      path.lineTo(fillInset, liquidTopY);
      for (double x = fillInset; x <= size.width - fillInset; x += 4) {
        final y =
            liquidTopY +
            amplitude * ampBoost * math.sin((x / wavelength) + phase);
        path.lineTo(x, y);
      }
      path.lineTo(size.width - fillInset, size.height - fillInset);
      path.close();
      return path;
    }

    final liquidBounds = Rect.fromLTWH(
      0,
      liquidTopY - _waveAmplitudeA - 2,
      size.width,
      size.height - (liquidTopY - _waveAmplitudeA - 2),
    );

    final lighter = Color.lerp(liquidColor, Colors.white, 0.25)!;
    final deeper = Color.lerp(liquidColor, Colors.black, 0.20)!;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lighter, liquidColor, deeper],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(liquidBounds);

    // Back wave layer — main liquid body.
    canvas.drawPath(
      buildWavePath(_waveAmplitudeA, wavelengthA, wavePhase),
      basePaint,
    );

    // Front wave layer — subtler, offset phase/speed, translucent tint,
    // sits just above the base fill for a bit of surface texture.
    final frontPaint = Paint()
      ..color = Color.lerp(
        liquidColor,
        Colors.white,
        0.35,
      )!.withValues(alpha: 0.35);
    canvas.drawPath(
      buildWavePath(_waveAmplitudeB, wavelengthB, -wavePhase * 1.4 + math.pi),
      frontPaint,
    );
  }

  void _paintGlassHighlight(Canvas canvas, Size size, Path cupPath) {
    canvas.save();
    canvas.clipPath(cupPath);

    final streakX = size.width * 0.24;
    final streakRect = Rect.fromLTWH(streakX - 14, 0, 28, size.height);

    final streakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.02),
          const Color(0xFF1E293B).withValues(alpha: 0.10),
          const Color(0xFF1E293B).withValues(alpha: 0.02),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(streakRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final streakPath = Path()
      ..moveTo(streakX, 0)
      ..lineTo(streakX + 9, 0)
      ..lineTo(streakX - 5, size.height)
      ..lineTo(streakX - 14, size.height)
      ..close();

    canvas.drawPath(streakPath, streakPaint);
    canvas.restore();
  }

  void _paintInnerBaseShadow(Canvas canvas, Size size, Path cupPath) {
    canvas.save();
    canvas.clipPath(cupPath);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height + 4),
        width: size.width * 1.2,
        height: 30,
      ),
      shadowPaint,
    );

    canvas.restore();
  }

  void _paintGroundShadow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height + 10),
        width: size.width * 0.85,
        height: 16,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CupPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.settleIntensity != settleIntensity ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.liquidColor != liquidColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

// =============================================================================
// IMPLEMENTATION NOTES FOR THE BUILDING AGENT
// =============================================================================
//
// 1. Public contract (CupFillView constructor) is UNCHANGED from the version
//    Task 3 already integrated — no changes needed in smart_log_sheet.dart
//    beyond wrapping _buildCabinetBody()'s AnimatedSwitcher in AnimatedSize
//    (see that file's own notes).
//
// 2. BUG FIX (earlier pass): initState() was calling _reduceMotion (which
//    reads MediaQuery.maybeOf(context)) to decide whether to start
//    _waveController.repeat(). That's illegal — MediaQuery isn't
//    reachable yet inside initState(). Fixed by moving the wave-start
//    decision to didChangeDependencies(), guarded by _waveStarted so it
//    only fires once even though didChangeDependencies() can re-run on
//    later dependency changes. Unrelated to the fix in this pass — kept
//    here for context, not touched again.
//
// 3. BUG FIX (this pass): the cup zone was `Expanded(child: Center(child:
//    LayoutBuilder(...)))`, sizing cupHeight/cupWidth directly off
//    `constraints.maxHeight`. Inside AnimatedSwitcher's Stack-based
//    layout, that constraint isn't guaranteed to be a small finite
//    number — it can resolve to something effectively unbounded
//    depending on the ambient layout at the moment of the cup tap. When
//    that happened, cupHeight/cupWidth went infinite/NaN and were passed
//    straight into CustomPaint's size and from there into _CupPainter's
//    canvas calls (gradients, drawPath, drawOval) — which Skia does not
//    fail on gracefully, matching the observed "blank, then the app
//    crashes" behavior on cup tap. Replaced with _buildCupZone(), which
//    sizes off MediaQuery.sizeOf(context).height directly (clamped to a
//    sane 200–340 range) instead of an ambient BoxConstraints value —
//    deterministic regardless of what's above it in the tree. This also
//    gives CupFillView a real, finite intrinsic height instead of "fill
//    whatever's available," which is what lets the AnimatedSize wrapper
//    in smart_log_sheet.dart actually animate the sheet's height instead
//    of snapping it.
//
// 4. Still worth confirming on-device: this removes the specific
//    mechanism hypothesized to cause the crash, based on static review
//    of the code — not confirmed yet against an actual crash log. If the
//    crash persists after this change, the next step is grabbing the
//    attached `flutter run` output at the moment of failure (looking for
//    a Dart stack trace vs. a bare engine-level fatal signal) rather than
//    guessing further.
//
// 5. What changed in earlier passes (visual/behavioral, not bug fixes),
//    kept for context:
//    - Static meniscus curve -> continuously animated double-sine wave.
//    - Flat-rim tumbler -> added two stroked rim ellipses near the top.
//    - Preset ticks on the cup edge -> row of labeled chip buttons
//      (¼ ⅓ ⅔ ¾ Full) below the slider.
//    - Icon-based mode toggle -> plain text labels ("Left" / "Drunk").
//
// 6. _waveController runs continuously (..repeat()) for as long as the
//    widget is mounted, independent of _settleController. Both are
//    disposed in dispose(). Performance under continuous CustomPaint
//    repaint inside a bottom sheet is still untested on-device — separate
//    from the sizing bug fixed in this pass.
//
// 7. Reduced motion: wave phase is frozen at 0.0 (controller never
//    started) rather than just skipping the *rebuild* — avoids an
//    unnecessary repeating animation ticking in the background for users
//    who've opted out of motion.
