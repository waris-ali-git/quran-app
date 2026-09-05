import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/state/language_cubit.dart';
import '../../../../core/widgets/translated_text.dart';
import '../../models/daily_hadith.dart';
import 'animated_gradient_reveal_text.dart';

class DailyHadithDialog extends StatefulWidget {
  final DailyHadith hadith;

  const DailyHadithDialog({super.key, required this.hadith});

  static Future<void> show(BuildContext context, DailyHadith hadith) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DailyHadithDialog(hadith: hadith),
    );
  }

  @override
  State<DailyHadithDialog> createState() => _DailyHadithDialogState();
}

class _DailyHadithDialogState extends State<DailyHadithDialog> {
  int _animationKeySeed = 0;

  void _replayAnimation() {
    setState(() {
      _animationKeySeed++;
    });
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final String currentLang = context.read<LanguageCubit>().state;
    String translationText;

    if (currentLang == 'ur') {
      translationText = widget.hadith.urdu.isNotEmpty
          ? widget.hadith.urdu
          : widget.hadith.english;
    } else if (currentLang == 'en') {
      translationText = widget.hadith.english.isNotEmpty
          ? widget.hadith.english
          : widget.hadith.urdu;
    } else {
      final source = widget.hadith.english.isNotEmpty
          ? widget.hadith.english
          : widget.hadith.urdu;
      translationText = await sl<TranslationService>()
          .translate(text: source, targetLang: currentLang);
    }

    final String text = '''
حديث مباركة | Daily Hadith

${widget.hadith.arabic}

Translation:
$translationText

${widget.hadith.book} (${widget.hadith.hadithNumber})
Narrator: ${widget.hadith.narrator}
Grade: ${widget.hadith.grade}
''';

    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              TranslatedText('Hadith copied to clipboard',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          backgroundColor: const Color(0xFF3487D1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareHadith(BuildContext context) async {
    final String currentLang = context.read<LanguageCubit>().state;
    String translationText;

    if (currentLang == 'ur') {
      translationText = widget.hadith.urdu.isNotEmpty
          ? widget.hadith.urdu
          : widget.hadith.english;
    } else if (currentLang == 'en') {
      translationText = widget.hadith.english.isNotEmpty
          ? widget.hadith.english
          : widget.hadith.urdu;
    } else {
      final source = widget.hadith.english.isNotEmpty
          ? widget.hadith.english
          : widget.hadith.urdu;
      translationText = await sl<TranslationService>()
          .translate(text: source, targetLang: currentLang);
    }

    final String text = '''
حديث مباركة | Daily Hadith

${widget.hadith.arabic}

Translation:
$translationText

${widget.hadith.book} (${widget.hadith.hadithNumber}) - ${widget.hadith.grade}
''';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFAFDFF),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Gradient Header Banner ──────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFD9F1FD),
                      Color(0xFF90BDE7),
                      Color(0xFFA6C7F2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'حَدِيث',
                              style: TextStyle(
                                fontFamily: 'Jameel Noori',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2E44),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'حَدِيثُ الْيَوْمِ',
                          style: GoogleFonts.amiri(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A2E44),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 2),
                        TranslatedText(
                          'Hadith of the Day',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D5F8A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // Replay Animation Button on Top Right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.replay_rounded,
                            color: Color(0xFF1A2E44), size: 22),
                        tooltip: 'Replay Reveal Animation',
                        onPressed: _replayAnimation,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content Area ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Book Name & Grade Pill Badges
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBE9FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${widget.hadith.book} (${widget.hadith.hadithNumber})',
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A2E44),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            widget.hadith.grade,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Arabic Hadith Box with Animated Gradient Reveal (RTL, Light Blue -> Light Pink -> Navy Black)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FD),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD9F1FD)),
                      ),
                      child: Column(
                        children: [
                          AnimatedGradientRevealText(
                            key: ValueKey(
                                'arabic_${widget.hadith.id}_$_animationKeySeed'),
                            text: widget.hadith.arabic,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            backgroundColor: const Color(0xFFF0F7FD),
                            duration: const Duration(milliseconds: 5000),
                            style: GoogleFonts.amiri(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              height: 1.8,
                              color: const Color(0xFF1A2E44),
                            ),
                          ),
                          if (widget.hadith.narrator.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            AnimatedGradientRevealText(
                              key: ValueKey(
                                  'narrator_${widget.hadith.id}_$_animationKeySeed'),
                              text: '― ${widget.hadith.narrator}',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              backgroundColor: const Color(0xFFF0F7FD),
                              duration: const Duration(milliseconds: 3000),
                              delay: const Duration(milliseconds: 2800),
                              style: GoogleFonts.amiri(
                                fontSize: 15,
                                color: const Color(0xFF4A6B8A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Translation Box with Animated Gradient Reveal based on selected global language
                    BlocBuilder<LanguageCubit, String>(
                      builder: (context, currentLang) {
                        final bool isRtl = currentLang == 'ur' || currentLang == 'ar';
                        final TextDirection direction =
                            isRtl ? TextDirection.rtl : TextDirection.ltr;

                        if (currentLang == 'ur') {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFDBE9FA)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AnimatedGradientRevealText(
                              key: ValueKey(
                                  'trans_ur_${widget.hadith.id}_$_animationKeySeed'),
                              text: widget.hadith.urdu.isNotEmpty
                                  ? widget.hadith.urdu
                                  : widget.hadith.english,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              backgroundColor: Colors.white,
                              duration: const Duration(milliseconds: 6500),
                              delay: const Duration(milliseconds: 3200),
                              style: const TextStyle(
                                fontFamily: 'Jameel Noori',
                                fontSize: 17,
                                height: 1.7,
                                color: Color(0xFF1A2E44),
                              ),
                            ),
                          );
                        } else if (currentLang == 'en') {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFDBE9FA)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AnimatedGradientRevealText(
                              key: ValueKey(
                                  'trans_en_${widget.hadith.id}_$_animationKeySeed'),
                              text: widget.hadith.english.isNotEmpty
                                  ? widget.hadith.english
                                  : widget.hadith.urdu,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              backgroundColor: Colors.white,
                              duration: const Duration(milliseconds: 4500),
                              delay: const Duration(milliseconds: 3200),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.5,
                                color: const Color(0xFF1A2E44),
                              ),
                            ),
                          );
                        } else {
                          // For any other global language (fr, es, tr, id, hi, ar, etc.)
                          final String sourceText = widget.hadith.english.isNotEmpty
                              ? widget.hadith.english
                              : widget.hadith.urdu;

                          return FutureBuilder<String>(
                            future: sl<TranslationService>().translate(
                              text: sourceText,
                              targetLang: currentLang,
                            ),
                            builder: (context, snapshot) {
                              final String translatedStr =
                                  snapshot.data ?? sourceText;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFDBE9FA)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: AnimatedGradientRevealText(
                                  key: ValueKey(
                                      'trans_${currentLang}_${widget.hadith.id}_${_animationKeySeed}_${translatedStr.hashCode}'),
                                  text: translatedStr,
                                  textAlign: TextAlign.center,
                                  textDirection: direction,
                                  backgroundColor: Colors.white,
                                  duration: const Duration(milliseconds: 4500),
                                  delay: const Duration(milliseconds: 3200),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: const Color(0xFF1A2E44),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // ── Action Buttons Row ────────────────────────────────────
                    Row(
                      children: [
                        // Copy Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(context),
                            icon: const Icon(Icons.copy_rounded,
                                size: 18, color: Color(0xFF2D5F8A)),
                            label: TranslatedText(
                              'Copy',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D5F8A),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFA6C7F2)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Share Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareHadith(context),
                            icon: const Icon(Icons.share_rounded,
                                size: 18, color: Color(0xFF2D5F8A)),
                            label: TranslatedText(
                              'Share',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D5F8A),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFA6C7F2)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Close / JazakAllah Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF90BDE7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: TranslatedText(
                              'JazakAllah',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
