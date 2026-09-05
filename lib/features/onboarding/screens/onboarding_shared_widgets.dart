part of 'onboarding_screen.dart';

// ──────────────────────────────────────────────────────────────
// Arabic Greeting  (Page 1)
// ──────────────────────────────────────────────────────────────
class _ArabicGreeting extends StatelessWidget {
  final Animation<double> shimmer;
  const _ArabicGreeting({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: shimmer,
          builder: (_, __) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                _deepBlue,
                Color.lerp(_carolina, _gold, shimmer.value * 0.5)!,
                _deepBlue,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Jameel Noori',
                fontSize: 29,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'In the Name of Allah, the Most Gracious, the Most Merciful',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _steelBlue.withValues(alpha: 0.80),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Crescent Widget  (Page 1)
// ──────────────────────────────────────────────────────────────
class _CrescentWidget extends StatelessWidget {
  final double size;
  final double shimmer;
  final double twinkle;
  final double glowPulse;
  const _CrescentWidget({
    required this.size,
    required this.shimmer,
    required this.twinkle,
    required this.glowPulse,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrescentPainter(
          shimmer: shimmer,
          twinkle: twinkle,
          glowPulse: glowPulse,
        ),
      ),
    );
  }
}

class _CrescentPainter extends CustomPainter {
  final double shimmer;
  final double twinkle;
  final double glowPulse;
  _CrescentPainter({
    required this.shimmer,
    required this.twinkle,
    required this.glowPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R  = size.width * 0.36;

    final outer = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: R));

    final innerCenter = Offset(cx + R * 0.45, cy - R * 0.05);
    final inner = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: R * 0.82));

    final crescent = Path.combine(PathOperation.difference, outer, inner);

    final glowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + glowPulse * 16)
      ..color = _gold.withValues(alpha: 0.20 + glowPulse * 0.40);
    canvas.drawPath(crescent, glowPaint);

    final gradRect = Rect.fromCircle(center: Offset(cx, cy), radius: R);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.4),
        radius: 1.0,
        colors: [
          Colors.white,
          Color.lerp(_gold, const Color(0xFFFFF3B0), 0.4)!,
          _gold,
          _goldDark,
        ],
        stops: const [0.0, 0.30, 0.65, 1.0],
      ).createShader(gradRect);
    canvas.drawPath(crescent, fillPaint);

    final sheenPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.45 + shimmer * 0.25);
    canvas.drawPath(crescent, sheenPaint);

    final shadowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 6)
      ..color = const Color(0xFFF39C12).withValues(alpha: 0.3);
    canvas.drawPath(crescent, shadowPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _gold.withValues(alpha: 0.12 + glowPulse * 0.16);
    canvas.drawCircle(Offset(cx, cy), R * 1.18, ringPaint);
    canvas.drawCircle(Offset(cx, cy), R * 1.32, ringPaint..color = _gold.withValues(alpha: 0.05 + glowPulse * 0.06));

    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) - math.pi / 2;
      final big  = i % 2 == 0;
      final rIn  = R * 1.35;
      final rOut = R * (big ? 1.62 : 1.50);
      rayPaint
        ..color = _gold.withValues(alpha: (big ? 0.35 : 0.18) * (0.5 + glowPulse * 0.5))
        ..strokeWidth = big ? 2.0 : 1.2;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * rIn, cy + math.sin(angle) * rIn),
        Offset(cx + math.cos(angle) * rOut, cy + math.sin(angle) * rOut),
        rayPaint,
      );
    }

    final starX = cx + R * 1.10;
    final starY = cy - R * 0.60;
    _drawStar(canvas, Offset(starX, starY), R * 0.13, R * 0.055,
        _gold.withValues(alpha: twinkle));

    final starGlow = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5)
      ..color = _gold.withValues(alpha: 0.5 * twinkle);
    canvas.drawCircle(Offset(starX, starY), R * 0.10, starGlow);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dots = [
      (cx - R * 1.35, cy - R * 0.45, 2.4, 0.65),
      (cx + R * 0.15, cy - R * 1.50, 1.8, 0.55),
      (cx - R * 0.55, cy + R * 1.30, 1.5, 0.45),
      (cx + R * 1.40, cy + R * 0.35, 1.3, 0.50),
      (cx - R * 1.0,  cy + R * 0.80, 1.2, 0.40),
    ];
    for (final d in dots) {
      dotPaint.color = Colors.white.withValues(alpha: d.$4 * (0.6 + shimmer * 0.4));
      canvas.drawCircle(Offset(d.$1, d.$2), d.$3, dotPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double outer, double inner, Color color) {
    const pts = 4;
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < pts * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = i * math.pi / pts - math.pi / 2;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrescentPainter old) =>
      old.shimmer != shimmer || old.twinkle != twinkle || old.glowPulse != glowPulse;
}

