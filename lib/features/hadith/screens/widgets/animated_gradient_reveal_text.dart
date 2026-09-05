import 'package:flutter/material.dart';

class AnimatedGradientRevealText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color backgroundColor;
  final Color lightBlueColor;
  final Color lightPinkColor;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Duration duration;
  final Duration delay;
  final VoidCallback? onComplete;

  const AnimatedGradientRevealText({
    super.key,
    required this.text,
    required this.style,
    this.backgroundColor = const Color(0xFFF0F7FD),
    this.lightBlueColor = const Color(0xFF80B3E6),
    this.lightPinkColor = const Color(0xFFF48FB1),
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.rtl,
    this.duration = const Duration(milliseconds: 4800),
    this.delay = Duration.zero,
    this.onComplete,
  });

  @override
  State<AnimatedGradientRevealText> createState() =>
      _AnimatedGradientRevealTextState();
}

class _AnimatedGradientRevealTextState
    extends State<AnimatedGradientRevealText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuad,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isFinished = true;
          });
        }
        widget.onComplete?.call();
      }
    });

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once animation finishes, render clean static text with original style
    if (_isFinished) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
      );
    }

    final bool isRtl = widget.textDirection == TextDirection.rtl;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double progress = _animation.value; // 0.0 -> 1.0

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            // Directional sweep: top-right to bottom-left for RTL, top-left to bottom-right for LTR
            final Alignment begin =
                isRtl ? Alignment.topRight : Alignment.topLeft;
            final Alignment end =
                isRtl ? Alignment.bottomLeft : Alignment.bottomRight;

            // Transition band width
            const double band = 0.35;
            final double front = (progress * (1.0 + band * 2.0)) - band;

            final double solidEnd = (front - band).clamp(0.0, 1.0);
            final double blueStop = (front - band * 0.60).clamp(0.0, 1.0);
            final double pinkStop = (front - band * 0.20).clamp(0.0, 1.0);
            final double bgStart = front.clamp(0.0, 1.0);

            final Color targetColor =
                widget.style.color ?? const Color(0xFF1A2E44);
            final Color bg = widget.backgroundColor;

            final List<double> rawStops = [
              0.0,
              solidEnd,
              blueStop,
              pinkStop,
              bgStart,
              1.0,
            ];

            // Ensure stops are strictly monotonically non-decreasing
            final List<double> stops = [];
            double last = 0.0;
            for (final s in rawStops) {
              final val = s < last ? last : s;
              stops.add(val);
              last = val;
            }

            // Exactly TWO gradient colors (Light Blue & Light Pink), starting as background color (invisible)
            final List<Color> colors = [
              targetColor,              // Revealed: Navy Black
              targetColor,              // Up to solidEnd
              widget.lightBlueColor,     // 1. Light Blue (#80B3E6)
              widget.lightPinkColor,     // 2. Light Pink (#F48FB1)
              bg,                        // Unrevealed: Container Background (No white leak!)
              bg,
            ];

            return LinearGradient(
              begin: begin,
              end: end,
              colors: colors,
              stops: stops,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style.copyWith(
              color: Colors.white,
            ),
            textAlign: widget.textAlign,
            textDirection: widget.textDirection,
          ),
        );
      },
    );
  }
}
