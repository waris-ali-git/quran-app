import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Animated skeleton card shown while ayah data is streaming in.
/// Mimics the shape of a real [_StandardAyahCard] so the layout doesn't jump.
class SurahSkeletonCard extends StatelessWidget {
  const SurahSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E4DF),
      highlightColor: const Color(0xFFF8F5F0),
      period: const Duration(milliseconds: 1200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar placeholder
              Row(
                children: [
                  _pill(width: 36, height: 20, radius: 10),
                  const Spacer(),
                  _pill(width: 24, height: 24, radius: 12),
                  const SizedBox(width: 8),
                  _pill(width: 24, height: 24, radius: 12),
                  const SizedBox(width: 8),
                  _pill(width: 24, height: 24, radius: 12),
                ],
              ),

              const SizedBox(height: 14),

              // Arabic text placeholder (RTL wide bar)
              Align(
                alignment: Alignment.centerRight,
                child: _pill(width: double.infinity, height: 22, radius: 4),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _pill(width: 220, height: 22, radius: 4),
              ),

              const SizedBox(height: 14),

              // Translation placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pill(width: double.infinity, height: 14, radius: 4),
                    const SizedBox(height: 6),
                    _pill(width: 180, height: 14, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({required double width, required double height, required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Header skeleton (Bismillah area) — plain blank shimmer, no text
class BismillahSkeletonHeader extends StatelessWidget {
  const BismillahSkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E4DF),
      highlightColor: const Color(0xFFF8F5F0),
      period: const Duration(milliseconds: 1200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Container(
            width: 220,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
