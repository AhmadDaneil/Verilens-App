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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detection Result'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Verdict Card — unchanged
              VerdictCard(result: result)
                  .animate()
                  .fadeIn()
                  .scale(),

              const SizedBox(height: 20),

              // Confidence Bar — unchanged
              ConfidenceBar(result: result)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),

              // Analyzed Text Card — unchanged
              _buildTextCard()
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),

              // AI Summary Card — now uses real highlights
              _buildAISummaryCard()
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),

              // Timestamp — unchanged
              _buildTimestamp()
                  .animate()
                  .fadeIn(delay: 500.ms),

              const SizedBox(height: 20),

              // Analyze Another Button — unchanged
              _buildAnalyzeAnotherButton(context)
                  .animate()
                  .fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ── Analyzed Text card — unchanged ─────────────────────────────────────
  Widget _buildTextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          const Row(
            children: [
              Icon(Icons.article_outlined, size: 18, color: AppColors.textSecond),
              SizedBox(width: 8),
              Text(
                'Analyzed Text',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.preview,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecond,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Summary card — RichText with real highlighted words ──────────────
  Widget _buildAISummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          const Row(
            children: [
              Icon(Icons.psychology_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'AI Analysis Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRichText(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Powered by DistilBERT + Bi-LSTM hybrid model',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Builds the summary as RichText so flagged words are highlighted ─────
  //
  // If highlights are empty (backend hasn't returned them yet) we fall back
  // to a plain descriptive sentence — never a generic placeholder.
  Widget _buildSummaryRichText() {
    // ── No highlights available ────────────────────────────────────────────
    if (result.highlights.isEmpty) {
      final fallback = result.isFake
          ? 'The model classified this content as likely fake with '
            '${(result.fakeProb * 100).toStringAsFixed(1)}% probability. '
            'No word-level breakdown is available for this result.'
          : 'The model classified this content as likely real with '
            '${(result.realProb * 100).toStringAsFixed(1)}% probability. '
            'No word-level breakdown is available for this result.';
      return Text(
        fallback,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecond,
          height: 1.6,
        ),
      );
    }

    // ── Pick top suspicious and credible words from LIME highlights ────────
    final fakeTokens = result.highlights
        .where((h) => h.label == 'fake' && h.score > 0.6)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final realTokens = result.highlights
        .where((h) => h.label == 'real' && h.score < 0.4)
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    final topFake = fakeTokens.take(3).map((h) => h.text.trim()).toList();
    final topReal = realTokens.take(2).map((h) => h.text.trim()).toList();
    final scorePct = (result.fakeProb * 100).toStringAsFixed(1);

    // ── Assemble sentence parts ────────────────────────────────────────────
    // Each part is plain text OR a highlighted word (red=fake, green=real).
    final List<_Part> parts = [];

    void plain(String t) {
      if (t.isNotEmpty) parts.add(_Part(t));
    }

    void words(List<String> ws, {required bool isFake, required String sep}) {
      for (int i = 0; i < ws.length; i++) {
        parts.add(_Part('"${ws[i]}"', isFake: isFake));
        if (i < ws.length - 1) plain(sep);
      }
    }

    if (result.fakeProb >= 0.55) {
      plain('The model flagged this as likely misleading ($scorePct% fake). ');
      if (topFake.isNotEmpty) {
        plain('The word${topFake.length > 1 ? 's' : ''} ');
        words(topFake, isFake: true, sep: ', ');
        plain(
          ' ${topFake.length > 1 ? 'push' : 'pushes'} the score toward fake'
          ' — ${topFake.length > 1 ? 'they carry' : 'it carries'} emotional,'
          ' sensational, or speculative language uncommon in factual reporting. ',
        );
      }
      if (topReal.isNotEmpty) {
        plain('In contrast, ');
        words(topReal, isFake: false, sep: ' and ');
        plain(
          ' ${topReal.length == 1 ? 'pulls' : 'pull'} the score toward real'
          ' — ${topReal.length == 1 ? 'it uses' : 'they use'} neutral,'
          ' factual language that reduced the overall fake score.',
        );
      }
      if (topFake.isEmpty && topReal.isEmpty) {
        plain(
          'The model found subtle linguistic patterns associated with'
          ' misinformation throughout the text.',
        );
      }
    } else if (result.fakeProb <= 0.45) {
      plain('The model considers this content likely credible ($scorePct% fake). ');
      if (topReal.isNotEmpty) {
        plain('The word${topReal.length > 1 ? 's' : ''} ');
        words(topReal, isFake: false, sep: ', ');
        plain(
          ' ${topReal.length > 1 ? 'anchor' : 'anchors'} the real score —'
          ' ${topReal.length > 1 ? 'they use' : 'it uses'} neutral, factual'
          ' language consistent with credible journalism. ',
        );
      }
      if (topFake.isNotEmpty) {
        plain('However, ');
        words(topFake, isFake: true, sep: ' and ');
        plain(
          ' ${topFake.length == 1 ? 'carries' : 'carry'} slightly charged'
          ' language — exercise caution with'
          ' ${topFake.length == 1 ? 'that phrase' : 'those phrases'}.',
        );
      }
      if (topReal.isEmpty && topFake.isEmpty) {
        plain(
          'The overall tone and structure align with factual reporting,'
          ' though always verify from multiple sources.',
        );
      }
    } else {
      plain('The model is uncertain ($scorePct% — near 50/50). ');
      if (topFake.isNotEmpty) {
        words(topFake, isFake: true, sep: ' and ');
        plain(
          ' ${topFake.length == 1 ? 'leans' : 'lean'} toward misinformation',
        );
        plain(topReal.isNotEmpty ? ', while ' : '. ');
      }
      if (topReal.isNotEmpty) {
        words(topReal, isFake: false, sep: ' and ');
        plain(
          ' ${topReal.length == 1 ? 'reads' : 'read'} as more credible. ',
        );
      }
      plain('Cross-check with a trusted source before sharing.');
    }

    // ── Render parts as a RichText ─────────────────────────────────────────
    final spans = parts.map((p) {
      if (p.isFake == true) {
        return TextSpan(
          text: p.text,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
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
            fontSize: 13,
            height: 1.6,
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w700,
            backgroundColor: Color(0xFFC8E6C9),
          ),
        );
      }
      return TextSpan(
        text: p.text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecond,
          height: 1.6,
        ),
      );
    }).toList();

    return RichText(text: TextSpan(children: spans));
  }

  // ── Timestamp — unchanged ───────────────────────────────────────────────
  Widget _buildTimestamp() {
    final formatted =
        DateFormat('dd MMM yyyy, hh:mm a').format(result.timestamp);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.access_time, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          'Analyzed on $formatted',
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }

  // ── Analyze Another button — unchanged ─────────────────────────────────
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
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── Internal helper — one piece of the summary sentence ─────────────────────
class _Part {
  final String text;
  final bool? isFake; // true = red, false = green, null = plain

  const _Part(this.text, {this.isFake});
}