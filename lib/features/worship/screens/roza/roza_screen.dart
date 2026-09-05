import 'package:flutter/material.dart';
import '../../../../core/widgets/translated_text.dart';
import '../../widgets/worship_sliver_header.dart';
import '../../services/prayer_timing_service.dart';
import '../../models/prayer_timing.dart';

class RozaScreen extends StatefulWidget {
  const RozaScreen({super.key});

  @override
  State<RozaScreen> createState() => _RozaScreenState();
}

class _RozaScreenState extends State<RozaScreen> {
  final PrayerTimingService _timingService = PrayerTimingService();
  late Future<PrayerTiming?> _timingsFuture;

  // Light lavender theme (matching Namaz light gradient pattern)
  final Color _deepColor = const Color(0xFF9C6FD6); // soft lavender-purple
  final Color _lightColor = const Color(0xFFD8B8F5); // light lilac

  @override
  void initState() {
    super.initState();
    _timingsFuture = _timingService.getTodayTimings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFE), // Ice White
      body: FutureBuilder<PrayerTiming?>(
        future: _timingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final timings = snapshot.data;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              WorshipSliverHeader(
                title: 'Roza',
                subtitle: 'Fasting in Ramadan',
                arabicTitle: 'صَوْم',
                icon: Icons.brightness_3,
                deepColor: _deepColor,
                lightColor: _lightColor,
                badgeText: 'Pillar #3',
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (timings != null)
                        _buildTimingCard(timings)
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _deepColor.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const TranslatedText(
                            "Unable to fetch timings. Please check location permissions and internet connection.",
                            style: TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildDuaCard(
                          "Sehri Dua (Intention to Fast)",
                          "وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَانَ",
                          "Wa bisawmi ghadinn nawaiytu min shahri ramadan",
                          "I intend to keep the fast for tomorrow in the month of Ramadan"),
                      const SizedBox(height: 16),
                      _buildDuaCard(
                          "Iftar Dua (Breaking the Fast)",
                          "اَللّٰهُمَّ اِنّيْ لَكَ صُمْتُ وَبِكَ اٰمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلٰيْ رِزْقِكَ اَفْطَرْتُ",
                          "Allahumma inni laka sumtu wa bika aamantu wa 'alayka tawakkaltu wa 'ala rizqika aftartu",
                          "O Allah! I fasted for You and I believe in You and I put my trust in You and I break my fast with Your sustenance"),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimingCard(PrayerTiming timings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE0FF), Color(0xFFD8C0F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _deepColor.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText("Sehri Ends (Fajr)",
                      style: TextStyle(
                          color: _deepColor.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(timings.fajr.replaceAll(' (PKT)', ''),
                      style: TextStyle(
                          color: _deepColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wb_twilight,
                    color: _deepColor, size: 32),
              ),
            ],
          ),
          Divider(color: _deepColor.withValues(alpha: 0.2), height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText("Iftar Time (Maghrib)",
                      style: TextStyle(
                          color: _deepColor.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(timings.maghrib.replaceAll(' (PKT)', ''),
                      style: TextStyle(
                          color: _deepColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.nights_stay, color: _deepColor, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDuaCard(String title, String arabic, String transliteration,
      String translation) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5EEFF), Color(0xFFECDCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _deepColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TranslatedText(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _deepColor)),
            const SizedBox(height: 16),
            Text(
              arabic,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontFamily: 'DigitalKhatt',
                  fontSize: 30,
                  height: 1.8,
                  color: Color(0xFF2D1B69)),
              textDirection: TextDirection.rtl,
            ),
            Divider(height: 32, color: _deepColor.withValues(alpha: 0.2)),
            Text(
              transliteration,
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              translation,
              style: const TextStyle(
                  fontSize: 15, height: 1.4, color: Color(0xFF2D1B69)),
            ),
          ],
        ),
      ),
    );
  }
}
