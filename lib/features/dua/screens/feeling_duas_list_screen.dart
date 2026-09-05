import 'package:flutter/material.dart';
import '../../../core/widgets/language_selector_button.dart';
import '../../../core/widgets/translated_text.dart';
import '../../../shared/widgets/custom_button.dart';
import '../models/feeling_dua_model.dart';
import '../services/feeling_dua_service.dart';
import 'feeling_dua_detail_screen.dart';

class FeelingDuasListScreen extends StatefulWidget {
  const FeelingDuasListScreen({super.key});

  @override
  State<FeelingDuasListScreen> createState() => _FeelingDuasListScreenState();
}

class _FeelingDuasListScreenState extends State<FeelingDuasListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  List<FeelingCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final service = FeelingDuaService();
    final categories = await service.loadFeelingDuas();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FeelingCategory> get _filtered {
    if (_search.isEmpty) return _categories;
    final q = _search.toLowerCase();
    return _categories
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3), // Match neumorphic base
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildHeaderMessage()),
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
            'I am Feeling...',
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
                  'أنا أشعر...',
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
            hintText: 'Search feelings...',
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

  // ── HEADER MESSAGE ──────────────────────────────────────────────────────
  Widget _buildHeaderMessage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LiquidGlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TranslatedText(
              'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
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
              '"And when My servants ask you concerning Me, indeed I am near." — Quran 2:186',
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

  // ── CATEGORY GRID ───────────────────────────────────────────────────────────
  Widget _buildGrid() {
    final categories = _filtered;
    if (categories.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No feelings found',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = categories[index];
          return _CategoryCard(
            category: category,
            index: index,
            onTap: () => _openDetail(category),
          );
        },
        childCount: categories.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
    );
  }

  void _openDetail(FeelingCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FeelingDuaDetailScreen(category: category)),
    );
  }
}

// ── CATEGORY CARD ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final FeelingCategory category;
  final int index;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 30).clamp(0, 600);
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
    final bgColor = widget.category.color;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: LiquidGlassContainer(
            borderRadius: 24,
            glassColor: bgColor.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TranslatedText(
                  widget.category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  '${widget.category.duas.length} Duas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
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
