import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/translated_text.dart';
import '../../widgets/worship_sliver_header.dart';
import '../../services/prayer_timing_service.dart';
import '../../services/prayer_tracking_service.dart';
import '../../models/prayer_timing.dart';
import '../../models/prayer_tracking_record.dart';
import '../../models/namaz_step.dart';
import '../../models/rakat_info.dart';
import '../../../quran/models/ayah.dart'; // For ArabicStringExtension
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/constants.dart';

class NamazScreen extends StatelessWidget {
  const NamazScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Blue theme for Namaz
    final Color deepColor = const Color(0xFF90BDE7); // Carolina Blue
    final Color lightColor = const Color(0xFFD9F1FD); // Powder Blue

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: TasbeehColors.iceWhite, // Ice White
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              WorshipSliverHeader(
                title: 'Namaz',
                subtitle: 'The Five Daily Prayers',
                arabicTitle: 'صَلَاة',
                icon: Icons.pan_tool_alt_rounded,
                deepColor: deepColor,
                lightColor: lightColor,
                badgeText: 'Pillar #2',
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _NamazSliverAppBarDelegate(
                  TabBar(
                    isScrollable: false,
                    indicatorColor: deepColor,
                    labelColor: deepColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Timings', icon: Icon(Icons.access_time)),
                      Tab(text: 'Tariqa', icon: Icon(Icons.accessibility_new)),
                      Tab(text: 'Rakats', icon: Icon(Icons.format_list_numbered)),
                      Tab(text: 'Calendar', icon: Icon(Icons.calendar_month)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              _TimingsTab(),
              _TariqaTab(),
              _RakatsTab(),
              _CalendarTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamazSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _NamazSliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4FBFE), Color(0xFFD9F1FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_NamazSliverAppBarDelegate oldDelegate) {
    return false;
  }
}


// ─── TIMINGS TAB ─────────────────────────────────────────────────────────────
class _TimingsTab extends StatefulWidget {
  const _TimingsTab();

  @override
  State<_TimingsTab> createState() => _TimingsTabState();
}

class _TimingsTabState extends State<_TimingsTab> {
  PrayerTiming? _timing;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTimings();
  }

  Future<void> _fetchTimings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    final service = PrayerTimingService();
    // This will ask for location permission if not already granted.
    final data = await service.getTodayTimings();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data != null) {
          _timing = data;
        } else {
          _errorMessage = 'Could not fetch timings. Please ensure Location services are enabled.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              TranslatedText('Fetching precise timings for your location...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _timing == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              TranslatedText(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              LiquidGlassButton(
                label: 'Retry',
                icon: const Icon(Icons.refresh, size: 18),
                onTap: _fetchTimings,
              )
            ],
          ),
        ),
      );
    }

    final t = _timing!;
    final Color deepColor = const Color(0xFF90BDE7); // Carolina Blue
    final Color lightColor = const Color(0xFFD9F1FD); // Powder Blue

    return RefreshIndicator(
      onRefresh: _fetchTimings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hijri Date Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [deepColor, lightColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: deepColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${t.hijriDate} ${t.hijriMonth} ${t.hijriYear}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  t.gregorianDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const TranslatedText('Today\'s Prayers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTimingRow('Fajr', t.fajr, Icons.wb_twilight, deepColor),
          _buildTimingRow('Sunrise', t.sunrise, Icons.wb_sunny_outlined, deepColor),
          _buildTimingRow('Dhuhr', t.dhuhr, Icons.wb_sunny, deepColor),
          _buildTimingRow('Asr', t.asr, Icons.wb_cloudy, deepColor),
          _buildTimingRow('Maghrib', t.maghrib, Icons.nights_stay_outlined, deepColor),
          _buildTimingRow('Isha', t.isha, Icons.nights_stay, deepColor),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String name, String time, IconData icon, Color deepColor) {
    // Format the time slightly if needed, Aladhan API returns e.g. "05:14 (PKT)", we can strip the timezone if we want
    final cleanTime = time.replaceAll(RegExp(r'\ \([^)]*\)'), ''); // Removes " (PKT)"

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
            color: TasbeehColors.iceWhite, // Ice White
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: deepColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: deepColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: deepColor),
        ),
        title: TranslatedText(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: deepColor)),
        trailing: Text(
          cleanTime,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }
}

// ─── TARIQA TAB ─────────────────────────────────────────────────────────────
class _TariqaTab extends StatefulWidget {
  const _TariqaTab();

