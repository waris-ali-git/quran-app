import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/grammar_lesson.dart';
import '../../../quran/services/preferences_service.dart';

// ─── Soft pastel gradient palette ───────────────────────────────────────
const _bgTop = Color(0xFFF3EEFB); // pale lilac
const _bgMid = Color(0xFFFBEFF6); // pale pink
const _bgBottom = Color(0xFFFFF6EE); // pale peach

const _primary = Color(0xFF9C8FD9); // pastel lavender
const _primaryDeep = Color(0xFF6E5A9E); // deeper lavender for text accents
const _pink = Color(0xFFF3B8CE); // pastel pink
const _peach = Color(0xFFFAD1B8); // pastel peach
const _mint = Color(0xFFB8E3D2); // pastel mint (success)
const _coral = Color(0xFFF3B0A8); // pastel coral (error, softer than red)

const _ink = Color(0xFF463F5B); // soft plum-black for headings
const _muted = Color(0xFF938BAC); // muted lavender-grey body text
const _hairline = Color(0xFFEADFF2);
const _surface = Color(0xFFFFFFFF);

const _nahwGrad = [Color(0xFFE9E1FB), Color(0xFFF6E6F5)]; // lilac -> orchid
const _sarfGrad = [Color(0xFFFCE8EF), Color(0xFFFCEEDD)]; // rose -> apricot

class GrammarLessonsScreen extends StatefulWidget {
  const GrammarLessonsScreen({super.key});

  @override
  State<GrammarLessonsScreen> createState() => _GrammarLessonsScreenState();
}

