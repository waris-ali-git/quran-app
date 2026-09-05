// lib/screens/prophets/prophet_detail_screen.dart

import 'package:flutter/material.dart';
import 'prophets_data.dart';
import '../../../core/widgets/translated_text.dart';
import '../../../core/widgets/language_selector_button.dart';

class ProphetDetailScreen extends StatefulWidget {
  final ProphetModel prophet;

  const ProphetDetailScreen({super.key, required this.prophet});

  @override
  State<ProphetDetailScreen> createState() => _ProphetDetailScreenState();
}

class _ProphetDetailScreenState extends State<ProphetDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = [];
  late AnimationController _fabCtrl;
  bool _showFab = false;
  int _activeSectionIndex = 0;
  bool _isTOCExpanded = false;

  // ── FIX: debounce flag to avoid setState storm in scroll listener ───────────
  bool _scheduledUpdate = false;

  @override
  void initState() {
    super.initState();
    _sectionKeys.addAll(
      List.generate(widget.prophet.sections.length, (_) => GlobalKey()),
    );
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    // ── FIX: use a single post-frame callback instead of scheduling one every
    //         scroll event — prevents the infinite setState → rebuild loop. ───
    if (_scheduledUpdate) return;
    _scheduledUpdate = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledUpdate = false;
      if (!mounted) return;

      final offset = _scrollController.offset;
      final shouldShowFab = offset > 280;

      // Track active section for TOC highlighting
      int newActiveSection = _activeSectionIndex;
      final screenHeight = MediaQuery.sizeOf(context).height;
      for (int i = _sectionKeys.length - 1; i >= 0; i--) {
        final ctx = _sectionKeys[i].currentContext;
        if (ctx != null) {
          final box = ctx.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final pos = box.localToGlobal(Offset.zero);
            if (pos.dy < screenHeight * 0.4) {
              newActiveSection = i;
              break;
            }
          }
        }
      }

      if (shouldShowFab != _showFab || newActiveSection != _activeSectionIndex) {
        setState(() {
          _showFab = shouldShowFab;
          _activeSectionIndex = newActiveSection;
        });
        if (_showFab) {
          _fabCtrl.forward();
        } else {
          _fabCtrl.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  Color get _lightColor =>
      Color(prophetColors[widget.prophet.id % prophetColors.length][0]);
  Color get _deepColor =>
      Color(prophetColors[widget.prophet.id % prophetColors.length][1]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context),
              SliverToBoxAdapter(child: _buildInfoRow()),
              SliverToBoxAdapter(child: _buildKeyLessonCard()),
              SliverToBoxAdapter(child: _buildShortBio()),
              if (widget.prophet.tableOfContents.isNotEmpty)
                SliverToBoxAdapter(child: _buildTableOfContents()),
              SliverToBoxAdapter(child: _buildSections()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // TOC FAB — only shown when scrolled down and TOC exists
          if (widget.prophet.tableOfContents.isNotEmpty)
            Positioned(
              bottom: 24,
              right: 20,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _fabCtrl,
                  curve: Curves.elasticOut,
                ),
                child: FloatingActionButton.extended(
                  onPressed: _showTOCDrawer,
                  backgroundColor: _deepColor,
                  icon: const Icon(Icons.list_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Contents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  elevation: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: _deepColor,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        const LanguageSelectorButton(),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepColor, _lightColor],
            ),
          ),
          child: Stack(
            children: [
              // Background decorations
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji + prophet number row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Prophet #${widget.prophet.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.prophet.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Arabic name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.prophet.arabicName,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // English name
                      Text(
                        widget.prophet.englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title
                      Text(
                        widget.prophet.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── INFO ROW ─────────────────────────────────────────────────────────────────
  Widget _buildInfoRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ── FIX: use IntrinsicHeight + Row instead of nested Expanded logic ───
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _infoChip(Icons.access_time_rounded, widget.prophet.period)),
            Container(width: 1, color: Colors.grey.shade200),
            Expanded(
              child: _infoChip(
                Icons.menu_book_rounded,
                widget.prophet.mentionedIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: _deepColor),
          const SizedBox(width: 8),
          Flexible(
            child: TranslatedText(
              text,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF2D1B69).withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── KEY LESSON ───────────────────────────────────────────────────────────────
  Widget _buildKeyLessonCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_lightColor, _lightColor.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _deepColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _deepColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_rounded, color: _deepColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'Key Lesson',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _deepColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  widget.prophet.keyLesson,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2D1B69).withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SHORT BIO ─────────────────────────────────────────────────────────────────
  Widget _buildShortBio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TranslatedText(
        widget.prophet.shortBio,
        style: TextStyle(
          fontSize: 15,
          color: const Color(0xFF2D1B69).withValues(alpha: 0.7),
          height: 1.65,
        ),
      ),
    );
  }

  // ── TABLE OF CONTENTS ─────────────────────────────────────────────────────────
  Widget _buildTableOfContents() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isTOCExpanded = !_isTOCExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded,
                      color: _deepColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TranslatedText(
                      'Table of Contents',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _deepColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isTOCExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_up_rounded,
                        color: _deepColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, indent: 16, endIndent: 16),
                ...widget.prophet.tableOfContents.asMap().entries.map((e) {
                  final i = e.key;
                  final title = e.value;
                  return InkWell(
                    onTap: () => _scrollToSection(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _lightColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _deepColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TranslatedText(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    const Color(0xFF2D1B69).withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.grey.shade300, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
            crossFadeState: _isTOCExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // ── SECTIONS ──────────────────────────────────────────────────────────────────
  Widget _buildSections() {
    if (widget.prophet.sections.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.prophet.sections.asMap().entries.map((e) {
          return _SectionWidget(
            key: _sectionKeys[e.key],
            section: e.value,
            index: e.key,
            deepColor: _deepColor,
            lightColor: _lightColor,
          );
        }).toList(),
      ),
    );
  }

  // ── SCROLL TO SECTION ─────────────────────────────────────────────────────────
  // ── FIX: removed Navigator.pop() — this was popping the detail screen itself
  //         when a TOC item was tapped from the inline table of contents. ───────
  void _scrollToSection(int index) {
    if (index < 0 || index >= _sectionKeys.length) return;
    final ctx = _sectionKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
    }
  }

  // ── TOC BOTTOM SHEET ──────────────────────────────────────────────────────────
  void _showTOCDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF8FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    widget.prophet.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prophet.englishName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _deepColor,
                        ),
                      ),
                      Text(
                        'Table of Contents',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.prophet.tableOfContents.length,
                itemBuilder: (_, i) {
                  final isActive = _activeSectionIndex == i;
                  return ListTile(
                    onTap: () {
                      // ── FIX: close the bottom sheet first, then scroll ───
                      Navigator.of(sheetContext).pop();
                      _scrollToSection(i);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: isActive ? _lightColor : Colors.transparent,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive ? _deepColor : _lightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : _deepColor,
                          ),
                        ),
                      ),
                    ),
                    title: TranslatedText(
                      widget.prophet.tableOfContents[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? _deepColor
                            : const Color(0xFF2D1B69).withValues(alpha: 0.75),
                      ),
                    ),
                    trailing: isActive
                        ? Icon(Icons.fiber_manual_record_rounded,
                            color: _deepColor, size: 10)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION WIDGET ────────────────────────────────────────────────────────────
class _SectionWidget extends StatelessWidget {
  final ProphetSection section;
  final int index;
  final Color deepColor;
  final Color lightColor;

  const _SectionWidget({
    super.key,
    required this.section,
    required this.index,
    required this.deepColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section heading
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: deepColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TranslatedText(
                  section.heading,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: deepColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Section content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: deepColor.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildContent(section.content),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String content) {
    final lines = content.split('\n');
    final hasBullets = lines.any((l) => l.trimLeft().startsWith('•'));

    if (!hasBullets) {
      return TranslatedText(
        content,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF3D2B5C),
          height: 1.75,
          letterSpacing: 0.1,
        ),
      );
    }

    // Render mixed content with bullet points
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trimLeft().startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: deepColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TranslatedText(
                    line.replaceFirst(RegExp(r'^[\s•]+'), ''),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D2B5C),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (line.trim().isEmpty) return const SizedBox(height: 8);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: TranslatedText(
            line,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF3D2B5C),
              height: 1.75,
            ),
          ),
        );
      }).toList(),
    );
  }
}