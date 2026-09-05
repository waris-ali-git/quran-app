part of 'onboarding_screen.dart';

// ──────────────────────────────────────────────────────────────
// Page 1: Welcome Screen
// ──────────────────────────────────────────────────────────────
class _OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onNext;
  const _OnboardingWelcomePage({required this.onNext});

  @override
  State<_OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<_OnboardingWelcomePage>
    with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _dustCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _twinkleCtrl;
  late final AnimationController _waveCtrl;

  // ── Entrance Animations ────────────────────────────────────
  late final Animation<double>  _fadeIn;
  late final Animation<Offset>  _slideArabic;
  late final Animation<Offset>  _slideCrescent;
  late final Animation<Offset>  _slideText;
  late final Animation<Offset>  _slideBtn;

  // ── Continuous Animations ──────────────────────────────────
  late final Animation<double>  _floatAnim;
  late final Animation<double>  _shimmerAnim;
  late final Animation<double>  _pulseAnim;
  late final Animation<double>  _twinkleAnim;

  // ── Particle lists ─────────────────────────────────────────
  late final List<_DustParticle>    _dustParticles;
  late final List<_SparkleParticle> _sparkles;
  late final List<_RippleParticle>  _ripples;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1600))..forward();
    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _dustCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _twinkleCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 6))..repeat();

    _fadeIn = CurvedAnimation(parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));

    _slideArabic   = _slide(_entranceCtrl, 0.00, 0.55, 0.28);
    _slideCrescent = _slide(_entranceCtrl, 0.10, 0.70, 0.40);
    _slideText     = _slide(_entranceCtrl, 0.25, 0.85, 0.35);
    _slideBtn      = _slideUp(_entranceCtrl, 0.50, 1.00, 0.55);

    _floatAnim   = Tween<double>(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _pulseAnim   = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _twinkleAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _twinkleCtrl, curve: Curves.easeInOut));

    final rng = math.Random(77);
    _dustParticles = List.generate(40, (i) => _DustParticle(
      startX: rng.nextDouble() * 0.95,
      startY: 1.05 + rng.nextDouble() * 0.20,
      driftX: -0.06 + rng.nextDouble() * 0.14,
      speed:   0.04 + rng.nextDouble() * 0.07,
      radius:  1.2 + rng.nextDouble() * 3.2,
      maxOpacity: 0.25 + rng.nextDouble() * 0.45,
      delay:   rng.nextDouble(),
      glowSize: 3.0 + rng.nextDouble() * 5.0,
    ));

    _sparkles = List.generate(18, (i) => _SparkleParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.75,
      radius: 1.0 + rng.nextDouble() * 2.0,
      phase: rng.nextDouble() * math.pi * 2,
    ));

    _ripples = List.generate(4, (i) => _RippleParticle(
      delay: i * 0.25,
      maxRadius: 0.16 + i * 0.04,
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
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _dustCtrl.dispose();
    _pulseCtrl.dispose();
    _twinkleCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double minDim = math.min(size.width, size.height);
    // Clamp crescent size so it doesn't become enormous on large screens
    final double crescentSize = (minDim * 0.44).clamp(110.0, 260.0);
    final double rippleSize   = (minDim * 0.60).clamp(150.0, 340.0);

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
              // ① Background mandala watermark
              Positioned(
                top: -size.width * 0.15,
                right: -size.width * 0.18,
                child: AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (_, __) => Opacity(
                    opacity: 0.04 + _shimmerAnim.value * 0.03,
                    child: _GeometricMandala(size: size.width * 1.05),
                  ),
                ),
              ),

              // ② Silver-blue glowing dust
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

              // ③ Background star sparkles
              AnimatedBuilder(
                animation: _twinkleCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size(size.width, size.height),
                  painter: _SparklePainter(
                    sparkles: _sparkles,
                    twinkle: _twinkleAnim.value,
                  ),
                ),
              ),

              // ④ Bottom soft wave
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

              // ⑤ Main content (render-safe column)
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Arabic bismillah — fixed header
                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideArabic,
                        child: _ArabicGreeting(shimmer: _shimmerAnim),
                      ),
                    ),

                    // Scrollable middle: crescent + title + subtitle
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),

                              // Crescent moon with ripples
                              AnimatedBuilder(
                                animation: Listenable.merge(
                                    [_floatCtrl, _pulseCtrl, _dustCtrl]),
                                builder: (_, __) => SlideTransition(
                                  position: _slideCrescent,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Ripples behind crescent
                                      AnimatedBuilder(
                                        animation: _dustCtrl,
                                        builder: (_, __) => CustomPaint(
                                          size: Size(rippleSize, rippleSize),
                                          painter: _RipplePainter(
                                            ripples: _ripples,
                                            progress: _dustCtrl.value,
                                          ),
                                        ),
                                      ),
                                      // Crescent
                                      Transform.translate(
                                        offset: Offset(0, _floatAnim.value),
                                        child: _CrescentWidget(
                                          size: crescentSize,
                                          shimmer: _shimmerAnim.value,
                                          twinkle: _twinkleAnim.value,
                                          glowPulse: _pulseAnim.value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Title
                              SlideTransition(
                                position: _slideText,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Your Spiritual Companion',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w700,
                                      color: _navy,
                                      height: 1.25,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Subtitle
                              SlideTransition(
                                position: _slideText,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 44),
                                  child: Text(
                                    'Quran · Hadith · Prayers · Dua\nbeautifully crafted for your daily journey.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: _steelBlue,
                                      height: 1.65,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Page dots
                    FadeTransition(
                      opacity: _fadeIn,
                      child: const _PageDots(total: 4, active: 0),
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
                            label: 'Next',
                            onTap: widget.onNext,
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
