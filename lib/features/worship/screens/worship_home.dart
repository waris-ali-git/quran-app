import 'package:flutter/material.dart';
import '../../../core/widgets/translated_text.dart';
import '../../../core/widgets/language_selector_button.dart';
import 'kalma/kalma_screen.dart';
import 'namaz/namaz_screen.dart';
import 'roza/roza_screen.dart';
import 'zakat/zakat_screen.dart';
import 'hajj/hajj_screen.dart';
import '../../../core/constants.dart';

class WorshipHomeScreen extends StatelessWidget {
  const WorshipHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> pillars = [
      {
        'title': 'Kalma',
        'subtitle': 'The Declaration of Faith',
        'image': 'lib/assets/images/worship/kalma.png',
        'color': const Color(0xFF90BDE7), // Carolina Blue
        'screen': const KalmaScreen(),
      },
      {
        'title': 'Namaz',
        'subtitle': 'The Five Daily Prayers',
        'image': 'lib/assets/images/worship/namaz.png',
        'color': const Color(0xFFD9F1FD), // Powder Blue
        'screen': const NamazScreen(),
      },
      {
        'title': 'Roza',
        'subtitle': 'Fasting in Ramadan',
        'image': 'lib/assets/images/worship/roza.png',
        'color': const Color(0xFFA6C7F2), // Baby Blue
        'screen': const RozaScreen(),
      },
      {
        'title': 'Zakat',
        'subtitle': 'Obligatory Charity',
        'image': 'lib/assets/images/worship/zakat.png',
        'color': const Color(0xFFDBE9FA), // Whisper Blue
        'screen': const ZakatScreen(),
      },
      {
        'title': 'Hajj',
        'subtitle': 'Pilgrimage to Makkah',
        'image': 'lib/assets/images/worship/hajj.png',
        'color': const Color(0xFF6B8FB5), // Steel Blue
        'screen': const HajjScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: TasbeehColors.iceWhite, // Ice White
      appBar: AppBar(
        backgroundColor: TasbeehColors.iceWhite,
        elevation: 0,
        title: const TranslatedText('5 Pillars of Islam', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
        centerTitle: true,
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: TranslatedText(
                'Explore the foundational acts of worship in Islam.',
                style: TextStyle(fontSize: 16, color: Color(0xFF4A6B8A)),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: pillars.length,
              itemBuilder: (context, index) {
                final pillar = pillars[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => pillar['screen'] as Widget),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                        image: AssetImage(pillar['image'] as String),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
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
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            pillar['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TranslatedText(
                            pillar['subtitle'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
