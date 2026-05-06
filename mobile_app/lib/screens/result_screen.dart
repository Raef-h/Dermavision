import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/classification_result.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_bar.dart';

class ResultScreenArgs {
  final String imagePath;
  final ClassificationResult result;
  const ResultScreenArgs({required this.imagePath, required this.result});
}

class ResultScreen extends StatelessWidget {
  final ResultScreenArgs args;
  const ResultScreen({super.key, required this.args});

  Color get _riskColor {
    switch (args.result.riskLevel) {
      case RiskLevel.high:
        return AppTheme.danger;
      case RiskLevel.medium:
        return AppTheme.warning;
      case RiskLevel.low:
        return AppTheme.success;
      case RiskLevel.none:
        return AppTheme.safe;
      case RiskLevel.invalid:
        return AppTheme.textMuted;
    }
  }

  String get _riskLabel {
    switch (args.result.riskLevel) {
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MODERATE';
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.none:
        return 'NO RISK';
      case RiskLevel.invalid:
        return 'INVALID';
    }
  }

  IconData get _riskIcon {
    switch (args.result.riskLevel) {
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
      case RiskLevel.medium:
        return Icons.info_outline_rounded;
      case RiskLevel.low:
        return Icons.check_circle_outline_rounded;
      case RiskLevel.none:
        return Icons.shield_outlined;
      case RiskLevel.invalid:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Blurred image background
            _buildBlurredBackground(),
            // Content
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildImageCard(),
                          const SizedBox(height: 20),
                          _buildResultCard(),
                          const SizedBox(height: 16),
                          _buildAlternativesCard(),
                          const SizedBox(height: 16),
                          _buildDisclaimerCard(),
                          const SizedBox(height: 20),
                          _buildScanAgainButton(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.06,
        child: Image.file(File(args.imagePath), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: AppTheme.glassCard(radius: 12),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Analysis Result',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          // Inference time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentGlow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${args.result.inferenceTimeMs}ms',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentLight,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildImageCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(args.imagePath), fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOut);
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _riskColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_riskIcon, color: _riskColor, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      _riskLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _riskColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                args.result.label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Condition name
          Text(
            args.result.displayName,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.1,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideX(begin: -0.05, curve: Curves.easeOut),

          const SizedBox(height: 20),

          // Confidence label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${(args.result.confidence * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Confidence bar
          ConfidenceBar(value: args.result.confidence),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _buildAlternativesCard() {
    if (args.result.topClasses.length <= 1) return const SizedBox.shrink();

    final others = args.result.topClasses.skip(1).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alternatives',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ...others.asMap().entries.map((e) {
            final delay = (e.key * 80).ms;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlternativeRow(score: e.value)
                  .animate(delay: delay + 400.ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, curve: Curves.easeOut),
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 400.ms)
        .slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.medical_information_outlined,
            color: AppTheme.warning,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'For informational purposes only. This analysis is not a medical diagnosis. '
              'Please consult a licensed dermatologist for professional evaluation.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.warning.withValues(alpha: 0.85),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  Widget _buildScanAgainButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              'Scan Again',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }
}

class _AlternativeRow extends StatelessWidget {
  final ClassScore score;
  const _AlternativeRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = score.confidence * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              score.displayName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score.confidence,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation(AppTheme.textMuted),
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}
