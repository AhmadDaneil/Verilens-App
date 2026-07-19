// lib/widgets/verdict_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/scan_result.dart';
import '../utils/app_colors.dart';

class VerdictCard extends StatelessWidget {
  final ScanResult result;

  const VerdictCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // ── All visual properties driven by Verdict enum ──────────────────
    final Color color;
    final IconData icon;
    final String label;
    final String subtitle;

    switch (result.verdict) {
      case Verdict.fake:
        color    = AppColors.fake;
        icon     = Icons.dangerous;
        label    = 'FAKE NEWS';
        subtitle = 'This content shows signs of misinformation';
        break;
      case Verdict.real:
        color    = AppColors.real;
        icon     = Icons.verified;
        label    = 'REAL NEWS';
        subtitle = 'This content appears to be credible';
        break;
      case Verdict.uncertain:
        color    = AppColors.warning;
        icon     = Icons.help_outline_rounded;
        label    = 'UNCERTAIN';
        subtitle = 'The model could not determine this with confidence — '
            'verify from multiple sources before sharing';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated icon
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.white),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.08, 1.08),
                duration: 1200.ms,
              ),

          const SizedBox(height: 16),

          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Confidence badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_outlined,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${result.confidencePercent} — ${result.confidenceLevel}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Extra note for uncertain verdict
          if (result.verdict == Verdict.uncertain) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    'fake score: ${(result.fakeProb * 100).toStringAsFixed(1)}% '
                    '· real score: ${(result.realProb * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}