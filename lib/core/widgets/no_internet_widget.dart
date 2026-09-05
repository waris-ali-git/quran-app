import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/shared/widgets/custom_button.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  final bool isFullScreen;

  const NoInternetWidget({
    super.key,
    required this.onRetry,
    this.message,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing pulsing Wi-Fi off icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5F1F6), Color(0xFFEAF6F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF90BDE7).withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Color(0xFF6B8FB5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Single English check internet message
            Text(
              'Please check your internet connection & try again',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2E44),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Retry Button
            LiquidGlassButton(
              width: 180,
              height: 54,
              label: 'Retry',
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: Color(0xFF1A2E44),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2E44),
              ),
              glassColor: const Color(0xFF90BDE7),
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );

    if (!isFullScreen) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE5F1F6), // skyTop
              Color(0xFFF7FBFC), // skyMid
              Color(0xFFEAF6F2), // mintBot
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Glassmorphism card for the error content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LiquidGlassContainer(
                    isTransparent: true,
                    glassColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
