import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Navigate after 2.5s
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Background rings
            Center(child: _PulsingRings(controller: _pulseCtrl)),

            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                        'assets/images/logo.png',
                        width: 160,
                        height: 160,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 28),

                  // App name
                  Text(
                        'DERMAVISION',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                          color: AppTheme.textPrimary,
                        ),
                      )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 10),

                  Text(
                    'AI Dermatology Analysis',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                      color: AppTheme.textSecondary,
                    ),
                  ).animate(delay: 350.ms).fadeIn(duration: 600.ms),

                  const SizedBox(height: 60),

                  // Loading indicator
                  const SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.border,
                      color: AppTheme.accent,
                      minHeight: 2,
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // Version tag
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Offline · Private · Secure',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ).animate(delay: 700.ms).fadeIn(duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingRings extends StatelessWidget {
  final AnimationController controller;
  const _PulsingRings({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return SizedBox(
          width: 360,
          height: 360,
          child: CustomPaint(painter: _RingsPainter(t: t)),
        );
      },
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double t;
  _RingsPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final radius = 80.0 + phase * 100.0;
      final opacity = (1.0 - phase) * 0.15;
      final paint = Paint()
        ..color = AppTheme.accent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}
