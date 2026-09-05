import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/word_analysis.dart';

const _gDeep = Color(0xFF7B8FF5);
const _gPink = Color(0xFFF5C2E0);
const _gDark = Color(0xFF2D2060);
const _gMuted = Color(0xFF9B8EBB);
const _gBg = Color(0xFFFDF5FB);

// I'rab color map
const Map<String, Color> _irabColors = {
  "Raf'": Color(0xFF5468E8),   // Blue — nominative
  "Nasb": Color(0xFFD45A9F),   // Pink — accusative
  "Jarr": Color(0xFF2DAA7A),   // Green — genitive
  "Jazm": Color(0xFFD4872A),   // Amber — jussive
};

const Map<String, Color> _irabBgColors = {
  "Raf'": Color(0xFFEEF0FF),
  "Nasb": Color(0xFFFCE8F3),
  "Jarr": Color(0xFFE8FFF4),
  "Jazm": Color(0xFFFFF3E8),
};

class WordAnalysisScreen extends StatefulWidget {
  const WordAnalysisScreen({super.key});

  @override
  State<WordAnalysisScreen> createState() => _WordAnalysisScreenState();
}

class _WordAnalysisScreenState extends State<WordAnalysisScreen> {
  List<SurahAnalysis> _surahs = [];
  int _selectedSurahIdx = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String response = await rootBundle
        .loadString('lib/assets/data/grammar/word_analysis.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _surahs = data
          .map((s) => SurahAnalysis.fromJson(s as Map<String, dynamic>))
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
          'Word-by-Word Analysis',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: _gDark,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSurahPicker(),
                _buildLegend(),
                Expanded(child: _buildAyahList()),
              ],
            ),
    );
  }

  Widget _buildSurahPicker() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF0FF), Color(0xFFFCE8F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _gDeep.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSurahIdx,
          isExpanded: true,
          dropdownColor: const Color(0xFFF8F0FF),
          style: GoogleFonts.montserrat(
            color: _gDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          items: List.generate(
            _surahs.length,
            (i) => DropdownMenuItem(
              value: i,
              child: Text(
                  'Surah ${_surahs[i].surah} — ${_surahs[i].surahName}'),
            ),
          ),
          onChanged: (val) {
            if (val != null) setState(() => _selectedSurahIdx = val);
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _irabColors.entries.map((e) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: e.value,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                e.key,
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: _gMuted, fontWeight: FontWeight.w600),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAyahList() {
    final surah = _surahs[_selectedSurahIdx];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: surah.ayahs.length,
      itemBuilder: (context, i) =>
          _buildAyahCard(context, surah.ayahs[i], i + 1),
    );
  }

  Widget _buildAyahCard(
      BuildContext context, AyahAnalysis ayah, int displayNum) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0EEFF), Color(0xFFFCEBF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _gDeep.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayah number badge + full arabic
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_gDeep, _gPink],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$displayNum',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ayah.arabicFull,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      color: _gDark,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Word chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: ayah.words.reversed.map((word) {
                return GestureDetector(
                  onTap: () => _showWordDetail(context, word),
                  child: _buildWordChip(word),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordChip(WordEntry word) {
    final color = _irabColors[word.irab] ?? _gMuted;
    final bgColor = _irabBgColors[word.irab] ?? const Color(0xFFF4F4F4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            word.arabic,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 18,
              color: _gDark,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              word.irab,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showWordDetail(BuildContext context, WordEntry word) {
    final color = _irabColors[word.irab] ?? _gMuted;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDF5FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              word.arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(fontSize: 40, color: _gDark, height: 1.5),
            ),
            const SizedBox(height: 4),
            Text(
              '${word.transliteration}  —  ${word.meaning}',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: _gMuted,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Root', word.root, Icons.account_tree_rounded),
            _detailRow('Type', word.type, Icons.label_rounded),
            _detailRow('I\'rab', word.irab, Icons.assignment_turned_in_rounded,
                valueColor: color),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF0FF), Color(0xFFFCE8F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grammar Note',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _gDeep,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(word.grammarNote,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: _gDark, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _gDeep),
          const SizedBox(width: 8),
          Text(
            '$label:  ',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: _gMuted, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: valueColor ?? _gDark,
                fontWeight: FontWeight.w700,
              ),
              textDirection: value.contains(RegExp(r'[\u0600-\u06FF]'))
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}
