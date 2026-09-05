import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/language_selector_button.dart';
import 'lessons/grammar_lessons_screen.dart';
import 'word_analysis/word_analysis_screen.dart';
import 'root_explorer/root_explorer_screen.dart';
import 'vocabulary/vocabulary_screen.dart';

// ── Grammar Color Palette (Light Pink & Blue) ─────────────────────────────────
const _gBg = Color(0xFFFDF5FB);           // very light pinkish white
const _gDeep = Color(0xFF7B8FF5);          // periwinkle blue
const _gDark = Color(0xFF2D2060);          // deep indigo text
const _gMuted = Color(0xFF9B8EBB);         // muted violet

class GrammarHomeScreen extends StatelessWidget {
  const GrammarHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildIntroCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Choose a Module'),
                const SizedBox(height: 16),
                _buildModuleGrid(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _gDeep,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: const [LanguageSelectorButton()],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B7FF0), Color(0xFFD9A8E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Fahm-ul-Quran',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'النَّحْوُ وَالصَّرْف',
                      style: GoogleFonts.amiri(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quranic Grammar',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF0FF), Color(0xFFFCE8F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gDeep.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: _gDeep, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Understand the Quran',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _gDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Learn Nahw (syntax) & Sarf (morphology) to unlock the beauty of Quranic Arabic.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _gMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _gDark,
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _GrammarModule(
        title: 'Grammar Lessons',
        subtitle: 'Nahw & Sarf',
        arabicText: 'النحو والصرف',
        icon: Icons.menu_book_rounded,
        imagePath: 'lib/assets/images/grammar/grammar lessons.png',
        gradient: const [Color(0xFFEEF0FF), Color(0xFFCBD0FF)],
        iconColor: const Color(0xFF5468E8),
        screen: const GrammarLessonsScreen(),
      ),
      _GrammarModule(
        title: 'Word-by-Word',
        subtitle: 'Verse Analysis',
        arabicText: 'إعراب',
        icon: Icons.translate_rounded,
        imagePath: 'lib/assets/images/grammar/word by word analysis.png',
        gradient: const [Color(0xFFFCE8F3), Color(0xFFF5C2E0)],
        iconColor: const Color(0xFFD45A9F),
        screen: const WordAnalysisScreen(),
      ),
      _GrammarModule(
        title: 'Root Explorer',
        subtitle: 'جذور الكلمات',
        arabicText: 'الجذر',
        icon: Icons.account_tree_rounded,
        imagePath: 'lib/assets/images/grammar/root analysis.png',
        gradient: const [Color(0xFFE8FFF4), Color(0xFFA8EDD0)],
        iconColor: const Color(0xFF2DAA7A),
        screen: const RootExplorerScreen(),
      ),
      _GrammarModule(
        title: 'Vocabulary',
        subtitle: 'Top Quran Words',
        arabicText: 'المفردات',
        icon: Icons.library_books_rounded,
        imagePath: 'lib/assets/images/grammar/vocabolary.png',
        gradient: const [Color(0xFFFFF3E8), Color(0xFFFFD8A8)],
        iconColor: const Color(0xFFD4872A),
        screen: const VocabularyScreen(),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: modules.map((m) => _buildModuleCard(context, m)).toList(),
    );
  }

  Widget _buildModuleCard(BuildContext context, _GrammarModule module) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => module.screen),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: AssetImage(module.imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.arabicText,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 2),
              Text(
                module.title,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                module.subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrammarModule {
  final String title;
  final String subtitle;
  final String arabicText;
  final IconData icon;
  final String imagePath;
  final List<Color> gradient;
  final Color iconColor;
  final Widget screen;

  _GrammarModule({
    required this.title,
    required this.subtitle,
    required this.arabicText,
    required this.icon,
    required this.imagePath,
    required this.gradient,
    required this.iconColor,
    required this.screen,
  });
}
