import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../state/tasbeeh_bloc.dart';
import '../models/counter.dart';
import '../tasbeeh_widget.dart';
import 'tasbeeh_list_screen.dart';
import 'tasbeeh_settings_screen.dart';
import 'tasbeeh_stats_screen.dart';
import 'add_tasbeeh_screen.dart';

class TasbeehHomeScreen extends StatefulWidget {
  const TasbeehHomeScreen({super.key});

  @override
  State<TasbeehHomeScreen> createState() => _TasbeehHomeScreenState();
}

class _TasbeehHomeScreenState extends State<TasbeehHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _tapController;
  late AnimationController _completionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tapScaleAnimation;
  late Animation<double> _completionAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _completionAnimation = CurvedAnimation(
      parent: _completionController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _onTap(TasbeehBloc bloc) async {
    _tapController.forward().then((_) => _tapController.reverse());

    await bloc.increment();

    if (bloc.state.justCompleted) {
      _completionController
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehBloc, TasbeehState>(builder: (context, state) {
      final bloc = context.read<TasbeehBloc>();
      final counter = state.activeCounter;

      if (state.isLoading) {
        return const Scaffold(
          backgroundColor: TasbeehColors.background,
          body: Center(
            child: CircularProgressIndicator(
              color: TasbeehColors.standardBlue,
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: TasbeehColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, bloc, counter),
              Expanded(
                child: counter == null
                    ? _buildEmptyState(context)
                    : _buildCounterContent(context, bloc, state, counter),
              ),
              _buildBottomNav(context, bloc, counter),
            ],
          ),
        ),
      );
    });
  }

  // ─── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(
      BuildContext context, TasbeehBloc bloc, TasbeehCounter? counter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          PrimaryIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    TasbeehColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'تسبيح',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Tasbeeh Counter',
                style: TasbeehTextStyles.caption.copyWith(letterSpacing: 1.5),
              ),
            ],
          ),
          const Spacer(),
          if (counter != null)
            PrimaryIconButton(
              icon: counter.isFavorite ? Icons.favorite : Icons.favorite_border,
              onTap: () => bloc.toggleFavorite(counter.id),
            ),
          const SizedBox(width: 10),
          PrimaryIconButton(
            icon: Icons.tune_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const TasbeehSettingsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Counter Content ───────────────────────────────────────────────────
  Widget _buildCounterContent(
      BuildContext context, TasbeehBloc bloc, TasbeehState state, TasbeehCounter counter) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: TasbeehColors.whisperBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TasbeehColors.babyBlue),
              ),
              child: Text(
                counter.category,
                style: TasbeehTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              counter.arabicText,
              textAlign: TextAlign.center,
              style: TasbeehTextStyles.arabicLarge(32),
            ),
            const SizedBox(height: 6),
            if (state.settings['showTransliteration'] != false)
              Text(
                counter.transliteration,
                style: TasbeehTextStyles.subheading,
              ),
            if (state.settings['showTranslation'] != false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  counter.translation,
                  textAlign: TextAlign.center,
                  style: TasbeehTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 36),
            _buildMainCounter(bloc, state, counter),
            const SizedBox(height: 28),
            TasbeehBeadsRow(count: counter.count, target: counter.targetCount),
            const SizedBox(height: 24),
            _buildInfoRow(counter),
            const SizedBox(height: 28),
            _buildActionButtons(context, bloc, counter),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Main Counter Ring + Button ─────────────────────────────────────────────
  Widget _buildMainCounter(TasbeehBloc bloc, TasbeehState state, TasbeehCounter counter) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (state.justCompleted)
          ScaleTransition(
            scale: _completionAnimation,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TasbeehColors.standardBlue.withValues(alpha: 0.06),
              ),
            ),
          ),
        SizedBox(
          width: 240,
          height: 240,
          child: CustomPaint(
            painter: PrimaryArcPainter(
              progress: counter.progress,
              strokeWidth: 7,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _onTap(bloc),
          child: AnimatedBuilder(
            animation:
            Listenable.merge([_tapScaleAnimation, _pulseAnimation]),
            builder: (_, __) => Transform.scale(
              scale: _tapScaleAnimation.value * _pulseAnimation.value,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TasbeehColors.surface,
                      TasbeehColors.whisperBlue,
                    ],
                    center: Alignment.topCenter,
                    radius: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TasbeehColors.standardBlue.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: Offset(-4, -4),
                    ),
                  ],
                  border: Border.all(
                    color: TasbeehColors.babyBlue,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${counter.count}',
                      style: TasbeehTextStyles.counterDisplay,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 1,
                      width: 40,
                      color: TasbeehColors.babyBlue,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '/ ${counter.targetCount}',
                      style: TasbeehTextStyles.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Info Row ───────────────────────────────────────────────────────────────
  Widget _buildInfoRow(TasbeehCounter counter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _InfoChip(
          icon: Icons.refresh_rounded,
          label: '${counter.roundsCompleted} rounds',
        ),
        const SizedBox(width: 12),
        _InfoChip(
          icon: Icons.arrow_upward_rounded,
          label: '${counter.remainingInRound} left',
        ),
        const SizedBox(width: 12),
        _InfoChip(
          icon: Icons.history_rounded,
          label: '${counter.totalCount} total',
        ),
      ],
    );
  }

  // ─── Action Buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons(
      BuildContext context, TasbeehBloc bloc, TasbeehCounter counter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          label: 'Undo',
          icon: Icons.remove_rounded,
          onTap: bloc.decrement,
          small: true,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          label: 'Reset',
          icon: Icons.restart_alt_rounded,
          onTap: () => _showResetDialog(context, bloc),
          primary: true,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          label: 'Change',
          icon: Icons.swap_horiz_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const TasbeehListScreen(),
              ),
            ),
          ),
          small: true,
        ),
      ],
    );
  }

  // ─── Bottom Navigation ──────────────────────────────────────────────────────
  Widget _buildBottomNav(
      BuildContext context, TasbeehBloc bloc, TasbeehCounter? counter) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: TasbeehColors.surface,
        border: Border(
            top: BorderSide(color: TasbeehColors.babyBlue, width: 1)),
        boxShadow: [
          BoxShadow(
            color: TasbeehColors.standardBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.grid_view_rounded,
            label: 'All Dhikr',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const TasbeehListScreen(),
                ),
              ),
            ),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const TasbeehStatsScreen(),
                ),
              ),
            ),
          ),
          _NavItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Custom',
            primary: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AddTasbeehScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome,
              size: 56, color: TasbeehColors.babyBlue),
          const SizedBox(height: 16),
          Text('No dhikr selected', style: TasbeehTextStyles.heading),
          const SizedBox(height: 8),
          Text('Tap below to choose or add one',
              style: TasbeehTextStyles.subheading),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, TasbeehBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TasbeehColors.iceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Counter',
            style: TextStyle(
                color: TasbeehColors.textPrimary, fontWeight: FontWeight.w600)),
        content: const Text(
            'This will reset the current count and save the session.',
            style: TextStyle(color: TasbeehColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: TasbeehColors.steelBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TasbeehColors.standardBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              bloc.resetCount();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TasbeehColors.whisperBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TasbeehColors.babyBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: TasbeehColors.steelBlue),
          const SizedBox(width: 4),
          Text(label, style: TasbeehTextStyles.caption),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool small;
  final bool primary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.small = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 52.0 : 64.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: primary ? TasbeehColors.primaryGradient : null,
              color: primary ? null : TasbeehColors.surface,
              border: Border.all(
                color: primary
                    ? TasbeehColors.blueDark
                    : TasbeehColors.babyBlue,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: TasbeehColors.standardBlue
                      .withValues(alpha: primary ? 0.3 : 0.1),
                  blurRadius: primary ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: size * 0.38,
              color: primary ? Colors.white : TasbeehColors.steelBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TasbeehTextStyles.caption),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: primary
                ? TasbeehColors.standardBlue
                : TasbeehColors.steelBlue,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TasbeehTextStyles.caption.copyWith(
              color:
              primary ? TasbeehColors.standardBlue : TasbeehColors.textLight,
              fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}