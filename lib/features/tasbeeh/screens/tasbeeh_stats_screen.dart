import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../state/tasbeeh_bloc.dart';
import '../models/counter.dart';
import '../tasbeeh_widget.dart';

class TasbeehStatsScreen extends StatefulWidget {
  const TasbeehStatsScreen({super.key});

  @override
  State<TasbeehStatsScreen> createState() => _TasbeehStatsScreenState();
}

class _TasbeehStatsScreenState extends State<TasbeehStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasbeehBloc>().refreshStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehBloc, TasbeehState>(builder: (context, state) {
      final stats = state.stats;
      final counters = state.counters;
      final mostUsed = stats['mostUsed'] as TasbeehCounter?;

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
              'Statistics',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: TasbeehColors.babyBlue),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Overview', style: TasbeehTextStyles.heading),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  icon: Icons.grain_rounded,
                  label: 'Total Dhikr',
                  value: _formatNum(stats['totalCount'] ?? 0),
                ),
                StatCard(
                  icon: Icons.today_rounded,
                  label: "Today's Count",
                  value: _formatNum(stats['todayCount'] ?? 0),
                ),
                StatCard(
                  icon: Icons.loop_rounded,
                  label: 'Sessions',
                  value: _formatNum(stats['totalSessions'] ?? 0),
                ),
                StatCard(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Unique Dhikr',
                  value: '${stats['uniqueDhikr'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (mostUsed != null) ...[
              Text('Most Recited', style: TasbeehTextStyles.heading),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF8E7),
                      Color(0xFFDBE9FA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TasbeehColors.babyBlue),
                  boxShadow: [
                    BoxShadow(
                      color: TasbeehColors.standardBlue.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: TasbeehColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mostUsed.arabicText,
                              style: TasbeehTextStyles.arabicLarge(18)),
                          Text(mostUsed.name,
                              style: TasbeehTextStyles.subheading),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatNum(mostUsed.totalCount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: TasbeehColors.standardBlue,
                          ),
                        ),
                        Text('total', style: TasbeehTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
            Text('All Dhikr', style: TasbeehTextStyles.heading),
            const SizedBox(height: 12),
            ...counters.map((c) => _CounterStatRow(counter: c)),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _CounterStatRow extends StatelessWidget {
  final TasbeehCounter counter;

  const _CounterStatRow({required this.counter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TasbeehColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TasbeehColors.babyBlue),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(counter.name,
                    style: TasbeehTextStyles.subheading
                        .copyWith(color: TasbeehColors.textPrimary)),
              ),
              Text(
                '${counter.totalCount} total',
                style: TasbeehTextStyles.caption
                    .copyWith(color: TasbeehColors.standardBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: counter.totalCount > 0
                        ? (counter.totalCount / 1000).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: TasbeehColors.babyBlue,
                    valueColor: const AlwaysStoppedAnimation(
                        TasbeehColors.standardBlue),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${counter.totalSessions} sessions',
                style: TasbeehTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}