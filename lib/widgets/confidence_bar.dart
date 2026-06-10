// lib/widgets/confidence_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/scan_result.dart';
import '../utils/app_colors.dart';

class ConfidenceBar extends StatelessWidget {
  final ScanResult result;

  const ConfidenceBar({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color  ?? AppColors.textPrimary;
    final textSecond  = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    final textHint    = Theme.of(context).textTheme.bodySmall?.color  ?? AppColors.textHint;
    final barBg       = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100;

    final color   = result.isFake ? AppColors.fake : AppColors.real;
    // In dark mode use a darker tint so the badge doesn't glare
    final bgColor = result.isFake
        ? (isDark ? const Color(0xFF4A1010) : AppColors.fakeLight)
        : (isDark ? const Color(0xFF0D3320) : AppColors.realLight);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 18, color: textSecond),
                  const SizedBox(width: 8),
                  Text('Confidence Score',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                ],
              ),
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.confidencePercent,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: result.confidence),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: barBg,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 12,
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Scale labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%',
                  style: TextStyle(fontSize: 11, color: textHint)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.confidenceLevel,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              Text('100%',
                  style: TextStyle(fontSize: 11, color: textHint)),
            ],
          ),

          const SizedBox(height: 16),

          _buildScoreRow(
            context: context,
            label: 'Fake Probability',
            value: result.isFake ? result.confidence : 1 - result.confidence,
            color: AppColors.fake,
            barBg: barBg,
            textSecond: textSecond,
          ),

          const SizedBox(height: 8),

          _buildScoreRow(
            context: context,
            label: 'Real Probability',
            value: result.isFake ? 1 - result.confidence : result.confidence,
            color: AppColors.real,
            barBg: barBg,
            textSecond: textSecond,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildScoreRow({
    required BuildContext context,
    required String label,
    required double value,
    required Color color,
    required Color barBg,
    required Color textSecond,
  }) {
    final percent = (value * 100).toStringAsFixed(1);

    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: textSecond)),
        ),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: barBg,
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.5)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}