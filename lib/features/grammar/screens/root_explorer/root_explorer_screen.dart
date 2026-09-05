import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/root_word.dart';

// Soft, cohesive pastel palette
const _lavender = Color(0xFFEDE7FB);
const _blush = Color(0xFFFCE8F0);
const _skyBlue = Color(0xFFE3EEFC);
const _mint = Color(0xFFE4F7EE);
const _peach = Color(0xFFFDEFE2);

const _accent = Color(0xFFA593D9); // soft periwinkle-purple, main accent
const _accentDeep = Color(0xFF8B78C9); // slightly deeper for contrast on badges
const _dark = Color(0xFF4D4266); // soft plum-grey for headings/text
const _muted = Color(0xFFAA9FC4); // muted lavender-grey for secondary text
const _bgTop = Color(0xFFF7F3FC);
const _bgBottom = Color(0xFFFDF6FA);

class RootExplorerScreen extends StatefulWidget {
  const RootExplorerScreen({super.key});

  @override
  State<RootExplorerScreen> createState() => _RootExplorerScreenState();
}

class _RootExplorerScreenState extends State<RootExplorerScreen> {
  List<RootWord> _allRoots = [];
  List<RootWord> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final String response =
    await rootBundle.loadString('lib/assets/data/grammar/root_words.json');
    final List<dynamic> data = json.decode(response);
    final roots = data
        .map((r) => RootWord.fromJson(r as Map<String, dynamic>))
        .toList();
    setState(() {
      _allRoots = roots;
      _filtered = roots;
      _isLoading = false;
    });
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _allRoots;
      } else {
        _filtered = _allRoots.where((r) {
          return r.root.contains(query) ||
              r.meaning.toLowerCase().contains(query) ||
              r.derivatives.any((d) =>
              d.arabic.contains(query) ||
                  d.meaning.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Root Explorer',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: _dark,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: _accent),
        )
            : Column(
          children: [
            _buildSearchBar(),
            _buildStats(),
            Expanded(child: _buildRootList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_lavender, _blush],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.amiri(fontSize: 18, color: _dark),
          decoration: InputDecoration(
            hintText: 'Search root or meaning…  ابحث عن الجذر',
            hintStyle: GoogleFonts.montserrat(
                fontSize: 13, color: _muted),
            prefixIcon: const Icon(Icons.search_rounded, color: _accent),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: _muted, size: 18),
              onPressed: () => _searchCtrl.clear(),
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text(
            '${_filtered.length} root${_filtered.length != 1 ? 's' : ''} found',
            style: GoogleFonts.montserrat(
                fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRootList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: _muted),
            const SizedBox(height: 12),
            Text('No roots found',
                style: GoogleFonts.montserrat(color: _muted, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      itemBuilder: (context, i) => _buildRootCard(_filtered[i]),
    );
  }

  Widget _buildRootCard(RootWord root) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_skyBlue, _mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          iconColor: _accentDeep,
          collapsedIconColor: _muted,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accent, Color(0xFFC7BAF0)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              root.root,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            root.meaning,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accentDeep.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${root.frequency}× in Quran',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: _accentDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _dark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    root.category,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: _dark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            // Derivatives
            Text(
              'Derivatives',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _accentDeep,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: root.derivatives.map((d) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        d.arabic,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                            fontSize: 18, color: _dark),
                      ),
                      Text(
                        d.meaning,
                        style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: _muted,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Quran Occurrences
            Text(
              'Quran Occurrences',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _accentDeep,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...root.occurrences.map((occ) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_peach, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_accent, _accentDeep],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${occ.surah}:${occ.ayah}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            occ.context,
                            style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: _muted,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      occ.arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                          fontSize: 20, color: _dark, height: 1.5),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}