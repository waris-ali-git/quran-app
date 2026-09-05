import 'package:flutter/material.dart';
import '../../../../core/widgets/translated_text.dart';
import '../../widgets/worship_sliver_header.dart';

class HajjScreen extends StatefulWidget {
  const HajjScreen({super.key});

  @override
  State<HajjScreen> createState() => _HajjScreenState();
}

class _HajjScreenState extends State<HajjScreen> {
  // Light warm sand/peach theme (matching Namaz light gradient pattern)
  final Color _deepColor = const Color(0xFFBF8860); // warm camel
  final Color _lightColor = const Color(0xFFFFDCC0); // soft peach

  final Map<String, bool> _checklist = {
    "Passport & Visa": false,
    "Ihram Towels (x2)": false,
    "Comfortable Slippers": false,
    "Basic First Aid & Medicines": false,
    "Prayer Mat": false,
    "Umbrella / Sun Glasses": false,
    "Power Bank": false,
    "Fragrance-Free Soap/Lotion": false,
    "Small Backpack for Mina": false,
    "Nail Clipper & Scissors": false,
  };

  final List<Map<String, String>> _guideSteps = [
    {
      "title": "1. Preparation & Ihram",
      "desc":
          "Perform Ghusl, wear the Ihram, and make the intention for Hajj before crossing the Miqat. Start reciting the Talbiyah."
    },
    {
      "title": "2. Tawaf al-Qudum",
      "desc":
          "Upon reaching Masjid al-Haram, perform 7 circuits of the Kaaba starting from the Black Stone."
    },
    {
      "title": "3. Sa'i",
      "desc":
          "Walk 7 times between the hills of Safa and Marwa. Afterwards, remain in the state of Ihram if performing Hajj al-Ifrad or Qiran."
    },
    {
      "title": "4. 8th Dhul Hijjah - Mina",
      "desc":
          "Proceed to Mina before Dhuhr. Stay there until the next morning, praying all 5 prayers (Dhuhr, Asr, Maghrib, Isha, Fajr)."
    },
    {
      "title": "5. 9th Dhul Hijjah - Arafat",
      "desc":
          "The pinnacle of Hajj. Proceed to Arafat and spend the day in intense Dua and repentance until sunset."
    },
    {
      "title": "6. Night of 9th - Muzdalifah",
      "desc":
          "Leave Arafat after sunset without praying Maghrib. Pray Maghrib and Isha combined at Muzdalifah, sleep, and collect pebbles."
    },
    {
      "title": "7. 10th Dhul Hijjah - Rami & Sacrifice",
      "desc":
          "Return to Mina to throw 7 pebbles at Jamarat al-Aqabah. Then perform the sacrifice, followed by shaving/cutting hair to begin leaving Ihram."
    },
    {
      "title": "8. Tawaf al-Ifadah",
      "desc":
          "Return to Makkah to perform Tawaf al-Ifadah and Sa'i (if required). You are now completely out of Ihram restrictions."
    },
    {
      "title": "9. 11th-13th - Days of Tashreeq",
      "desc":
          "Stay in Mina and pelt all three Jamarat each afternoon. Perform the Farewell Tawaf (Wada) before leaving Makkah."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FBFE), // Ice White
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              WorshipSliverHeader(
                title: 'Hajj',
                subtitle: 'Pilgrimage to Makkah',
                arabicTitle: 'حَجّ',
                icon: Icons.location_on,
                deepColor: _deepColor,
                lightColor: _lightColor,
                badgeText: 'Pillar #5',
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _HajjSliverAppBarDelegate(
                  TabBar(
                    labelColor: _deepColor,
                    unselectedLabelColor: Colors.grey[500],
                    indicatorColor: _deepColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(icon: Icon(Icons.map), text: "Guide"),
                      Tab(icon: Icon(Icons.menu_book), text: "Duas"),
                      Tab(icon: Icon(Icons.checklist), text: "Checklist"),
                    ],
                  ),
                  _lightColor,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildGuideTab(),
              _buildDuasTab(),
              _buildChecklistTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guideSteps.length,
      itemBuilder: (context, index) {
        final step = _guideSteps[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8F2), Color(0xFFFFEDD8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _deepColor.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_lightColor, _deepColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: TranslatedText(step["title"]!,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _deepColor,
                    fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TranslatedText(step["desc"]!,
                  style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF4A3020))),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDuaCard(
            "The Talbiyah",
            "لَبَّيْكَ اللّٰهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ",
            "Labbayk, Allahumma Labbayk, Labbayka la sharika laka Labbayk, Innal hamda wanni'mata laka walmulk, La sharika lak",
            "Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Verily all praise and blessings are Yours, and all sovereignty, You have no partner."),
        const SizedBox(height: 16),
        _buildDuaCard(
            "At Safa & Marwa",
            "إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَآئِرِ اللّٰهِ",
            "Innas-Safa wal-Marwata min sha'aa'irillaah",
            "Indeed, Safa and Marwa are from the signs of Allah."),
        const SizedBox(height: 16),
        _buildDuaCard(
            "Dua on the Day of Arafat",
            "لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
            "La ilaha illallahu wahdahu la sharika lahu, lahul mulk wa lahul hamdu, wa huwa 'ala kulli shay'in qadeer",
            "There is no deity but Allah alone, without partner. To Him belongs the dominion, and to Him belongs all praise, and He has power over all things."),
      ],
    );
  }

  Widget _buildDuaCard(
      String title, String arabic, String transliteration, String translation) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8F2), Color(0xFFFFEDD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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
                  color: Color(0xFF2A1A0A)),
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
                  fontSize: 15, height: 1.4, color: Color(0xFF4A3020)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checklist.keys.length,
      itemBuilder: (context, index) {
        String key = _checklist.keys.elementAt(index);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _checklist[key]!
                  ? [const Color(0xFFF0F0F0), const Color(0xFFE8E8E8)]
                  : [const Color(0xFFFFF8F2), const Color(0xFFFFEDD8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _deepColor.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CheckboxListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: TranslatedText(
              key,
              style: TextStyle(
                decoration:
                    _checklist[key]! ? TextDecoration.lineThrough : null,
                color: _checklist[key]! ? Colors.grey : _deepColor,
                fontWeight:
                    _checklist[key]! ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            value: _checklist[key],
            activeColor: _deepColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onChanged: (bool? value) {
              setState(() {
                _checklist[key] = value ?? false;
              });
            },
          ),
        );
      },
    );
  }
}

class _HajjSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _HajjSliverAppBarDelegate(this._tabBar, this._lightColor);

  final TabBar _tabBar;
  final Color _lightColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF4FBFE), _lightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_HajjSliverAppBarDelegate oldDelegate) {
    return false;
  }
}
