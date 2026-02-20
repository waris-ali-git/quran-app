import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/quran_bloc.dart';
import '../models/surah.dart';
import '../models/reading_mode.dart';
import 'reader_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _lastRead;
  List<Surah> _filteredSurahs = [];
  List<Surah> _allSurahs = [];

  @override
  void initState() {
    super.initState();
    context.read<QuranBloc>().add(const LoadSurahsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSurahs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = _allSurahs;
      } else {
        _filteredSurahs = _allSurahs.where((s) {
          return s.englishName.toLowerCase().contains(query.toLowerCase()) ||
              s.name.contains(query) ||
              s.number.toString() == query;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'القرآن الكريم',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'AmiriQuran',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchBottomSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<QuranBloc, QuranState>(
        builder: (context, state) {
          // 1. Search Results
          if (state is QuranSearchResults) {
            return _buildSearchResults(state);
          }

          // 2. Data Loaded -> Update Cache
          if (state is SurahsLoaded) {
            _allSurahs = state.surahs;
            _lastRead = state.lastRead;
            // Apply current search filter if any
            if (_searchController.text.isNotEmpty) {
              _filterSurahs(_searchController.text);
            } else {
              _filteredSurahs = _allSurahs;
            }
          }

          // 3. Error (only if no data)
          if (state is QuranError && _allSurahs.isEmpty) {
            return _ErrorWidget(
              message: state.message,
              onRetry: () => context.read<QuranBloc>().add(const LoadSurahsEvent()),
            );
          }

          // 4. Loading (only if no data)
          if (state is QuranLoading && _allSurahs.isEmpty) {
            return const _LoadingWidget();
          }

          // 5. Show List (from Cache or State)
          if (_filteredSurahs.isNotEmpty) {
             return Column(
              children: [
                if (_lastRead != null) _LastReadBanner(lastRead: _lastRead!),
                _SearchBar(
                  controller: _searchController,
                  onChanged: _filterSurahs,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredSurahs.length,
                    itemBuilder: (context, index) {
                      return _SurahListTile(
                        surah: _filteredSurahs[index],
                        onTap: (mode) => _openSurah(
                          context,
                          _filteredSurahs[index],
                          mode,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchResults(QuranSearchResults state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.read<QuranBloc>().add(const LoadSurahsEvent()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search Results: "${state.query}"',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.results.isEmpty 
            ? const Center(child: Text("No results found"))
            : ListView.builder(
                itemCount: state.results.length,
                itemBuilder: (context, index) {
                  final ayah = state.results[index];
                  return ListTile(
                    title: Text(ayah.text, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20)),
                    subtitle: Text(
                      "Surah ${ayah.surah?.name ?? '?'} : Ayah ${ayah.numberInSurah}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      if (ayah.surah != null) {
                         _openSurah(
                            context,
                            ayah.surah!,
                            ReadingDisplayMode.arabicWithTranslation
                         );
                      }
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Future<void> _openSurah(BuildContext context, Surah surah, ReadingDisplayMode mode) async {
    // Pehle reading mode set karo
    context.read<QuranBloc>().add(ChangeReadingModeEvent(mode: mode));

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<QuranBloc>(),
          child: ReaderScreen(surah: surah, initialMode: mode),
        ),
      ),
    );

    // Wapis aane par dobara list load karein taake screen blank na ho
    if (context.mounted) {
      context.read<QuranBloc>().add(const LoadSurahsEvent());
    }
  }

  void _showSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<QuranBloc>(),
        child: const _QuranSearchSheet(),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1B5E20)),
          SizedBox(height: 16),
          Text('قرآن لوڈ ہو رہا ہے...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'انٹرنیٹ کنکشن نہیں',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('دوبارہ کوشش کریں'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastReadBanner extends StatelessWidget {
  final Map<String, dynamic> lastRead;

  const _LastReadBanner({required this.lastRead});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'آخری پڑھی ہوئی جگہ',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'سورہ ${lastRead['surahNumber']} — آیت ${lastRead['ayahNumber']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to last read position
            },
            child: const Text('جاری رکھیں', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'سورہ تلاش کریں...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _SurahListTile extends StatelessWidget {
  final Surah surah;
  final void Function(ReadingDisplayMode) onTap;

  const _SurahListTile({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEven = surah.number.isEven;
    return InkWell(
      onTap: () => _showModeSelector(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Surah number badge
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${surah.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Surah info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.englishName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${surah.englishNameTranslation} • ${surah.numberOfAyahs} Ayahs • ${surah.revelationType}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Arabic name
              Text(
                surah.name,
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 20,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  surah.name,
                  style: const TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 22,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  surah.englishName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${surah.numberOfAyahs} آیات • ${surah.revelationType}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 24),
            const Text(
              'پڑھنے کا طریقہ منتخب کریں',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            // Mode tiles
            _ModeTile(
              icon: Icons.menu_book,
              title: 'عربی + ترجمہ',
              subtitle: 'آیت کے نیچے ترجمہ',
              onTap: () {
                Navigator.pop(context);
                onTap(ReadingDisplayMode.arabicWithTranslation);
              },
            ),
            _ModeTile(
              icon: Icons.text_fields,
              title: 'لفظ بہ لفظ',
              subtitle: 'ہر لفظ کے نیچے ترجمہ (جیسا تصویر میں)',
              onTap: () {
                Navigator.pop(context);
                onTap(ReadingDisplayMode.wordByWord);
              },
            ),
            _ModeTile(
              icon: Icons.palette,
              title: 'تجوید رنگ',
              subtitle: 'تجوید کے قواعد رنگوں سے',
              onTap: () {
                Navigator.pop(context);
                onTap(ReadingDisplayMode.tajweed);
              },
            ),
            _ModeTile(
              icon: Icons.text_format,
              title: 'صرف عربی',
              subtitle: 'صرف عربی متن',
              onTap: () {
                Navigator.pop(context);
                onTap(ReadingDisplayMode.arabicOnly);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F5E9),
        child: Icon(icon, color: const Color(0xFF1B5E20)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

class _QuranSearchSheet extends StatefulWidget {
  const _QuranSearchSheet();

  @override
  State<_QuranSearchSheet> createState() => _QuranSearchSheetState();
}

class _QuranSearchSheetState extends State<_QuranSearchSheet> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'قرآن میں تلاش کریں...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF1B5E20)),
                onPressed: () {
                  context.read<QuranBloc>().add(
                    SearchQuranEvent(query: _ctrl.text),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            onSubmitted: (val) {
              context.read<QuranBloc>().add(SearchQuranEvent(query: val));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}