// lib/screens/prophets/prophets_list_screen.dart

import 'package:flutter/material.dart';
import 'prophets_data.dart';
import 'prophets_detail_screen.dart';
import '../../../core/widgets/language_selector_button.dart';
import '../../../core/widgets/translated_text.dart';
import '../../../shared/widgets/custom_button.dart';

class ProphetsListScreen extends StatefulWidget {
  const ProphetsListScreen({super.key});

  @override
  State<ProphetsListScreen> createState() => _ProphetsListScreenState();
}

class _ProphetsListScreenState extends State<ProphetsListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProphetModel> get _filtered {
    if (_search.isEmpty) return allProphets;
    final q = _search.toLowerCase();
    return allProphets
        .where((p) =>
    p.englishName.toLowerCase().contains(q) ||
        p.arabicName.contains(q) ||
        p.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3), // Match neumorphic base
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildQuranVerse()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: _buildGrid(),
          ),
        ],
      ),
    );
  }

  // ── SLIVER APP BAR ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFFF0F0F3),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
      actions: const [
        LanguageSelectorButton(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: TranslatedText(
            'Stories of Prophets',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1C1C1E),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F0F3),
          ),
          child: Stack(
            children: [
              // decorative circles (glassy)
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const Positioned(
                left: 20,
                bottom: 42,
                child: TranslatedText(
                  'قصص الأنبياء',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF1C1C1E),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'UthmanicHafs',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SEARCH BAR ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LiquidGlassContainer(
        height: 56,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
          decoration: InputDecoration(
            hintText: 'Search prophets...', // Keeping it as string if TextField doesn't support Widget hint, but usually we'd want this translated too.
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.grey.shade400, size: 22),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.close_rounded,
                  color: Colors.grey.shade400, size: 20),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _search = '');
              },
            )
                : null,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ── QURAN VERSE BANNER ──────────────────────────────────────────────────────
  Widget _buildQuranVerse() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LiquidGlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TranslatedText(
              'نَحْنُ نَقُصُّ عَلَيْكَ أَحْسَنَ الْقَصَصِ',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.w600,
                height: 1.6,
                fontFamily: 'UthmanicHafs',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TranslatedText(
              '"We relate to you the best of stories"  —  Quran 12:3',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── PROPHETS GRID ───────────────────────────────────────────────────────────
  Widget _buildGrid() {
    final prophets = _filtered;
    if (prophets.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No prophets found',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final prophet = prophets[index];
          return _ProphetCard(
            prophet: prophet,
            index: index,
            onTap: () => _openDetail(prophet),
          );
        },
        childCount: prophets.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
    );
  }

  void _openDetail(ProphetModel prophet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProphetDetailScreen(prophet: prophet)),
    );
  }
}

// ── PROPHET CARD ─────────────────────────────────────────────────────────────
class _ProphetCard extends StatefulWidget {
  final ProphetModel prophet;
  final int index;
  final VoidCallback onTap;

  const _ProphetCard({
    required this.prophet,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ProphetCard> createState() => _ProphetCardState();
}

class _ProphetCardState extends State<_ProphetCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 60).clamp(0, 600);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = prophetColors[widget.prophet.id % prophetColors.length];
    final lightColor = Color(colors[0]);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: LiquidGlassContainer(
            borderRadius: 24,
            glassColor: lightColor.withValues(alpha: 0.28),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${widget.prophet.id}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                    Text(
                      widget.prophet.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                const Spacer(),
                TranslatedText(
                  widget.prophet.arabicName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                    fontFamily: 'Jameel Noori',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                TranslatedText(
                  widget.prophet.englishName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lightColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TranslatedText(
                    widget.prophet.title,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}