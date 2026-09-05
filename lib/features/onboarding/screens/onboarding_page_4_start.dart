part of 'onboarding_screen.dart';

// ──────────────────────────────────────────────────────────────
// Page 4: Getting Started Screen
// ──────────────────────────────────────────────────────────────
class _OnboardingStartPage extends StatefulWidget {
  final VoidCallback onNext;
  const _OnboardingStartPage({required this.onNext});

  @override
  State<_OnboardingStartPage> createState() => _OnboardingStartPageState();
}

class _OnboardingStartPageState extends State<_OnboardingStartPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _dustCtrl;
  late final AnimationController _twinkleCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideHeader;
  late final Animation<Offset> _slideContent;
  late final Animation<Offset> _slideBtn;

  late final List<_DustParticle>    _dustParticles;
  late final List<_SparkleParticle> _sparkles;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _dustCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))..repeat();
    _twinkleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));

    _slideHeader  = _slide(_entranceCtrl, 0.00, 0.55, 0.25);
    _slideContent = _slide(_entranceCtrl, 0.15, 0.75, 0.35);
    _slideBtn     = _slideUp(_entranceCtrl, 0.50, 1.00, 0.50);

    final rng = math.Random(111);
    _dustParticles = List.generate(35, (i) => _DustParticle(
      startX: rng.nextDouble() * 0.95,
      startY: 1.05 + rng.nextDouble() * 0.20,
      driftX: -0.05 + rng.nextDouble() * 0.12,
      speed: 0.03 + rng.nextDouble() * 0.06,
      radius: 1.2 + rng.nextDouble() * 2.8,
      maxOpacity: 0.20 + rng.nextDouble() * 0.40,
      delay: rng.nextDouble(),
      glowSize: 2.5 + rng.nextDouble() * 4.0,
    ));

    _sparkles = List.generate(15, (i) => _SparkleParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.70,
      radius: 1.0 + rng.nextDouble() * 1.8,
      phase: rng.nextDouble() * math.pi * 2,
    ));
  }

  Animation<Offset> _slide(AnimationController c, double t0, double t1, double y) =>
      Tween<Offset>(begin: Offset(0, y), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Interval(t0, t1, curve: Curves.easeOutCubic)));

  Animation<Offset> _slideUp(AnimationController c, double t0, double t1, double y) =>
      Tween<Offset>(begin: Offset(0, y), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Interval(t0, t1, curve: Curves.easeOutBack)));

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _dustCtrl.dispose();
    _twinkleCtrl.dispose();
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _getStarted() async {
    await PreferencesService().setCompletedOnboarding(true);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double minDim = math.min(size.width, size.height);
    // Clamp sizes to prevent overflow on large or small screens
    final double outerRingSize  = (minDim * 0.45).clamp(80.0, 220.0);
    final double innerRingSize  = (minDim * 0.35).clamp(60.0, 170.0);
    final double coreDiskSize   = (minDim * 0.28).clamp(50.0, 140.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_skyTop, _skyMid, _skyMid, _mintBot],
            stops: [0.0, 0.30, 0.65, 1.0],
          ),
        ),
        child: RepaintBoundary(
          child: Stack(
            children: [
              // Background mandala
              Positioned(
                top: -size.width * 0.1,
                right: -size.width * 0.1,
                child: Opacity(
                  opacity: 0.035,
                  child: _GeometricMandala(size: size.width * 1.1),
                ),
              ),

              // Glowing dust
              AnimatedBuilder(
                animation: _dustCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size(size.width, size.height),
                  painter: _DustPainter(
                    particles: _dustParticles,
                    progress: _dustCtrl.value,
                  ),
                ),
              ),

              // Star sparkles
              AnimatedBuilder(
                animation: _twinkleCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size(size.width, size.height),
                  painter: _SparklePainter(
                    sparkles: _sparkles,
                    twinkle: _twinkleCtrl.value,
                  ),
                ),
              ),

              // Bottom soft wave
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) => CustomPaint(
                    size: Size(size.width, 90),
                    painter: _WavePainter(progress: _waveCtrl.value),
                  ),
                ),
              ),

              // Main content (render-safe column)
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Header title (fixed, always visible)
                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideHeader,
                        child: TranslatedText(
                          'You\'re All Set!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideHeader,
                        child: TranslatedText(
                          'Begin your daily connection with the words of Allah.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _steelBlue,
                          ),
                        ),
                      ),
                    ),

                    // Scrollable middle: glowing centerpiece + quote
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideContent,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 24),

                                // Animated Glowing Center Piece
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Pulsing glow outer ring
                                      AnimatedBuilder(
                                        animation: _pulseCtrl,
                                        builder: (_, __) {
                                          final scale = 1.0 + _pulseCtrl.value * 0.15;
                                          final opacity = 0.25 - _pulseCtrl.value * 0.15;
                                          return Transform.scale(
                                            scale: scale,
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: outerRingSize,
                                              height: outerRingSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _carolina.withValues(alpha: opacity),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Pulsing glow inner ring
                                      AnimatedBuilder(
                                        animation: _pulseCtrl,
                                        builder: (_, __) {
                                          final scale = 1.0 + _pulseCtrl.value * 0.08;
                                          final opacity = 0.40 - _pulseCtrl.value * 0.20;
                                          return Transform.scale(
                                            scale: scale,
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: innerRingSize,
                                              height: innerRingSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _deepBlue.withValues(alpha: opacity),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Inner core with book icon
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(100),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            width: coreDiskSize,
                                            height: coreDiskSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(alpha: 0.75),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.6),
                                                width: 2.0,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.auto_stories_rounded,
                                                size: 44,
                                                color: _navy,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Blessing context message / quote
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            width: 1.0,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            TranslatedText(
                                              '"The best among you are those who learn the Qur\'an and teach it."',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: _navy.withValues(alpha: 0.85),
                                                fontStyle: FontStyle.italic,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TranslatedText(
                                              '— Prophet Muhammad (ﷺ)',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: _steelBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Page Dots
                    FadeTransition(
                      opacity: _fadeIn,
                      child: const _PageDots(total: 4, active: 3),
                    ),

                    const SizedBox(height: 22),

                    // CTA button
                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideBtn,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: _GradientButton(
                            label: 'Get Started',
                            onTap: _getStarted,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
