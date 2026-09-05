import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakTier {
  final int requiredDays;
  final String name;
  final List<Color> colors;
  final Color glowColor;
  final IconData icon;
  final String description;
  final bool hasPulse;
  final bool hasRotate;

  const StreakTier({
    required this.requiredDays,
    required this.name,
    required this.colors,
    required this.glowColor,
    required this.icon,
    required this.description,
    this.hasPulse = false,
    this.hasRotate = false,
  });
}

const List<StreakTier> streakTiers = [
  StreakTier(
    requiredDays: 1,
    name: 'Starter Flame',
    colors: [Color(0xFFFF9F43), Color(0xFFFF5252)],
    glowColor: Color(0xFFFF9F43),
    icon: Icons.local_fire_department_rounded,
    description: 'A glowing spark of daily faith. Welcome to your journey!',
  ),
  StreakTier(
    requiredDays: 3,
    name: 'Bronze Spark',
    colors: [Color(0xFFCD7F32), Color(0xFF8B5A2B)],
    glowColor: Color(0xFFCD7F32),
    icon: Icons.local_fire_department_rounded,
    description: 'Three days of devotion. Your spark is catching fire!',
    hasPulse: true,
  ),
  StreakTier(
    requiredDays: 5,
    name: 'Golden Devout',
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    glowColor: Color(0xFFFFD700),
    icon: Icons.whatshot_rounded,
    description: 'Five continuous days. You are building a warm habit!',
    hasPulse: true,
  ),
  StreakTier(
    requiredDays: 7,
    name: 'Emerald Beacon',
    colors: [Color(0xFF2ECC71), Color(0xFF16A085)],
    glowColor: Color(0xFF2ECC71),
    icon: Icons.wb_sunny_rounded,
    description: 'One full week! Your faith shines like a bright beacon.',
    hasPulse: true,
  ),
  StreakTier(
    requiredDays: 10,
    name: 'Amethyst Aura',
    colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
    glowColor: Color(0xFF9B59B6),
    icon: Icons.filter_vintage_rounded,
    description: 'Ten days. A calm, beautiful aura of persistence.',
    hasPulse: true,
  ),
  StreakTier(
    requiredDays: 15,
    name: 'Phoenix Ruby',
    colors: [Color(0xFFFF5252), Color(0xFFFF007F)],
    glowColor: Color(0xFFFF5252),
    icon: Icons.bolt_rounded,
    description: 'Fifteen days! A powerful, blazing ruby flame of resolve.',
    hasPulse: true,
    hasRotate: true,
  ),
  StreakTier(
    requiredDays: 30,
    name: 'Glacial Frost',
    colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
    glowColor: Color(0xFF00E5FF),
    icon: Icons.ac_unit_rounded,
    description: 'One month! Cool, unshakable discipline like solid ice.',
    hasPulse: true,
    hasRotate: true,
  ),
  StreakTier(
    requiredDays: 50,
    name: 'Cosmic Stardust',
    colors: [Color(0xFFE040FB), Color(0xFF3F51B5)],
    glowColor: Color(0xFFE040FB),
    icon: Icons.stars_rounded,
    description: 'Fifty days! Your daily schedule shines like stars in the sky.',
    hasPulse: true,
    hasRotate: true,
  ),
  StreakTier(
    requiredDays: 100,
    name: 'Solar Core',
    colors: [Color(0xFFFF3D00), Color(0xFFFFC400)],
    glowColor: Color(0xFFFF3D00),
    icon: Icons.brightness_high_rounded,
    description: 'One hundred days! Intense, life-giving solar devotion.',
    hasPulse: true,
    hasRotate: true,
  ),
  StreakTier(
    requiredDays: 200,
    name: 'Diamond Grace',
    colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
    glowColor: Color(0xFFE0F7FA),
    icon: Icons.diamond_rounded,
    description: 'Two hundred days! Crystal clear, flawless commitment.',
    hasPulse: true,
    hasRotate: true,
  ),
  StreakTier(
    requiredDays: 365,
    name: 'Divine Crown',
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    glowColor: Color(0xFFFFD700),
    icon: Icons.emoji_events_rounded,
    description: 'One full year! Ultimate crown of steadfast worship. Subhan Allah!',
    hasPulse: true,
    hasRotate: true,
  ),
];

class StreakWidget extends StatefulWidget {
  const StreakWidget({Key? key}) : super(key: key);

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget> with TickerProviderStateMixin {
  int _streakCount = 1;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _initStreak();
  }

  Future<void> _initStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenDate = prefs.getString('last_open_date');
    final today = _formatDate(DateTime.now());
    
    int streak = prefs.getInt('streak_count') ?? 1;