// ──────────────────────────────────────────────────────────────
// Silver-Blue Glowing Dust Particle
// ──────────────────────────────────────────────────────────────
class _DustParticle {
  final double startX, startY, driftX, speed, radius, maxOpacity, delay, glowSize;
  const _DustParticle({
    required this.startX,
    required this.startY,
    required this.driftX,
    required this.speed,
    required this.radius,
    required this.maxOpacity,
    required this.delay,
    required this.glowSize,
  });
}

class _DustPainter extends CustomPainter {
  final List<_DustParticle> particles;
  final double progress;
  const _DustPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay + 1.0) % 1.0);
      final py = (p.startY - t * p.speed * 12.0) * size.height;
      final px = (p.startX + t * p.driftX) * size.width;

      double opacity;
      if (t < 0.25) {
        opacity = (t / 0.25) * p.maxOpacity;
      } else if (t < 0.70) {
        opacity = p.maxOpacity;
      } else {
        opacity = ((1.0 - t) / 0.30) * p.maxOpacity;
      }

      if (py < 0 || py > size.height || opacity <= 0) continue;

      final glowPaint = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.glowSize)
        ..color = _silverBlue.withValues(alpha: opacity * 0.65);
      canvas.drawCircle(Offset(px, py), p.radius * 2.0, glowPaint);

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(px, py), p.radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(_DustPainter old) => old.progress != progress;
}

// ──────────────────────────────────────────────────────────────
// Background Sparkle Stars
// ──────────────────────────────────────────────────────────────
class _SparkleParticle {
  final double x, y, radius, phase;
  const _SparkleParticle({required this.x, required this.y, required this.radius, required this.phase});
}

class _SparklePainter extends CustomPainter {
  final List<_SparkleParticle> sparkles;
  final double twinkle;
  const _SparklePainter({required this.sparkles, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final alpha = (0.4 + 0.6 * ((math.sin(s.phase + twinkle * math.pi * 2) + 1) / 2)) * 0.55;
      final paint = Paint()
        ..color = _carolina.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.twinkle != twinkle;
}

// ──────────────────────────────────────────────────────────────
// Ripple Rings (expanding from crescent area)
// ──────────────────────────────────────────────────────────────
class _RippleParticle {
  final double delay, maxRadius;
  const _RippleParticle({required this.delay, required this.maxRadius});
}

class _RipplePainter extends CustomPainter {
  final List<_RippleParticle> ripples;
  final double progress;
  const _RipplePainter({required this.ripples, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final rp in ripples) {
      final t = ((progress - rp.delay + 1.0) % 1.0);
      final r = t * rp.maxRadius * size.width;
      final alpha = (1.0 - t) * 0.18;
      if (alpha <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _carolina.withValues(alpha: alpha);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}

// ──────────────────────────────────────────────────────────────
// Soft Bottom Wave
// ──────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double progress;
  const _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _carolina.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;

    for (int w = 0; w < 2; w++) {
      final phase = progress * math.pi * 2 + w * math.pi;
      final path = Path();
      path.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 2) {
        final y = size.height * 0.35 +
            math.sin(x / size.width * math.pi * 2 + phase) * size.height * 0.22 +
            math.sin(x / size.width * math.pi * 3 + phase * 1.3) * size.height * 0.12;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

// ──────────────────────────────────────────────────────────────
// Geometric Mandala Background
// ──────────────────────────────────────────────────────────────
class _GeometricMandala extends StatelessWidget {
  final double size;
  const _GeometricMandala({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MandalaPainter(),
    );
  }
}

class _MandalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _steelBlue.withValues(alpha: 0.22)
      ..strokeWidth = 0.75;

    for (int ring = 1; ring <= 7; ring++) {
      final r = size.width * 0.065 * ring;
      canvas.drawCircle(Offset(cx, cy), r, paint);
      final sides = 4 + ring * 2;
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = (i / sides) * math.pi * 2 - math.pi / 2;
        final pt = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MandalaPainter _) => false;
}

// ──────────────────────────────────────────────────────────────
// Page Indicator Dots
// ──────────────────────────────────────────────────────────────
class _PageDots extends StatelessWidget {
  final int total, active;
  const _PageDots({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: on ? _navy : _carolina.withValues(alpha: 0.32),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Gradient CTA Button  (press-scale micro-interaction)
// ──────────────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 130));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => _ctrl.forward(),
      onTapUp:    (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [_deepBlue, _carolina],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _deepBlue.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TranslatedText(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
