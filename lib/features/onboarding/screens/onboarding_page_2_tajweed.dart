part of 'onboarding_screen.dart';

// ──────────────────────────────────────────────────────────────
// Page 2: Tajweed & Word-by-Word Page
// ──────────────────────────────────────────────────────────────
class _OnboardingTajweedPage extends StatefulWidget {
  final VoidCallback onNext;
  const _OnboardingTajweedPage({required this.onNext});

  @override
  State<_OnboardingTajweedPage> createState() => _OnboardingTajweedPageState();
}

class _OnboardingTajweedPageState extends State<_OnboardingTajweedPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _dustCtrl;
  late final AnimationController _twinkleCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _audioWaveCtrl;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideHeader;
  late final Animation<Offset> _slideCard;
  late final Animation<Offset> _slideText;
  late final Animation<Offset> _slideBtn;

  late final Animation<double> _floatAnim;
  late final Animation<double> _shimmerAnim;
  late final Animation<double> _twinkleAnim;

  late final List<_DustParticle>    _dustParticles;
  late final List<_SparkleParticle> _sparkles;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _dustCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))..repeat();
    _twinkleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))..repeat();
    _audioWaveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));

    _slideHeader = _slide(_entranceCtrl, 0.00, 0.55, 0.25);
    _slideCard   = _slide(_entranceCtrl, 0.10, 0.70, 0.35);
    _slideText   = _slide(_entranceCtrl, 0.25, 0.85, 0.30);
    _slideBtn    = _slideUp(_entranceCtrl, 0.50, 1.00, 0.50);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _twinkleAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _twinkleCtrl, curve: Curves.easeInOut));

    final rng = math.Random(88);
    _dustParticles = List.generate(30, (i) => _DustParticle(
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
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _dustCtrl.dispose();
    _twinkleCtrl.dispose();
    _waveCtrl.dispose();
    _audioWaveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                top: -size.width * 0.15,
                left: -size.width * 0.18,
                child: AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (_, __) => Opacity(
                    opacity: 0.03 + _shimmerAnim.value * 0.02,
                    child: _GeometricMandala(size: size.width * 1.05),
                  ),
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
                    twinkle: _twinkleAnim.value,
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
                    const SizedBox(height: 20),

                    // Fixed header title
                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideHeader,
                        child: Column(
                          children: [
                            Text(
                              'Tajweed & Translation',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _navy,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 48,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2.0),
                                color: _deepBlue.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Scrollable middle: Tajweed card + description
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              // Tajweed Card (Floating — properly animated)
                              SlideTransition(
                                position: _slideCard,
                                child: AnimatedBuilder(
                                  animation: _floatCtrl,
                                  builder: (_, child) => Transform.translate(
                                    offset: Offset(0, _floatAnim.value),
                                    child: child,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.70),
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.55),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(22),
                                          child: Column(
                                            children: [
                                              // Card top bar
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: _carolina.withValues(alpha: 0.16),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    child: Text(
                                                      'AL-FATIHAH (1:2)',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: _deepBlue,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  // Audio Wave representation
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.volume_up_rounded, size: 15, color: _steelBlue),
                                                      const SizedBox(width: 6),
                                                      _AudioWaveform(animation: _audioWaveCtrl),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 20),

                                              // Quran Arabic with Tajweed highlights
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: ' الْحَمْدُ َ',
                                                      style: TextStyle(color: _navy),
                                                    ),
                                                    const TextSpan(
                                                      text: 'لِلَّهِ ',
                                                      style: TextStyle(
                                                        color: Color(0xFFF39C12),
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: 'رَبِّ ',
                                                      style: TextStyle(
                                                        color: Color(0xFFC0392B),
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: 'الْعَالَمِين',
                                                      style: TextStyle(
                                                        color: Color(0xFF27AE60),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                textDirection: TextDirection.rtl,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontFamily: 'Jameel Noori',
                                                  fontSize: 27,
                                                  height: 1.45,
                                                ),
                                              ),

                                              const SizedBox(height: 18),
                                              const Divider(color: Colors.black12, height: 1),
                                              const SizedBox(height: 18),

                                              // Word-by-word blocks
                                              SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    _WordBlock(arabic: 'الْعَالَمِين', translation: 'of the worlds'),
                                                    _WordBlock(arabic: 'رَبِّ', translation: 'Lord'),
                                                    _WordBlock(arabic: 'لِلَّهِ', translation: 'be to Allah'),
                                                    _WordBlock(arabic: 'الْحَمْدُ', translation: 'All praise'),
                                                  ].reversed.toList(),
                                                ),
                                              ),

                                              const SizedBox(height: 18),

                                              // Tajweed Legend
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  _LegendItem(color: const Color(0xFF27AE60), label: 'Madd (Green)'),
                                                  const SizedBox(width: 14),
                                                  _LegendItem(color: const Color(0xFFF39C12), label: 'Glow (Orange)'),
                                                  const SizedBox(width: 14),
                                                  _LegendItem(color: const Color(0xFFC0392B), label: 'Echo (Red)'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Description text + feature badges
                              SlideTransition(
                                position: _slideText,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Perfect your recitation and understand every word. Access authentic sources, Tajweed color guidelines, and word-by-word translations.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                          color: _steelBlue,
                                          height: 1.65,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _FeatureBadge(icon: Icons.color_lens_rounded, label: 'Tajweed Rules'),
                                          _FeatureBadge(icon: Icons.translate_rounded, label: 'Word-by-Word'),
                                          _FeatureBadge(icon: Icons.mic_rounded, label: 'Recitations'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Page Dots
                    FadeTransition(
                      opacity: _fadeIn,
                      child: const _PageDots(total: 4, active: 1),
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

// ──────────────────────────────────────────────────────────────
// Page 2 Helper Widgets
// ──────────────────────────────────────────────────────────────
class _AudioWaveform extends StatelessWidget {
  final Animation<double> animation;
  const _AudioWaveform({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final val = animation.value;
        return Row(
          children: List.generate(4, (i) {
            final h = 4.0 + 10.0 * ((math.sin(val * math.pi * 2 + i * 1.5) + 1.0) / 2.0);
            return Container(
              width: 2.2,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              decoration: BoxDecoration(
                color: _deepBlue,
                borderRadius: BorderRadius.circular(1.0),
              ),
            );
          }),
        );
      },
    );
  }
}

class _WordBlock extends StatelessWidget {
  final String arabic;
  final String translation;
  const _WordBlock({required this.arabic, required this.translation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabic,
            style: const TextStyle(
              fontFamily: 'Jameel Noori',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            translation,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: _steelBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: _steelBlue,
          ),
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            color: _deepBlue,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
        ),
      ],
    );
  }
}
