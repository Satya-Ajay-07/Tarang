import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AuthShell({
    super.key,
    required this.child,
    this.maxWidth = 480.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient light waves
          Positioned.fill(
            child: Container(
              color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Opacity(
              opacity: isDark ? 0.08 : 0.16,
              child: CustomPaint(
                painter: _AmbientWavePainter(isDark: isDark),
              ),
            ),
          ),
          // Scrollable layout wrapping the card
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isDark ? AppTheme.darkCard : AppTheme.lightCard)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
                            border: Border.all(
                              color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                            ),
                            boxShadow: AppTheme.shadowLg,
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientWavePainter extends CustomPainter {
  final bool isDark;

  const _AmbientWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = (isDark ? AppTheme.waveGradientDark : AppTheme.waveGradient)
          .createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.5,
        size.width * 0.7,
        size.height * 0.3,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AmbientWavePainter old) => old.isDark != isDark;
}
