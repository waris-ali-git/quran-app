import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../state/tasbeeh_bloc.dart';
import '../models/counter.dart';
import '../tasbeeh_widget.dart';

class TasbeehListScreen extends StatefulWidget {
  const TasbeehListScreen({super.key});

  @override
  State<TasbeehListScreen> createState() => _TasbeehListScreenState();
}

class _TasbeehListScreenState extends State<TasbeehListScreen> {
  String _selectedCategory = 'All';
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehBloc, TasbeehState>(builder: (context, state) {
      final bloc = context.read<TasbeehBloc>();
      var counters = state.counters;

      if (_favoritesOnly) {
        counters = counters.where((c) => c.isFavorite).toList();
      }
      if (_selectedCategory != 'All') {
        counters = counters.where((c) => c.category == _selectedCategory).toList();
      }

      return Scaffold(
        backgroundColor: TasbeehColors.background,
        appBar: AppBar(
          backgroundColor: TasbeehColors.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: TasbeehColors.steelBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: ShaderMask(
            shaderCallback: (b) =>
                TasbeehColors.primaryGradient.createShader(b),
            child: const Text(
              'Choose Dhikr',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: _favoritesOnly
                    ? TasbeehColors.standardBlue
                    : TasbeehColors.steelBlue,
              ),
              onPressed: () =>
                  setState(() => _favoritesOnly = !_favoritesOnly),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: TasbeehColors.babyBlue,
            ),
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: kCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = kCategories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? TasbeehColors.primaryGradient
                            : null,
                        color: selected ? null : TasbeehColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? TasbeehColors.blueDark
                              : TasbeehColors.babyBlue,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : TasbeehColors.steelBlue,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const PrimaryDivider(opacity: 0.2),
            Expanded(
              child: counters.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: counters.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _DhikrCard(counter: counters[i], bloc: bloc),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome,
              size: 48, color: TasbeehColors.babyBlue),
          const SizedBox(height: 12),
          Text('No dhikr found', style: TasbeehTextStyles.subheading),
        ],
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  final TasbeehCounter counter;
  final TasbeehBloc bloc;

  const _DhikrCard({required this.counter, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final isActive = bloc.state.activeCounter?.id == counter.id;

    return GestureDetector(
      onTap: () async {
        await bloc.selectCounter(counter);
        if (context.mounted) Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TasbeehColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? TasbeehColors.standardBlue
                : TasbeehColors.babyBlue,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? TasbeehColors.standardBlue.withValues(alpha: 0.15)
                  : TasbeehColors.standardBlue.withValues(alpha: 0.06),
              blurRadius: isActive ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TasbeehColors.whisperBlue,
                    TasbeehColors.babyBlue.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TasbeehColors.babyBlue),
              ),
              child: Center(
                child: Text(
                  counter.arabicText.split(' ').first,
                  textAlign: TextAlign.center,
                  style: TasbeehTextStyles.arabicLarge(16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(counter.name, style: TasbeehTextStyles.heading.copyWith(fontSize: 15)),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: TasbeehColors.standardBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(counter.translation,
                      style: TasbeehTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: counter.progress,
                            backgroundColor: TasbeehColors.babyBlue,
                            valueColor: const AlwaysStoppedAnimation(
                                TasbeehColors.standardBlue),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${counter.count}/${counter.targetCount}',
                        style: TasbeehTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => bloc.toggleFavorite(counter.id),
              child: Icon(
                counter.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: counter.isFavorite
                    ? TasbeehColors.standardBlue
                    : TasbeehColors.babyBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}