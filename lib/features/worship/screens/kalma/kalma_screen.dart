import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/translated_text.dart';
import '../../widgets/worship_sliver_header.dart';
import '../../models/kalma.dart';

class KalmaScreen extends StatefulWidget {
  const KalmaScreen({super.key});

  @override
  State<KalmaScreen> createState() => _KalmaScreenState();
}

class _KalmaScreenState extends State<KalmaScreen> {
  List<Kalma> _kalmas = [];
  bool _isLoading = true;

  // Light mint teal theme (light gradient, matching Namaz pattern)
  final Color _deepColor = const Color(0xFF2EAAA6); // soft teal
  final Color _lightColor = const Color(0xFFB2EBE0); // mint

  @override
  void initState() {
    super.initState();
    _loadKalmas();
  }

  Future<void> _loadKalmas() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/data/worship/kalmas.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _kalmas = data.map((json) => Kalma.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading Kalmas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFE), // Ice White
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                WorshipSliverHeader(
                  title: '6 Kalmas',
                  subtitle: 'The Declaration of Faith',
                  arabicTitle: 'الكَلِمَة',
                  icon: Icons.menu_book,
                  deepColor: _deepColor,
                  lightColor: _lightColor,
                  badgeText: 'Pillar #1',
                ),
                if (_kalmas.isEmpty)
                  const SliverFillRemaining(
                    child:
                        Center(child: TranslatedText('Failed to load data.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildKalmaCard(context, _kalmas[index], index),
                        childCount: _kalmas.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildKalmaCard(BuildContext context, Kalma kalma, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F8F6), Color(0xFFCFF5EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Count & Name
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_lightColor, _deepColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _deepColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      kalma.id.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TranslatedText(
                    kalma.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _deepColor,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 32, color: _deepColor.withValues(alpha: 0.15)),

            // Arabic Text
            Text(
              kalma.arabic,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DigitalKhatt',
                fontSize: 32,
                height: 1.8,
                color: Color(0xFF1A3A38),
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),

            // Transliteration Segment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: _deepColor.withValues(alpha: 0.18), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'Transliteration',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _deepColor,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TranslatedText(
                    kalma.transliteration,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF1A3A38).withValues(alpha: 0.75),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Translation Segment
            TranslatedText(
              kalma.translation,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF1A3A38),
              ),
            ),
            const SizedBox(height: 24),

            // Description / Virtues
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded,
                    size: 20, color: _deepColor.withValues(alpha: 0.8)),
                const SizedBox(width: 12),
                Expanded(
                  child: TranslatedText(
                    kalma.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D5050),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
