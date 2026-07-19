// lib/utils/history_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_result.dart';
import '../utils/app_colors.dart';

class HistoryTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryTile({
    super.key,
    required this.result,
    required this.onTap,
    required this.onDelete,
  });

  // ── Verdict colours ───────────────────────────────────────────────────
  Color _labelColor(bool isDark) {
    switch (result.verdict) {
      case Verdict.fake:
        return AppColors.fake;
      case Verdict.real:
        return AppColors.real;
      case Verdict.uncertain:
        return AppColors.warning;
    }
  }

  Color _labelBg(bool isDark) {
    switch (result.verdict) {
      case Verdict.fake:
        return isDark ? const Color(0xFF4A1010) : AppColors.fakeLight;
      case Verdict.real:
        return isDark ? const Color(0xFF0D3320) : AppColors.realLight;
      case Verdict.uncertain:
        return isDark ? const Color(0xFF3D2800) : AppColors.warningLight;
    }
  }

  IconData _labelIcon() {
    switch (result.verdict) {
      case Verdict.fake:      return Icons.cancel_outlined;
      case Verdict.real:      return Icons.check_circle_outline;
      case Verdict.uncertain: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final surface     = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color  ?? AppColors.textPrimary;
    final textSecond  = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    final textHint    = Theme.of(context).textTheme.bodySmall?.color  ?? AppColors.textHint;

    final labelColor  = _labelColor(isDark);
    final labelBg     = _labelBg(isDark);
    final formatted   = DateFormat('dd MMM yyyy, hh:mm a').format(result.timestamp);
    final confidence  = (result.confidence * 100).toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: verdict + confidence + delete ────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: labelBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_labelIcon(), size: 13, color: labelColor),
                        const SizedBox(width: 4),
                        Text(
                          result.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$confidence%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecond,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.fake.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.fake),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Text preview ──────────────────────────────────────────
              Text(
                result.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, color: textPrimary, height: 1.5),
              ),

              const SizedBox(height: 10),

              // ── Mini progress bar ─────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.confidence,
                  backgroundColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(labelColor),
                  minHeight: 4,
                ),
              ),

              const SizedBox(height: 10),

              // ── Bottom row: timestamp + confidence level ───────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: textHint),
                      const SizedBox(width: 4),
                      Text(formatted,
                          style:
                              TextStyle(fontSize: 11, color: textHint)),
                    ],
                  ),
                  Text(
                    result.confidenceLevel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}