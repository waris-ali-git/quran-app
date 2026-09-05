import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/supported_languages.dart';
import '../../../core/state/language_cubit.dart';
import '../../../core/widgets/translated_text.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../home/screens/home_screen.dart';
import '../../quran/services/preferences_service.dart';

part 'onboarding_shared_widgets.dart';
part 'onboarding_page_1_welcome.dart';
part 'onboarding_page_2_tajweed.dart';
part 'onboarding_page_3_preferences.dart';
part 'onboarding_page_4_start.dart';

// ──────────────────────────────────────────────────────────────
// Color Palette  (shared across all onboarding pages)
// ──────────────────────────────────────────────────────────────
const _skyTop    = Color(0xFFE5F1F6); // Softest powder blue
const _skyMid    = Color(0xFFF7FBFC); // Pearl Ice White
const _mintBot   = Color(0xFFEAF6F2); // Softest mint
const _navy      = Color(0xFF1A2E44); // Deep Navy
const _steelBlue = Color(0xFF6B8FB5); // Steel Blue muted
const _carolina  = Color(0xFF90BDE7); // Carolina Blue
const _deepBlue  = Color(0xFF3487D1); // Deep Blue
const _gold      = Color(0xFFF4D03F); // Soft Gold
const _goldDark  = Color(0xFFF39C12); // Amber
const _silverBlue= Color(0xFFB8D9F5); // Silver-Blue (dust)

// ──────────────────────────────────────────────────────────────
// Onboarding Shell  (PageView — 4 pages)
// ──────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();

  void _next() {
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finish() async {
    await PreferencesService().setCompletedOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(), // buttons control nav
        children: [
          _OnboardingWelcomePage(onNext: _next),
          _OnboardingTajweedPage(onNext: _next),
          _OnboardingPreferencesPage(onNext: _next),
          _OnboardingStartPage(onNext: _finish),
        ],
      ),
    );
  }
}
