import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/hadith.dart';
import '../state/hadith_bloc.dart';

class HadithReaderScreen extends StatefulWidget {
  final HadithBook book;

  const HadithReaderScreen({super.key, required this.book});

  @override
  State<HadithReaderScreen> createState() => _HadithReaderScreenState();
}

class _HadithReaderScreenState extends State<HadithReaderScreen> {
  bool _showAllTranslations = true;

  @override
  void initState() {
    super.initState();
    context.read<HadithBloc>().add(SelectHadithBookEvent(book: widget.book));
  }

  void _showTranslationSelector(BuildContext context, List<HadithEdition> editions) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: editions.length,
          itemBuilder: (context, index) {
            final edition = editions[index];
            return ListTile(
              title: Text(edition.language),
              subtitle: Text(edition.name),
              onTap: () {
                context.read<HadithBloc>().add(
                    ChangeHadithTranslationEvent(language: edition.language));
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showLanguageFilter(BuildContext context, HadithAllTranslationsLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text('Select Languages',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      BlocBuilder<HadithBloc, HadithState>(
                        builder: (context, currentState) {
                          final s = currentState is HadithAllTranslationsLoaded ? currentState : state;
                          return Text(
                            '${s.selectedLanguages.length} of ${s.availableLanguages.length} selected',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          );
                        },
                      ),
                      const Divider(),
                      Expanded(
                        child: BlocBuilder<HadithBloc, HadithState>(
                          builder: (context, currentState) {
                            final s = currentState is HadithAllTranslationsLoaded ? currentState : state;
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: s.availableLanguages.length,
                              itemBuilder: (context, index) {
                                final lang = s.availableLanguages[index];
                                final isSelected = s.selectedLanguages.contains(lang);
                                return CheckboxListTile(
                                  title: Text(lang),
                                  value: isSelected,
                                  activeColor: const Color(0xFF1B5E20),
                                  onChanged: (_) {
                                    context.read<HadithBloc>().add(
                                        ToggleHadithLanguageEvent(language: lang));
                                    setModalState(() {});
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  bool _isRtlLanguage(String language) {
    final lower = language.toLowerCase();
    return lower.startsWith('arabic') || lower.startsWith('urdu') ||
        lower.startsWith('persian') || lower.startsWith('farsi') ||
        lower.startsWith('pashto') || lower.startsWith('sindhi') ||
        lower.startsWith('uyghur') || lower.startsWith('kurdish') ||
        lower.startsWith('hebrew');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.name, style: const TextStyle(fontSize: 16)),
        actions: [
          BlocBuilder<HadithBloc, HadithState>(
            builder: (context, state) {
              if (state is HadithSectionsLoaded || state is HadithsLoaded || state is HadithAllTranslationsLoaded) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showAllTranslations ? Icons.translate : Icons.language,
                        color: _showAllTranslations ? const Color(0xFF1B5E20) : null,
                      ),
                      tooltip: _showAllTranslations ? 'All Translations (ON)' : 'Single Translation',
                      onPressed: () => setState(() => _showAllTranslations = !_showAllTranslations),
                    ),
                    if (!_showAllTranslations)
                      IconButton(
                        icon: const Icon(Icons.language),
                        tooltip: 'Change Translation',
                        onPressed: () => _showTranslationSelector(context, widget.book.editions),
                      ),
                    if (_showAllTranslations && state is HadithAllTranslationsLoaded)
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filter Languages',
                        onPressed: () => _showLanguageFilter(context, state),
                      ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<HadithBloc, HadithState>(
        builder: (context, state) {
          if (state is HadithLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HadithError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Error: ${state.message}', textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<HadithBloc>().add(SelectHadithBookEvent(book: widget.book)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is HadithSectionsLoaded) return _buildSectionsList(state);
          if (state is HadithsLoaded) return _buildSingleTranslationView(state);
          if (state is HadithAllTranslationsLoaded) return _buildAllTranslationsView(state);
          return const SizedBox();
        },
      ),
    );
  }

  // ═══════ SECTIONS LIST ═══════
  Widget _buildSectionsList(HadithSectionsLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.sections.length,
      itemBuilder: (context, index) {
        final section = state.sections[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: section.firstHadith > 0
                ? Text('Hadiths: ${section.firstHadith} – ${section.lastHadith}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13))
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (_showAllTranslations) {
                context.read<HadithBloc>().add(LoadAllTranslationsForSectionEvent(section: section));
              } else {
                context.read<HadithBloc>().add(SelectHadithSectionEvent(section: section));
              }
            },
          ),
        );
      },
    );
  }

  // ═══════ SINGLE TRANSLATION VIEW ═══════
  Widget _buildSingleTranslationView(HadithsLoaded state) {
    return Column(
      children: [
        _buildSectionHeader(state.selectedSection.name, state.selectedBook),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.hadiths.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final hadith = state.hadiths[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHadithNumberBadge(hadith.hadithNumber),
                  const SizedBox(height: 12),
                  Text(
                    hadith.text,
                    style: const TextStyle(fontSize: 18, height: 1.6),
                    textAlign: state.selectedTranslation.direction == 'rtl' ? TextAlign.right : TextAlign.left,
                    textDirection: state.selectedTranslation.direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  if (hadith.grades.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildGradeChips(hadith.grades),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════ ALL TRANSLATIONS VIEW ═══════
  Widget _buildAllTranslationsView(HadithAllTranslationsLoaded state) {
    return Column(
      children: [
        _buildSectionHeader(state.selectedSection.name, state.selectedBook),
        // Language filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.grey[50],
          child: SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: state.availableLanguages.map((lang) {
                final isSelected = state.selectedLanguages.contains(lang);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(lang, style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.black87,
                    )),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B5E20),
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.grey[200],
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      context.read<HadithBloc>().add(ToggleHadithLanguageEvent(language: lang));
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.grey[100],
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '${state.hadiths.length} hadiths • ${state.selectedLanguages.length} languages selected',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.hadiths.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 2, thickness: 2, color: Colors.grey[300]),
            ),
            itemBuilder: (context, index) {
              final hadith = state.hadiths[index];
              return _buildMultiTranslationCard(hadith, state.selectedLanguages, state.availableLanguages);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiTranslationCard(
      MultiTranslationHadith hadith,
      Set<String> selectedLanguages,
      List<String> orderedLanguages) {
    final visibleTranslations = <MapEntry<String, String>>[];
    for (final lang in orderedLanguages) {
      if (selectedLanguages.contains(lang) && hadith.translations.containsKey(lang)) {
        visibleTranslations.add(MapEntry(lang, hadith.translations[lang]!));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHadithNumberBadge(hadith.hadithNumber),
        const SizedBox(height: 12),
        ...visibleTranslations.map((entry) {
          final lang = entry.key;
          final text = entry.value;
          final isRtl = _isRtlLanguage(lang);
          final isArabic = lang.toLowerCase().startsWith('arabic');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isArabic ? const Color(0xFFF5F0E8) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isArabic ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                  width: isArabic ? 1.2 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isArabic ? const Color(0xFF2E7D32).withValues(alpha: 0.15) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isArabic ? const Color(0xFF1B5E20) : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    text,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: isArabic ? 22 : 16,
                      height: isArabic ? 2.0 : 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (hadith.grades.isNotEmpty) _buildGradeChips(hadith.grades),
      ],
    );
  }

  // ═══════ SHARED WIDGETS ═══════
  Widget _buildSectionHeader(String sectionName, HadithBook book) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(sectionName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.list, size: 18),
            label: const Text('Chapters', style: TextStyle(fontSize: 13)),
            onPressed: () => context.read<HadithBloc>().add(SelectHadithBookEvent(book: book)),
          ),
        ],
      ),
    );
  }

  Widget _buildHadithNumberBadge(dynamic hadithNumber) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Hadith $hadithNumber',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildGradeChips(List<HadithGrade> grades) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: grades.map((g) {
        final isSahih = g.grade.toLowerCase().contains('sahih');
        return Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          label: Text('${g.grade} (${g.name})', style: const TextStyle(fontSize: 11)),
          backgroundColor: isSahih ? Colors.green[100] : Colors.orange[100],
        );
      }).toList(),
    );
  }
}
