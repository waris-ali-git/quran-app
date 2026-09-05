import 'package:flutter/material.dart';
import '../../../core/widgets/translated_text.dart';
import '../../../core/widgets/language_selector_button.dart';
import '../models/feeling_dua_model.dart';

class FeelingDuaDetailScreen extends StatefulWidget {
  final FeelingCategory category;

  const FeelingDuaDetailScreen({super.key, required this.category});

  @override
  State<FeelingDuaDetailScreen> createState() => _FeelingDuaDetailScreenState();
}

class _FeelingDuaDetailScreenState extends State<FeelingDuaDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  Color get _deepColor => widget.category.color;
  Color get _lightColor => widget.category.color.withValues(alpha: 0.5);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context),
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _DuaCard(
                    dua: widget.category.duas[index],
                    index: index,
                    deepColor: _deepColor,
                    lightColor: _lightColor,
                  );
                },
                childCount: widget.category.duas.length,
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
      expandedHeight: 220,
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
                      // English name
                      TranslatedText(
                        widget.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtitle
                      TranslatedText(
                        'Duas for when you are feeling ${widget.category.name.toLowerCase()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
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
}

// ── DUA CARD ──────────────────────────────────────────────────────────────────
class _DuaCard extends StatelessWidget {
  final FeelingDua dua;
  final int index;
  final Color deepColor;
  final Color lightColor;

  const _DuaCard({
    required this.dua,
    required this.index,
    required this.deepColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: deepColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (dua.title.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: deepColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    dua.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: deepColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Arabic Text (NO TRANSLATION APPLIED, ARABIC FONT ONLY)
          if (dua.arabic.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: Text(
                dua.arabic,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DigitalKhatt', // Using the beautiful Arabic font
                  color: Color(0xFF1C1C1E),
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Transliteration
          if (dua.transliteration.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dua.transliteration,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Translation (GLOBAL TRANSLATION APPLIED)
          if (dua.translation.isNotEmpty) ...[
            TranslatedText(
              dua.translation,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1C1C1E),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reference / Hadith
          if (dua.reference.isNotEmpty || dua.hadith.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book_rounded, size: 14, color: deepColor.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    dua.reference.isNotEmpty ? dua.reference : dua.hadith,
                    style: TextStyle(
                      fontSize: 12,
                      color: deepColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
