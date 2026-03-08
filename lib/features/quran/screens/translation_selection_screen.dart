import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/quran_bloc.dart';

class TranslationSelectionScreen extends StatefulWidget {
  const TranslationSelectionScreen({super.key});

  @override
  State<TranslationSelectionScreen> createState() => _TranslationSelectionScreenState();
}

class _TranslationSelectionScreenState extends State<TranslationSelectionScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Translation'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by language or name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<QuranBloc, QuranState>(
        builder: (context, state) {
          final bloc = context.read<QuranBloc>();
          final translations = bloc.availableTranslations;

          if (translations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = translations.where((t) {
            return t.englishName.toLowerCase().contains(_searchQuery) ||
                   t.name.toLowerCase().contains(_searchQuery) ||
                   t.language.toLowerCase().contains(_searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final t = filtered[index];
              return ListTile(
                title: Text(t.englishName),
                subtitle: Text('${t.name} (${t.language})'),
                onTap: () {
                  bloc.add(ChangeTranslationEvent(edition: t.identifier));
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
