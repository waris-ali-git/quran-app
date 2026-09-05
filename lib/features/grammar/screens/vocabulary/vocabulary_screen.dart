import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/root_word.dart';

const _gDeep = Color(0xFF7B8FF5);
const _gPink = Color(0xFFF5C2E0);
const _gDark = Color(0xFF2D2060);
const _gMuted = Color(0xFF9B8EBB);
const _gBg = Color(0xFFFDF5FB);

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<VocabularyWord> _words = [];
  bool _isLoading = true;
  Set<int> _flippedCards = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String response = await rootBundle
        .loadString('lib/assets/data/grammar/vocabulary_list.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _words = data
          .map((w) => VocabularyWord.fromJson(w as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gBg,
      appBar: AppBar(
        backgroundColor: _gBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _gDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Vocabulary Builder',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: _gDark,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildWordGrid()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3E8), Color(0xFFFFD8A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4872A).withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded,
                color: Color(0xFFD4872A), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap a card to reveal the meaning. Tap again to flip back.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF5A3A00),
                  height: 1.4,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4872A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_words.length} Words',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _words.length,
      itemBuilder: (context, i) {
        return _FlashCard(
          word: _words[i],
          isFlipped: _flippedCards.contains(i),
          onTap: () {
            setState(() {
              if (_flippedCards.contains(i)) {
                _flippedCards.remove(i);
              } else {
                _flippedCards.add(i);
              }
            });
          },
        );
      },
    );
  }
}

class _FlashCard extends StatefulWidget {
  final VocabularyWord word;
  final bool isFlipped;
  final VoidCallback onTap;

  const _FlashCard({
    required this.word,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  State<_FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<_FlashCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(_FlashCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final angle = _anim.value * 3.14159;
          final isBack = angle > 1.5708;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: _buildBackFace(widget.word),
                  )
                : _buildFrontFace(widget.word),
          );
        },
      ),
    );
  }

  Widget _buildFrontFace(VocabularyWord word) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF0FF), Color(0xFFFCE8F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _gDeep.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _gDeep.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${word.rank}',
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: _gDeep,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              word.arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                  fontSize: 36, color: _gDark, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              word.transliteration,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: _gMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${word.frequency}× in Quran',
              style: GoogleFonts.montserrat(
                  fontSize: 10, color: _gMuted),
            ),
            const Spacer(),
            const Icon(Icons.touch_app_rounded, color: _gPink, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBackFace(VocabularyWord word) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCE8F3), Color(0xFFEEF0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _gPink.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              word.meaning,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _gDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _gDeep.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Root: ${word.root}',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                    fontSize: 14, color: _gDeep),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _gPink.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                word.partOfSpeech,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: const Color(0xFFD45A9F),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