class _GrammarLessonsScreenState extends State<GrammarLessonsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<GrammarLesson> _nahwLessons = [];
  List<GrammarLesson> _sarfLessons = [];
  bool _isLoading = true;

  // Tracks which lesson ids have had a quiz answered correctly, purely
  // for a gentle in-session sense of progress (not persisted).
  final Set<int> _mastered = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadLessons();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    final String response = await rootBundle
        .loadString('lib/assets/data/grammar/grammar_lessons.json');
    final List<dynamic> data = json.decode(response);
    final lessons =
    data.map((j) => GrammarLesson.fromJson(j as Map<String, dynamic>)).toList();
    final savedMastered = PreferencesService().getMasteredGrammarLessons();
    setState(() {
      _nahwLessons = lessons.where((l) => l.category == 'Nahw').toList();
      _sarfLessons = lessons.where((l) => l.category == 'Sarf').toList();
      _mastered.addAll(savedMastered);
      _isLoading = false;
    });
  }

  void _onMastered(int id) {
    if (_mastered.add(id)) {
      PreferencesService().saveMasteredGrammarLessons(_mastered);
      setState(() {});
    }
  }

  Future<void> _resetProgress() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Progress?',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700, fontSize: 16, color: _ink),
        ),
        content: Text(
          'Are you sure you want to reset all lesson progress and solved MCQs back to 0%?',
          style: GoogleFonts.montserrat(fontSize: 13, color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(
                    color: _muted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _coral,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PreferencesService().clearMasteredGrammarLessons();
      setState(() {
        _mastered.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgMid, _bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: _primary,
                    strokeWidth: 2.4,
                  ),
                )
                    : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildLessonList(_nahwLessons, _nahwGrad),
                    _buildLessonList(_sarfLessons, _sarfGrad),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final total = _nahwLessons.length + _sarfLessons.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF6EFFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _hairline, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: _ink),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_primaryDeep, Color(0xFFC97BA0)],
                  ).createShader(bounds),
                  child: Text(
                    'Grammar Lessons',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 19,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (!_isLoading)
                  Text(
                    total == 0
                        ? 'Loading your lessons…'
                        : '${_mastered.length} of $total mastered',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (!_isLoading)
            Row(
              children: [
                _ProgressRing(
                  progress: total == 0 ? 0 : _mastered.length / total,
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Reset Progress',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _resetProgress,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _hairline, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: _primaryDeep,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFAF3FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hairline, width: 1),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabCtrl,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [_primary, _pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: _muted,
          labelStyle:
          GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
          GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(height: 42, text: 'Nahw · Syntax'),
            Tab(height: 42, text: 'Sarf · Morphology'),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonList(List<GrammarLesson> lessons, List<Color> cardGrad) {
    if (lessons.isEmpty) {
      return Center(
        child: Text('No lessons yet',
            style: GoogleFonts.montserrat(color: _muted, fontSize: 13)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return _LessonCard(
          lesson: lesson,
          index: index,
          cardGrad: cardGrad,
          mastered: _mastered.contains(lesson.id),
          onMastered: () => _onMastered(lesson.id),
        );
      },
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  const _ProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_pink, _peach],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(color: _surface, shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  backgroundColor: _hairline,
                  strokeWidth: 3.2,
                  valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _primaryDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatefulWidget {
  final GrammarLesson lesson;
  final int index;
  final List<Color> cardGrad;
  final bool mastered;
  final VoidCallback onMastered;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.cardGrad,
    required this.mastered,
    required this.onMastered,
  });

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  int? _selectedAnswer;
  bool _quizSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, widget.cardGrad[0].withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.cardGrad[1].withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 18, 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          iconColor: _primary,
          collapsedIconColor: _muted,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.mastered
                    ? [_mint, const Color(0xFF9FD6BC)]
                    : widget.cardGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.mastered ? _mint : widget.cardGrad[1])
                      .withValues(alpha: 0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: widget.mastered
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 18)
                  : Text(
                '${widget.index + 1}',
                style: GoogleFonts.montserrat(
                  color: _primaryDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          title: Text(
            lesson.title,
            style: GoogleFonts.montserrat(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              lesson.arabicTitle,
              style: GoogleFonts.amiri(fontSize: 17, color: _primaryDeep),
              textDirection: TextDirection.rtl,
            ),
          ),
          children: [
            _sectionDivider(),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.cardGrad[0].withValues(alpha: 0.55),
                    widget.cardGrad[1].withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                lesson.description,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  height: 1.7,
                  color: _ink.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Examples
            _sectionLabel('Examples', Icons.auto_awesome_rounded),
            const SizedBox(height: 8),
            ...lesson.examples.map((ex) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFCFAFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _hairline, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ex.arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 23,
                      color: _ink,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${ex.transliteration}  ·  ${ex.meaning}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: _muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )),

            // Quiz
            if (lesson.quiz != null) ...[
              const SizedBox(height: 8),
              _buildQuiz(lesson.quiz!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionDivider() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _hairline, Colors.transparent],
        ),
      ),
    ),
  );

  Widget _sectionLabel(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 14, color: _primary),
      const SizedBox(width: 6),
      Text(
        text.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _primaryDeep,
          letterSpacing: 0.8,
        ),
      ),
    ],
  );

  Widget _buildQuiz(GrammarQuiz quiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFE8FC), Color(0xFFFCE9F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: _primary, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Quiz',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: _primaryDeep,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quiz.question,
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              color: _ink,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(quiz.options.length, (i) {
            List<Color> optionGrad = [Colors.white, const Color(0xFFFCFAFF)];
            Color borderColor = _hairline;
            Color circleColor = _muted;
            if (_quizSubmitted) {
              if (i == quiz.answer) {
                optionGrad = [_mint.withValues(alpha: 0.35), _mint.withValues(alpha: 0.15)];
                borderColor = _mint;
                circleColor = const Color(0xFF5FA985);
              } else if (i == _selectedAnswer && i != quiz.answer) {
                optionGrad = [
                  _coral.withValues(alpha: 0.30),
                  _coral.withValues(alpha: 0.12)
                ];
                borderColor = _coral;
                circleColor = const Color(0xFFC96D62);
              }
            } else if (i == _selectedAnswer) {
              optionGrad = [_primary.withValues(alpha: 0.18), _pink.withValues(alpha: 0.14)];
              borderColor = _primary;
              circleColor = _primary;
            }
            return GestureDetector(
              onTap: _quizSubmitted
                  ? null
                  : () => setState(() => _selectedAnswer = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: optionGrad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: borderColor, width: 1.4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: circleColor, width: 1.6),
                        color: (i == _selectedAnswer && !_quizSubmitted)
                            ? _primary.withValues(alpha: 0.16)
                            : Colors.transparent,
                      ),
                      child: _quizSubmitted && i == quiz.answer
                          ? const Icon(Icons.check_rounded,
                          size: 14, color: Color(0xFF5FA985))
                          : _quizSubmitted &&
                          i == _selectedAnswer &&
                          i != quiz.answer
                          ? const Icon(Icons.close_rounded,
                          size: 14, color: Color(0xFFC96D62))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        quiz.options[i],
                        style: GoogleFonts.amiri(fontSize: 16, color: _ink),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (!_quizSubmitted && _selectedAnswer != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  setState(() => _quizSubmitted = true);
                  if (_selectedAnswer == quiz.answer) widget.onMastered();
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _pink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Check Answer',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_quizSubmitted) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _selectedAnswer == quiz.answer
                      ? [_mint.withValues(alpha: 0.35), _mint.withValues(alpha: 0.15)]
                      : [_coral.withValues(alpha: 0.30), _coral.withValues(alpha: 0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedAnswer == quiz.answer
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: _selectedAnswer == quiz.answer
                        ? const Color(0xFF5FA985)
                        : const Color(0xFFC96D62),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAnswer == quiz.answer
                          ? 'Excellent! Correct answer.'
                          : 'Correct answer: ${quiz.options[quiz.answer]}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        color: _selectedAnswer == quiz.answer
                            ? const Color(0xFF4C7C63)
                            : const Color(0xFFA85C52),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}