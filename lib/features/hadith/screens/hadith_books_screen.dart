import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/hadith_bloc.dart';
import 'hadith_reader_screen.dart';

class HadithBooksScreen extends StatefulWidget {
  const HadithBooksScreen({super.key});

  @override
  State<HadithBooksScreen> createState() => _HadithBooksScreenState();
}

class _HadithBooksScreenState extends State<HadithBooksScreen> {
  @override
  void initState() {
    super.initState();
    if (context.read<HadithBloc>().books.isEmpty) {
      context.read<HadithBloc>().add(const LoadHadithBooksEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ahadeeth (احادیث)', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocBuilder<HadithBloc, HadithState>(
        buildWhen: (previous, current) {
          return current is HadithLoading || current is HadithBooksLoaded || current is HadithError || current is HadithInitial;
        },
        builder: (context, state) {
          final bloc = context.read<HadithBloc>();

          if (state is HadithLoading && bloc.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HadithError && bloc.books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message),
                  TextButton(
                    onPressed: () => bloc.add(const LoadHadithBooksEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final books = bloc.books;
          if (books.isEmpty) {
            return const Center(child: Text('No books available.'));
          }

          // Important Books first (Bukhari, Muslim, etc.)
          final topBooks = ['bukhari', 'muslim', 'tirmidhi', 'abudawud', 'nasai', 'ibnmajah', 'malik', 'darimi'];

          final sortedBooks = [...books]..sort((a, b) {
            int indexA = topBooks.indexOf(a.id);
            int indexB = topBooks.indexOf(b.id);
            if (indexA == -1) indexA = 999;
            if (indexB == -1) indexB = 999;
            return indexA.compareTo(indexB);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sortedBooks.length,
            itemBuilder: (context, index) {
              final book = sortedBooks[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithReaderScreen(book: book),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book, size: 48, color: Color(0xFF1B5E20)),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          book.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${book.editions.length} Translations',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