  @override
  State<_TariqaTab> createState() => _TariqaTabState();
}

class _TariqaTabState extends State<_TariqaTab> {
  List<NamazStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    final String response = await rootBundle.loadString('lib/assets/data/worship/namaz_steps.json');
    final data = await json.decode(response);
    setState(() {
      _steps = (data as List).map((i) => NamazStep.fromJson(i)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final step = _steps[index];
        final Color deepColor = TasbeehColors.blueDark;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: TasbeehColors.softGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: TasbeehColors.blueDark.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: deepColor.withValues(alpha: 0.1),
                      foregroundColor: deepColor,
                      child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TranslatedText(
                        step.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TranslatedText(
                  step.description,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                if (step.arabicDua != null) ...[
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: deepColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: deepColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          step.arabicDua!.cleanArabic,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'DigitalKhatt',
                            fontSize: 22,
                            height: 1.8,
                          ),
                        ),
                        if (step.duaTransliteration != null) ...[
                          const SizedBox(height: 12),
                          const TranslatedText('Transliteration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          Text(step.duaTransliteration!, style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                        if (step.duaTranslation != null) ...[
                          const SizedBox(height: 12),
                          const TranslatedText('Translation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          TranslatedText(step.duaTranslation!),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// CALENDAR TAB
class _CalendarTab extends StatefulWidget {
  const _CalendarTab();

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final PrayerTrackingService _trackingService = PrayerTrackingService();

  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  Map<String, PrayerTrackingRecord> _records = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _focusedMonth = DateTime(today.year, today.month);
    _selectedDate = today;
    _loadMonth(showLoader: false);
  }

  Future<void> _loadMonth({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    final records = await _trackingService.getRecordsForMonth(_focusedMonth);
    if (!mounted) return;

    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _changeMonth(int delta) async {
    final now = _dateOnly(DateTime.now());
    final nextMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + delta,
    );

    setState(() {
      _focusedMonth = nextMonth;
      _selectedDate = _isSameMonth(nextMonth, now)
          ? now
          : DateTime(nextMonth.year, nextMonth.month);
    });

    await _loadMonth();
  }

  PrayerTrackingRecord get _selectedRecord {
    final key = PrayerTrackingService.dateKey(_selectedDate);
    return _records[key] ?? PrayerTrackingRecord.empty(key);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadMonth(showLoader: false),
      color: TasbeehColors.blueDark,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildMonthHeader(),
          const SizedBox(height: 12),
          _buildWeekdayHeader(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          _buildSelectedDayPanel(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalPrayers = _records.values.fold<int>(
      0,
      (sum, record) => sum + record.completionCount,
    );
    final fullDays = _records.values.where((record) => record.isComplete).length;
    final bestDay = _records.values.fold<int>(
      0,
      (best, record) =>
          record.completionCount > best ? record.completionCount : best,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4FCFE), Color(0xFFDBE9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TasbeehColors.blueDark.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: TasbeehColors.blueDark.withValues(alpha: 0.12),
            blurRadius: 16,
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
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: TasbeehColors.blueDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Prayer Calendar',
                      style: TextStyle(
                        color: TasbeehColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your monthly namaz rhythm',
                      style: TextStyle(
                        color: TasbeehColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryPill(
                  Icons.done_all_rounded,
                  'Prayers',
                  '$totalPrayers',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryPill(
                  Icons.auto_awesome_rounded,
                  'Best Day',
                  '$bestDay/5',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryPill(
                  Icons.verified_rounded,
                  'Full Days',
                  '$fullDays',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: TasbeehColors.blueDark, size: 19),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TasbeehColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TasbeehColors.textLight,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: TasbeehColors.whisperBlue.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: TasbeehColors.blueDark,
          ),
          Expanded(
            child: Text(
              '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TasbeehColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: TasbeehColors.blueDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: [
        for (final label in _weekdayLabels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: TasbeehColors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
    ).weekday;
    final leadingEmptyCells = firstWeekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leadingEmptyCells + daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        if (index < leadingEmptyCells) {
          return const SizedBox.shrink();
        }

        final day = index - leadingEmptyCells + 1;
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        return _buildDayCell(date);
      },
    );
  }

  Widget _buildDayCell(DateTime date) {
    final key = PrayerTrackingService.dateKey(date);
    final record = _records[key] ?? PrayerTrackingRecord.empty(key);
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final count = record.completionCount;

    List<Color> gradient;
    Color textColor;

    if (isSelected) {
      gradient = const [Color(0xFFEAF4FB), Color(0xFFD9EAF7)];
      textColor = const Color(0xFF1A2E44);
    } else if (record.isComplete) {
      gradient = const [Color(0xFFEDFAF2), Color(0xFFE2F7EA)];
      textColor = const Color(0xFF2F8B62);
    } else if (count > 0) {
      gradient = const [Color(0xFFF7FAFC), Color(0xFFEDF2F7)];
      textColor = const Color(0xFF1A2E44);
    } else {
      gradient = const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)];
      textColor = const Color(0xFF6B8FB5).withValues(alpha: 0.8);
    }

    // Color definitions for specific prayers
    final colors = [
      const Color(0xFF32C5C5), // Fajr (Cyan)
      const Color(0xFF7B66FF), // Dhuhr (Lavender)
      const Color(0xFF38A86C), // Asr (Green)
      const Color(0xFFE86B9D), // Maghrib (Pink)
      const Color(0xFF2687F6), // Isha (Blue)
    ];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = _dateOnly(date);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF90BDE7)
                : isToday
                    ? const Color(0xFF3487D1).withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.9),
            width: isSelected || isToday ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected || count > 0)
              BoxShadow(
                color: const Color(0xFF90BDE7).withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: _MiniPrayerDonutPainter(
                completedList: PrayerTrackingRecord.prayerKeys
                    .map((k) => record.isCompleted(k))
                    .toList(),
                colors: colors,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayPanel() {
    final record = _selectedRecord;
    final isFriday = _selectedDate.weekday == DateTime.friday;

    // Color definitions for specific prayers
    final colors = [
      const Color(0xFF32C5C5), // Fajr (Cyan)
      isFriday ? const Color(0xFFFBD9AE) : const Color(0xFF7B66FF), // Jumma / Dhuhr
      const Color(0xFF38A86C), // Asr (Green)
      const Color(0xFFE86B9D), // Maghrib (Pink)
      const Color(0xFF2687F6), // Isha (Blue)
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TasbeehColors.blueDark.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDateLabel,
                      style: const TextStyle(
                        color: TasbeehColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.completionCount}/5 prayers completed',
                      style: const TextStyle(
                        color: TasbeehColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _SelectedDayDonutPainter(
                        completedList: PrayerTrackingRecord.prayerKeys
                            .map((k) => record.isCompleted(k))
                            .toList(),
                        colors: colors,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${record.completionCount}',
                        style: const TextStyle(
                          color: TasbeehColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < PrayerTrackingRecord.prayerKeys.length; i++)
                _buildPrayerStatusChip(
                  prayerKey: PrayerTrackingRecord.prayerKeys[i],
                  label: PrayerTrackingRecord.prayerKeys[i] == 'Dhuhr' && isFriday
                      ? 'Jumma'
                      : PrayerTrackingRecord.prayerKeys[i],
                  isCompleted: record.isCompleted(PrayerTrackingRecord.prayerKeys[i]),
                  prayerColor: colors[i],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerStatusChip({
    required String prayerKey,
    required String label,
    required bool isCompleted,
    required Color prayerColor,
  }) {
    final activeColor = isCompleted ? prayerColor : TasbeehColors.textLight;
    final bgGradient = isCompleted
        ? [prayerColor.withValues(alpha: 0.12), prayerColor.withValues(alpha: 0.24)]
        : const [Color(0xFFF6FCFF), Color(0xFFEAF4FB)];

    return Container(
      constraints: const BoxConstraints(minWidth: 124),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeColor.withValues(alpha: isCompleted ? 0.35 : 0.16),
          width: isCompleted ? 1.2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: activeColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCompleted
                  ? prayerColor.withValues(alpha: 0.9)
                  : TasbeehColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String get _selectedDateLabel {
    return '${_weekdayNames[_selectedDate.weekday - 1]}, '
        '${_monthNames[_selectedDate.month - 1]} '
        '${_selectedDate.day}, ${_selectedDate.year}';
  }

  bool _isSameMonth(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _MiniPrayerDonutPainter extends CustomPainter {
  final List<bool> completedList;
  final List<Color> colors;

  _MiniPrayerDonutPainter({
    required this.completedList,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 2.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const totalPrayers = 5;
    const double angleSegment = (2 * 3.141592653589793) / totalPrayers;
    const double gap = 0.12; // gap in radians

    for (int i = 0; i < totalPrayers; i++) {
      final isDone = completedList[i];
      paint.color = isDone ? colors[i] : const Color(0xFF6B8FB5).withValues(alpha: 0.12);

      final startAngle = -3.141592653589793 / 2 + i * angleSegment + gap / 2;
      final sweepAngle = angleSegment - gap;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPrayerDonutPainter oldDelegate) {
    return oldDelegate.completedList != completedList || oldDelegate.colors != colors;
  }
}

class _SelectedDayDonutPainter extends CustomPainter {
  final List<bool> completedList;
  final List<Color> colors;

  _SelectedDayDonutPainter({
    required this.completedList,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const totalPrayers = 5;
    const double angleSegment = (2 * 3.141592653589793) / totalPrayers;
    const double gap = 0.10;

    for (int i = 0; i < totalPrayers; i++) {
      final isDone = completedList[i];
      paint.color = isDone ? colors[i] : const Color(0xFF6B8FB5).withValues(alpha: 0.12);

      final startAngle = -3.141592653589793 / 2 + i * angleSegment + gap / 2;
      final sweepAngle = angleSegment - gap;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SelectedDayDonutPainter oldDelegate) {
    return oldDelegate.completedList != completedList || oldDelegate.colors != colors;
  }
}

// RAKATS TAB
class _RakatsTab extends StatelessWidget {
  const _RakatsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rakatData.length,
      itemBuilder: (context, index) {
        final r = rakatData[index];
        
        List<Color> bgGradient;
        Color textColor;
        
        switch (r.prayerName.toLowerCase()) {
          case 'fajr':
          case 'isha':
            bgGradient = const [Color(0xFFEAF9FA), Color(0xFFC4EFEF)]; // Soothing light cyan
            textColor = const Color(0xFF2EAAA6);
            break;
          case 'dhuhr':
          case "jumu'ah":
            bgGradient = const [Color(0xFFF1F1FC), Color(0xFFE0E2F5)]; // Soothing lavender
            textColor = const Color(0xFF7B66FF);
            break;
          case 'asr':
            bgGradient = const [Color(0xFFEAF7ED), Color(0xFFCDEFCE)]; // Soothing mint green
            textColor = const Color(0xFF38A86C);
            break;
          case 'maghrib':
            bgGradient = const [Color(0xFFFCECF3), Color(0xFFF4D8E6)]; // Soothing soft pink
            textColor = const Color(0xFFE86B9D);
            break;
          default:
            bgGradient = [TasbeehColors.iceWhite, const Color(0xFFD9F1FD)]; // Default light blue
            textColor = const Color(0xFF2687F6);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: textColor.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            iconColor: textColor,
            collapsedIconColor: textColor,
            title: TranslatedText(r.prayerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            subtitle: Row(
              children: [
                TranslatedText('Total: ', style: TextStyle(color: textColor.withValues(alpha: 0.8))),
                Text('${r.total} ', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                TranslatedText('Rakats', style: TextStyle(color: textColor.withValues(alpha: 0.8))),
              ],
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRakatRow('Sunnah (Before)', r.sunnahMuakkadahBefore + r.sunnahGhairMuakkadahBefore, textColor),
              _buildRakatRow('Fard', r.fard, textColor, isFard: true),
              _buildRakatRow('Sunnah (After)', r.sunnahAfter, textColor),
              _buildRakatRow('Nafl', r.nafl, textColor),
              if (r.witr > 0) _buildRakatRow('Witr', r.witr, textColor, isWitr: true),
              if (r.naflAfterWitr > 0) _buildRakatRow('Nafl (After Witr)', r.naflAfterWitr, textColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRakatRow(String type, int count, Color themeColor, {bool isFard = false, bool isWitr = false}) {
    if (count == 0) return const SizedBox.shrink();
    
    Color badgeColor = themeColor.withValues(alpha: 0.15);
    Color tColor = themeColor;

    if (isFard) {
      badgeColor = themeColor; // Solid theme color for Fard
      tColor = Colors.white;
    } else if (isWitr) {
      badgeColor = themeColor.withValues(alpha: 0.7); // Slightly less solid for Witr
      tColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TranslatedText(type, style: TextStyle(fontWeight: isFard ? FontWeight.bold : FontWeight.normal, color: themeColor)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: tColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
