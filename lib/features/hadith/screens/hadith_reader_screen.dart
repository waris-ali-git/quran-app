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
                context.read<HadithBloc>().add(ChangeHadithTranslationEvent(language: edition.language));
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.name),
        actions: [
          BlocBuilder<HadithBloc, HadithState>(
            builder: (context, state) {
              if (state is HadithSectionsLoaded || state is HadithsLoaded) {
                return IconButton(
                  icon: const Icon(Icons.language),
                  tooltip: 'Change Translation',
                  onPressed: () => _showTranslationSelector(context, widget.book.editions),
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
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is HadithSectionsLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.sections.length,
              itemBuilder: (context, index) {
                final section = state.sections[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Hadiths: ${section.firstHadith} to ${section.lastHadith}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.read<HadithBloc>().add(SelectHadithSectionEvent(section: section));
                    },
                  ),
                );
              },
            );
          }

          if (state is HadithsLoaded) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.selectedSection.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.list),
                        label: const Text('Chapters'),
                        onPressed: () {
                          // Allow user to pick another chapter
                          // State needs to go back to HadithSectionsLoaded
                          // For simplicity, just dispatch SelectHadithBookEvent to reload chapters
                          context.read<HadithBloc>().add(SelectHadithBookEvent(book: state.selectedBook));
                        },
                      ),
                    ],
                  ),
                ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Hadith ${hadith.hadithNumber}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Optional: fetch Arabic text here alongside translation if needed. 
                          // Currently Fawaz API returns translated text in selected edition.
                          // Ideally arabic text would be fetched simultaneously. For now just show the fetched text.
                          Text(
                            hadith.text,
                            style: const TextStyle(fontSize: 18, height: 1.6),
                            textAlign: state.selectedTranslation.direction == 'rtl' ? TextAlign.right : TextAlign.left,
                            textDirection: state.selectedTranslation.direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          if (hadith.grades.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: hadith.grades.map((g) => Chip(
                                label: Text('${g.grade} (${g.name})'),
                                backgroundColor: g.grade.toLowerCase().contains('sahih') 
                                    ? Colors.green[100] 
                                    : Colors.orange[100],
                              )).toList(),
                            )
                          ]
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