    if (lastOpenDate != null) {
      if (lastOpenDate == today) {
        // Already opened today, do nothing
      } else {
        final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));
        if (lastOpenDate == yesterday) {
          streak++;
        } else {
          streak = 1;
        }
      }
    }
    
    await prefs.setString('last_open_date', today);
    await prefs.setInt('streak_count', streak);
    
    if (mounted) {
      setState(() {
        _streakCount = streak;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  StreakTier _getCurrentTier() {
    for (int i = streakTiers.length - 1; i >= 0; i--) {
      if (_streakCount >= streakTiers[i].requiredDays) {
        return streakTiers[i];
      }
    }
    return streakTiers[0];
  }

  void _showMilestonesDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Streak Milestones',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: _MilestonesPopup(
            currentStreak: _streakCount,
            onStreakChanged: (newStreak) {
              setState(() {
                _streakCount = newStreak;
              });
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = _getCurrentTier();
    
    Widget iconWidget = ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: tier.colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        tier.icon,
        color: Colors.white,
        size: 24,
      ),
    );

    if (tier.hasRotate) {
      iconWidget = RotationTransition(
        turns: _rotationController,
        child: iconWidget,
      );
    }

    if (tier.hasPulse) {
      iconWidget = ScaleTransition(
        scale: _pulseAnimation,
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: _showMilestonesDialog,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: tier.glowColor.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: tier.glowColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 6),
            Text(
              '$_streakCount',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2E44),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'Days',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestonesPopup extends StatefulWidget {
  final int currentStreak;
  final ValueChanged<int> onStreakChanged;

  const _MilestonesPopup({
    Key? key,
    required this.currentStreak,
    required this.onStreakChanged,
  }) : super(key: key);

  @override
  State<_MilestonesPopup> createState() => _MilestonesPopupState();
}

class _MilestonesPopupState extends State<_MilestonesPopup> with TickerProviderStateMixin {
  late int _localStreak;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _localStreak = widget.currentStreak;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF4FBFE), Color(0xFFEDFDF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Milestones',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A2E44),
                      ),
                    ),
                    Text(
                      'Unlock beautiful badges as you stay devout',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF1A2E44)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: streakTiers.length,
                      itemBuilder: (context, index) {
                        final tier = streakTiers[index];
                        final isUnlocked = _localStreak >= tier.requiredDays;
                        
                        Widget badgeIcon = ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isUnlocked ? tier.colors : [Colors.grey[400]!, Colors.grey[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Icon(
                            tier.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        );

                        if (isUnlocked && tier.hasRotate) {
                          badgeIcon = RotationTransition(
                            turns: _rotationController,
                            child: badgeIcon,
                          );
                        }

                        if (isUnlocked && tier.hasPulse) {
                          badgeIcon = ScaleTransition(
                            scale: _pulseAnimation,
                            child: badgeIcon,
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                title: Row(
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: isUnlocked ? tier.colors : [Colors.grey, Colors.grey],
                                      ).createShader(bounds),
                                      child: Icon(tier.icon, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        tier.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1A2E44),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUnlocked ? 'Status: Unlocked! 🎉' : 'Status: Locked 🔒',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      tier.description,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.grey[800],
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (!isUnlocked)
                                      Text(
                                        'Unlock at Day ${tier.requiredDays} continuous login.',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A2E44),
                                        ),
                                      ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isUnlocked
                                      ? tier.glowColor.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: isUnlocked
                                    ? tier.glowColor.withValues(alpha: 0.3)
                                    : Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                badgeIcon,
                                const SizedBox(height: 8),
                                Text(
                                  tier.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A2E44),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUnlocked ? 'Unlocked!' : 'unlock at day ${tier.requiredDays}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 8.5,
                                    fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
                                    color: isUnlocked ? Colors.green[700] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Dev Simulator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF90BDE7).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, color: Color(0xFF90BDE7), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Dev Simulator Tool',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A2E44),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF90BDE7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_localStreak Days',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A2E44),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF90BDE7),
                      inactiveTrackColor: Colors.grey[200],
                      thumbColor: const Color(0xFF90BDE7),
                      overlayColor: const Color(0xFF90BDE7).withValues(alpha: 0.2),
                      valueIndicatorColor: const Color(0xFF1A2E44),
                      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                    ),
                    child: Slider(
                      value: _localStreak.toDouble().clamp(1, 365),
                      min: 1,
                      max: 365,
                      divisions: 364,
                      label: '$_localStreak Days',
                      onChanged: (val) async {
                        final newStreak = val.round();
                        setState(() {
                          _localStreak = newStreak;
                        });
                        widget.onStreakChanged(newStreak);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('streak_count', newStreak);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [1, 3, 5, 7, 10, 15, 30, 50, 100, 200, 365].map((d) {
                      final isSelected = _localStreak == d;
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            _localStreak = d;
                          });
                          widget.onStreakChanged(d);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('streak_count', d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF90BDE7) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF90BDE7) : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            'Day $d',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF1A2E44),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
