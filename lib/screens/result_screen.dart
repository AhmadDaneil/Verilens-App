// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/scan_result.dart';
import '../utils/app_colors.dart';
import '../widgets/verdict_card.dart';
import '../widgets/confidence_bar.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Result')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              VerdictCard(result: result).animate().fadeIn().scale(),
              const SizedBox(height: 20),
              ConfidenceBar(result: result)
                  .animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 20),
              _buildTextCard(context)
                  .animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 20),
              _buildAISummaryCard(context)
                  .animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 20),
              _buildTimestamp(context).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 20),
              _buildAnalyzeAnotherButton(context)
                  .animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ── Theme helpers ─────────────────────────────────────────────────────
  Color _surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  Color _textPrimary(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
  Color _textSecond(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
  Color _textHint(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textHint;

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ── Analyzed Text card ────────────────────────────────────────────────
  Widget _buildTextCard(BuildContext context) {
    final neutralColor = _textSecond(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.article_outlined,
                  size: 18, color: _textSecond(context)),
              const SizedBox(width: 8),
              Text(
                'Analyzed Text',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend — only when highlights exist
          if (result.highlights.isNotEmpty) ...[
            Row(
              children: [
                _legendChip(context, const Color(0xFFFFCDD2),
                    const Color(0xFFC62828), 'Suspicious'),
                const SizedBox(width: 10),
                _legendChip(context, const Color(0xFFC8E6C9),
                    const Color(0xFF2E7D32), 'Credible'),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // ── Highlighted text ────────────────────────────────────────
          if (result.highlights.isNotEmpty)
            Text.rich(
              TextSpan(
                // default style so neutral tokens inherit correct colour
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: neutralColor,
                ),
                children: result.highlights.map((h) {
                  if (h.label == 'fake') {
                    return TextSpan(
                      text: h.text,
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                        backgroundColor: Color(0xFFFFCDD2),
                      ),
                    );
                  }
                  if (h.label == 'real') {
                    return TextSpan(
                      text: h.text,
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w700,
                        backgroundColor: Color(0xFFC8E6C9),
                      ),
                    );
                  }
                  // neutral — inherits parent style (correct dark/light color)
                  return TextSpan(text: h.text);
                }).toList(),
              ),
            )
          else
            Text(
              result.text,
              style: TextStyle(
                fontSize: 13,
                color: neutralColor,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendChip(
      BuildContext context, Color bg, Color fg, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: fg.withOpacity(0.5)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: _textSecond(context))),
      ],
    );
  }

  // ── AI Summary card ───────────────────────────────────────────────────
  Widget _buildAISummaryCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryLight =
        isDark ? const Color(0xFF1A3A6B) : AppColors.primaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'AI Analysis Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRichText(context),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Powered by DistilBERT + Bi-LSTM hybrid model',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRichText(BuildContext context) {
    final neutralColor = _textSecond(context);

    // ── No highlights fallback ──────────────────────────────────────────
    if (result.highlights.isEmpty) {
      final fallback = result.isFake
          ? 'The model classified this content as likely fake with a '
              '${(result.fakeProb * 100).toStringAsFixed(1)}% fake probability. '
              'Word-level analysis was not available for this result.'
          : 'The model classified this content as likely real with a '
              '${(result.realProb * 100).toStringAsFixed(1)}% real probability. '
              'Word-level analysis was not available for this result.';
      return Text(fallback,
          style: TextStyle(
              fontSize: 13, color: neutralColor, height: 1.6));
    }

    // ── Top fake / real words ───────────────────────────────────────────
    final fakeTokens = result.highlights
        .where((h) => h.label == 'fake')
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final realTokens = result.highlights
        .where((h) => h.label == 'real')
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    final topFake = fakeTokens
        .take(3)
        .map((h) => h.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final topReal = realTokens
        .take(2)
        .map((h) => h.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final scorePct = (result.fakeProb * 100).toStringAsFixed(1);

    // ── Build parts ─────────────────────────────────────────────────────
    final List<_Part> parts = [];
    void plain(String t) {
      if (t.isNotEmpty) parts.add(_Part(t));
    }

    void fakeWords(List<String> ws) {
      for (int i = 0; i < ws.length; i++) {
        parts.add(_Part('"${ws[i]}"', isFake: true));
        if (i < ws.length - 1) plain(', ');
      }
    }

    void realWords(List<String> ws) {
      for (int i = 0; i < ws.length; i++) {
        parts.add(_Part('"${ws[i]}"', isFake: false));
        if (i < ws.length - 1) plain(' and ');
      }
    }

    if (result.fakeProb >= 0.55) {
      plain(
          'The model flagged this content as likely misleading ($scorePct% fake probability). ');
      if (topFake.isNotEmpty) {
        plain('The word${topFake.length > 1 ? 's' : ''} ');
        fakeWords(topFake);
        plain(
            ' ${topFake.length > 1 ? 'push' : 'pushes'} the score toward fake'
            ' — ${topFake.length > 1 ? 'they carry' : 'it carries'} emotional,'
            ' sensational, or speculative language uncommon in factual reporting.');
      }
      if (topReal.isNotEmpty) {
        plain(' In contrast, ');
        realWords(topReal);
        plain(
            ' ${topReal.length == 1 ? 'pulls' : 'pull'} the score toward real'
            ' — ${topReal.length == 1 ? 'it uses' : 'they use'} neutral language'
            ' that reduced the overall fake score.');
      }
      if (topFake.isEmpty) {
        plain(
            'Subtle linguistic patterns associated with misinformation were detected throughout the text.');
      }
    } else if (result.fakeProb <= 0.45) {
      plain(
          'The model considers this content likely credible ($scorePct% fake probability). ');
      if (topReal.isNotEmpty) {
        plain('The word${topReal.length > 1 ? 's' : ''} ');
        realWords(topReal);
        plain(
            ' ${topReal.length > 1 ? 'anchor' : 'anchors'} the real score'
            ' — ${topReal.length > 1 ? 'they use' : 'it uses'} neutral, factual'
            ' language consistent with credible journalism.');
      }
      if (topFake.isNotEmpty) {
        plain(' However, ');
        fakeWords(topFake);
        plain(
            ' ${topFake.length == 1 ? 'carries' : 'carry'} slightly charged'
            ' language — exercise caution with'
            ' ${topFake.length == 1 ? 'that phrase' : 'those phrases'}.');
      }
      if (topReal.isEmpty) {
        plain(
            'The overall tone and structure align with factual reporting, though always verify from multiple sources.');
      }
    } else {
      plain('The model is uncertain ($scorePct% — near 50/50). ');
      if (topFake.isNotEmpty) {
        fakeWords(topFake);
        plain(
            ' ${topFake.length == 1 ? 'leans' : 'lean'} toward misinformation');
        plain(topReal.isNotEmpty ? ', while ' : '. ');
      }
      if (topReal.isNotEmpty) {
        realWords(topReal);
        plain(
            ' ${topReal.length == 1 ? 'reads' : 'read'} as more credible. ');
      }
      plain('Cross-check with a trusted source before sharing.');
    }

    // ── Render as Text.rich so it inherits DefaultTextStyle ─────────────
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: neutralColor, // neutral parts inherit this
        ),
        children: parts.map((p) {
          if (p.isFake == true) {
            return TextSpan(
              text: p.text,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w700,
                backgroundColor: Color(0xFFFFCDD2),
              ),
            );
          }
          if (p.isFake == false) {
            return TextSpan(
              text: p.text,
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w700,
                backgroundColor: Color(0xFFC8E6C9),
              ),
            );
          }
          // plain — inherits parent colour automatically
          return TextSpan(text: p.text);
        }).toList(),
      ),
    );
  }

  // ── Timestamp ─────────────────────────────────────────────────────────
  Widget _buildTimestamp(BuildContext context) {
    final formatted =
        DateFormat('dd MMM yyyy, hh:mm a').format(result.timestamp);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time, size: 14, color: _textHint(context)),
        const SizedBox(width: 4),
        Text(
          'Analyzed on $formatted',
          style: TextStyle(fontSize: 12, color: _textHint(context)),
        ),
      ],
    );
  }

  // ── Analyze Another button ────────────────────────────────────────────
  Widget _buildAnalyzeAnotherButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text(
          'Analyze Another Text',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _Part {
  final String text;
  final bool? isFake;
  const _Part(this.text, {this.isFake});
}