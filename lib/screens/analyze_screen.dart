// lib/screens/analyze_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubits/scan/scan_cubit.dart';
import '../cubits/scan/scan_state.dart';
import '../services/model_service.dart';
import '../utils/app_colors.dart';
import 'result_screen.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  static const int _maxChars = ModelService.maxChars;
  static const int _warnThreshold = _maxChars - 200;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listener: (context, state) {
        if (state is ScanSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(result: state.result),
            ),
          );
        }
        if (state is ScanError &&
            state.errorType != ScanErrorType.offline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: _snackbarColor(state.errorType),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        // ── Detect whether current input is a URL — drives button/hint text
        final isUrlInput =
            context.read<ScanCubit>().isUrl(_textController.text);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                if (state is ScanError &&
                    state.errorType == ScanErrorType.offline)
                  _buildOfflineBanner(context)
                      .animate()
                      .fadeIn()
                      .slideY(begin: -0.2, end: 0),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context).animate().fadeIn(),
                        const SizedBox(height: 24),
                        _buildInfoCard(context).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 20),
                        _buildTextInput(context).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 8),
                        if (isUrlInput)
                          _buildUrlBadge(context).animate().fadeIn()
                        else
                          _buildCharCounter(context).animate().fadeIn(delay: 250.ms),
                        const SizedBox(height: 8),
                        _buildActionButtons(context).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 24),
                        _buildAnalyzeButton(context, state, isUrlInput)
                            .animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 20),
                        _buildTipsSection(context).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── URL detected badge (replaces char counter when input is a URL) ────
  Widget _buildUrlBadge(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.link, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        const Text(
          'URL detected — the article text will be extracted',
          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Offline banner ────────────────────────────────────────────────────
  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.fake.withOpacity(0.10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.fake, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No connection to the server.\nCheck your network or try again.',
              style: TextStyle(fontSize: 13, color: AppColors.fake, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context
                .read<ScanCubit>()
                .retryAndAnalyze(_textController.text),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.fake,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.fake),
              ),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Character counter ─────────────────────────────────────────────────
  Widget _buildCharCounter(BuildContext context) {
    final length = _textController.text.length;
    final Color color;
    if (length > _maxChars) {
      color = AppColors.fake;
    } else if (length >= _warnThreshold) {
      color = Colors.orange;
    } else {
      color = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    }

    return Row(
      children: [
        Text('$length / $_maxChars characters',
            style: TextStyle(fontSize: 12, color: color)),
        if (length > _maxChars) ...[
          const SizedBox(width: 6),
          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.fake),
          const SizedBox(width: 4),
          Text(
            'Too long — shorten by ${length - _maxChars} chars',
            style: const TextStyle(fontSize: 12, color: AppColors.fake),
          ),
        ],
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final textSecond  = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analyze News',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 4),
        Text(
          'Paste a news article or article URL below to detect if it\'s fake or real.',
          style: TextStyle(fontSize: 14, color: textSecond),
        ),
      ],
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'VeriLens uses DistilBERT + Bi-LSTM to analyze text patterns and detect misinformation. Paste a URL and we\'ll extract the article for you.',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Text input ────────────────────────────────────────────────────────
  Widget _buildTextInput(BuildContext context) {
    final theme   = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final textSecond  = theme.textTheme.bodyMedium?.color ?? AppColors.textSecond;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: 10,
        minLines: 6,
        maxLength: _maxChars,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        decoration: InputDecoration(
          counterText: '',
          hintText:
              'Paste a news article, headline, or article URL...\n\n'
              'ATTENTION!\n'
              'The result from of real or fake news of this app is not 100% accurate.\n'
              'Please trust at your own discretion and verify the information from other sources.',
          hintStyle: TextStyle(color: textSecond, fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: surface,
        ),
        style: TextStyle(fontSize: 15, color: textPrimary, height: 1.5),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    return Row(
      children: [
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _onPaste,
          icon: const Icon(Icons.content_paste, size: 16),
          label: const Text('Paste'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _textController.text.isEmpty ? null : _onClear,
          icon: const Icon(Icons.clear, size: 16),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecond,
            side: BorderSide(color: divider),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ── Analyze button ────────────────────────────────────────────────────
  Widget _buildAnalyzeButton(BuildContext context, ScanState state, bool isUrlInput) {
    final isLoading = state is ScanLoading;
    final trimmed   = _textController.text.trim();
    final length    = trimmed.length;

    // For URLs, only require non-empty; for text, enforce min/max chars
    final hasValidInput = isUrlInput
        ? trimmed.isNotEmpty
        : (length >= ModelService.minChars && length <= _maxChars);

    final isOffline = state is ScanError && state.errorType == ScanErrorType.offline;
    final enabled   = !isLoading && hasValidInput && !isOffline;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? _onAnalyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Theme.of(context).disabledColor.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: enabled ? 2 : 0,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isUrlInput ? 'Extracting & analyzing...' : 'Analyzing...',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isUrlInput ? Icons.link : Icons.document_scanner, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isUrlInput ? 'Analyze URL' : 'Analyze Text',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Tips section ──────────────────────────────────────────────────────
  Widget _buildTipsSection(BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final textSecond  = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tips for best results',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 12),
        _buildTip(context, icon: Icons.link,
            text: 'Paste a full article URL and we\'ll extract the text for you'),
        _buildTip(context, icon: Icons.text_fields,
            text: 'Or paste the full headline and first few paragraphs directly'),
        _buildTip(context, icon: Icons.translate,
            text: 'English content only — other languages may give unreliable results'),
        _buildTip(context, icon: Icons.wb_sunny_outlined,
            text: 'Minimum ${ModelService.minChars} characters required for text analysis'),
      ],
    );
  }

  Widget _buildTip(BuildContext context, {required IconData icon, required String text}) {
    final textSecond = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textSecond),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: textSecond)),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────
  Future<void> _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        final pasted = data!.text!;
        _textController.text = pasted.length > _maxChars
            ? pasted.substring(0, _maxChars)
            : pasted;
      });
    }
  }

  void _onClear() {
    setState(() => _textController.clear());
    context.read<ScanCubit>().reset();
  }

  // ── Routes to text or URL analysis automatically ───────────────────────
  void _onAnalyze() {
    FocusScope.of(context).unfocus();
    context.read<ScanCubit>().analyzeInput(_textController.text);
  }

  Color _snackbarColor(ScanErrorType type) {
    switch (type) {
      case ScanErrorType.timeout: return Colors.orange.shade700;
      case ScanErrorType.input:   return Colors.blueGrey.shade600;
      case ScanErrorType.server:
      case ScanErrorType.offline: return AppColors.fake;
    }
  }
}