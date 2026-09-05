import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/translated_text.dart';

/// A heavily optimized "Light Glass" / Neumorphic container.
/// Includes an optional `isTransparent` mode with true BackdropFilter for deep glass effects.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color glassColor;
  final EdgeInsetsGeometry? padding;
  final bool isTransparent;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 36,
    this.glassColor = Colors.white,
    this.padding,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to determine if we are in a constrained context.
    // Passing double.infinity to a Stack inside an unconstrained parent (e.g. Row)
    // causes a layout crash. We avoid this by only setting a finite explicit size.
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final resolvedHeight = height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : null);
        return SizedBox(
          width: resolvedWidth,
          height: resolvedHeight,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
          // 1. Base Layer (Solid neumorphic OR True Glass with blur)
          if (!isTransparent)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: const Color(0xFFF0F0F3), // Neumorphic solid base
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(2, 4),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    offset: const Offset(-2, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: glassColor.withValues(alpha: 0.1), // Base tint
                  ),
                ),
              ),
            ),

          // 2. Gradient border layer (top-left = card color, bottom-right = white)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isTransparent ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF0F0F3),
                  isTransparent ? Colors.white.withValues(alpha: 0.0) : Colors.white,
                ],
              ),
              border: isTransparent 
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0)
                  : null,
            ),
          ),

          // 3. Simulated Glass Surface (inset by 1.5px to expose gradient border)
          Positioned(
            left: 1.5, top: 1.5, right: 1.5, bottom: 1.5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius - 1.5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    glassColor.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 4. Content
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
      },
    );
  }
}

class LiquidGlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final Color glassColor;
  final bool isTransparent;

  const LiquidGlassButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.width,
    this.height = 70,
    this.textStyle,
    this.glassColor = Colors.white,
    this.isTransparent = false,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: LiquidGlassContainer(
          width: widget.width, // null means "use available constrained space"
          height: widget.height,
          glassColor: widget.glassColor,
          isTransparent: widget.isTransparent,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                TranslatedText(
                  widget.label,
                  style: widget.textStyle ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C1E),
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
