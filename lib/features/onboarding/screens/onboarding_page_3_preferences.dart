part of 'onboarding_screen.dart';

// ──────────────────────────────────────────────────────────────
// Page 3: Language Preference Screen
// ──────────────────────────────────────────────────────────────
class _OnboardingPreferencesPage extends StatefulWidget {
  final VoidCallback onNext;
  const _OnboardingPreferencesPage({required this.onNext});

  @override
  State<_OnboardingPreferencesPage> createState() => _OnboardingPreferencesPageState();
}

class _OnboardingPreferencesPageState extends State<_OnboardingPreferencesPage>
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

  late final Animation<double> _twinkleAnim;

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
        vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    _fadeIn = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));

    _slideHeader  = _slide(_entranceCtrl, 0.00, 0.55, 0.25);
    _slideContent = _slide(_entranceCtrl, 0.15, 0.75, 0.35);
    _slideBtn     = _slideUp(_entranceCtrl, 0.50, 1.00, 0.50);

    _twinkleAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _twinkleCtrl, curve: Curves.easeInOut));

    final rng = math.Random(99);
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
    _dustCtrl.dispose();
    _twinkleCtrl.dispose();
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showFloatingLanguageCard(BuildContext context, String currentLangCode) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Language Selector',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _OnboardingLanguagePopup(currentLangCode: currentLangCode),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildWorshipCardsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: const [
          _WorshipPreviewCard(
            title: 'Salah Tracker',
            subtitle: 'Prayer times & logs.',
            icon: Icons.access_time_filled_rounded,
            color: Color(0xFF3487D1),
          ),
          _WorshipPreviewCard(
            title: 'Dhikr Tasbeeh',
            subtitle: 'Digital counter & goals.',
            icon: Icons.radio_button_checked_rounded,
            color: Color(0xFF27AE60),
          ),
          _WorshipPreviewCard(
            title: 'Fasting Roza',
            subtitle: 'Suhur & Iftar schedules.',
            icon: Icons.nights_stay_rounded,
            color: Color(0xFF8E44AD),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentLang = context.watch<LanguageCubit>().state;

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
                bottom: -size.width * 0.2,
                right: -size.width * 0.2,
                child: Opacity(
                  opacity: 0.03,
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

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Header title
                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideHeader,
                        child: Column(
                          children: [
                            TranslatedText(
                              'Explore & Personalize',
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

                    // Scrollable content area
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideContent,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Choose Language Section
                                Row(
                                  children: [
                                    const Icon(Icons.translate_rounded, color: _deepBlue, size: 16),
                                    const SizedBox(width: 8),
                                    TranslatedText(
                                      'App Language',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _navy,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Glowing LiquidGlass language button
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Pulsing halo ring 1
                                      AnimatedBuilder(
                                        animation: _pulseCtrl,
                                        builder: (_, __) {
                                          final scale = 1.0 + _pulseCtrl.value * 0.45;
                                          final opacity = 0.35 - _pulseCtrl.value * 0.35;
                                          return Transform.scale(
                                            scale: scale,
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _deepBlue.withValues(alpha: opacity),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Pulsing halo ring 2
                                      AnimatedBuilder(
                                        animation: _pulseCtrl,
                                        builder: (_, __) {
                                          final scale = 1.0 + _pulseCtrl.value * 0.22;
                                          final opacity = 0.5 - _pulseCtrl.value * 0.5;
                                          return Transform.scale(
                                            scale: scale,
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _carolina.withValues(alpha: opacity),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // LiquidGlass language button
                                      GestureDetector(
                                        onTap: () => _showFloatingLanguageCard(context, currentLang),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: LiquidGlassContainer(
                                            width: 80,
                                            height: 80,
                                            borderRadius: 22,
                                            child: const Icon(
                                              Icons.language,
                                              color: Color(0xFF1C1C1E),
                                              size: 38,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 35),

                                // 3. Worship Tracker Preview Section
                                TranslatedText(
                                  'Daily Worship Companion',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _navy,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildWorshipCardsRow(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Page Dots
                    FadeTransition(
                      opacity: _fadeIn,
                      child: const _PageDots(total: 4, active: 2),
                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 24),
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
// Onboarding Glassmorphic Language Selector Popup
// ──────────────────────────────────────────────────────────────
class _OnboardingLanguagePopup extends StatefulWidget {
  final String currentLangCode;
  const _OnboardingLanguagePopup({required this.currentLangCode});

  @override
  State<_OnboardingLanguagePopup> createState() => _OnboardingLanguagePopupState();
}

class _OnboardingLanguagePopupState extends State<_OnboardingLanguagePopup> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = supportedLanguages.entries.where((entry) {
      return entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return LiquidGlassContainer(
      width: 280,
      height: 450,
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Select Language',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF1C1C1E)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Language List
          Expanded(
            child: filteredLanguages.isEmpty
                ? const Center(child: Text('No results', style: TextStyle(color: Color(0xFF1C1C1E))))
                : ListView.builder(
                    itemCount: filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final entry = filteredLanguages[index];
                      final isSelected = entry.value == widget.currentLangCode;

                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blueAccent : const Color(0xFF1C1C1E),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, size: 18, color: Colors.blueAccent)
                            : null,
                        onTap: () {
                          context.read<LanguageCubit>().setLanguage(entry.value);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Worship Preview Card Widget
// ──────────────────────────────────────────────────────────────
class _WorshipPreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _WorshipPreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 72) / 3;
    final finalWidth = cardWidth.clamp(100.0, 220.0);
    final finalHeight = (finalWidth * 0.9).clamp(115.0, 160.0);

    return Container(
      width: finalWidth,
      height: finalHeight,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              TranslatedText(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _steelBlue,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
