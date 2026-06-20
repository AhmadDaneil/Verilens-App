// lib/cubits/scan/scan_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'scan_state.dart';
import 'package:verilens_app/services/model_service.dart';
import 'package:verilens_app/services/database_service.dart';

class ScanCubit extends Cubit<ScanState> {
  final ModelService modelService;
  final DatabaseService _databaseService;

  ScanCubit({
    required ModelService modelService,
    required DatabaseService databaseService,
  })  : modelService = modelService,
        _databaseService = databaseService,
        super(ScanInitial());

  // Matches http:// or https:// URLs anywhere in the trimmed input,
  // and requires the ENTIRE trimmed string to be just the URL (no
  // surrounding sentence) so pasted article text containing a link
  // inside it doesn't get misclassified as a URL-only scan.
  static final RegExp _urlPattern = RegExp(
    r'^https?:\/\/[^\s]+$',
    caseSensitive: false,
  );

  bool isUrl(String text) => _urlPattern.hasMatch(text.trim());

  // ── Main entry point — routes to text or URL analysis ────────────────
  Future<void> analyzeInput(String input) async {
    final trimmed = input.trim();

    if (isUrl(trimmed)) {
      await analyzeUrl(trimmed);
    } else {
      await analyzeText(trimmed);
    }
  }

  // ── Text analysis (unchanged logic, renamed call site) ────────────────
  Future<void> analyzeText(String text) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      emit(const ScanError(
        message: 'Please enter some text to analyze.',
        errorType: ScanErrorType.input,
      ));
      return;
    }

    if (trimmed.length < ModelService.minChars) {
      emit(const ScanError(
        message: 'Text is too short. Please enter at least '
            '${ModelService.minChars} characters.',
        errorType: ScanErrorType.input,
      ));
      return;
    }

    if (trimmed.length > ModelService.maxChars) {
      emit(ScanError(
        message: 'Text is too long (${trimmed.length} chars). '
            'Please shorten to ${ModelService.maxChars} characters or fewer.',
        errorType: ScanErrorType.input,
      ));
      return;
    }

    if (_likelyNonEnglish(trimmed)) {
      emit(const ScanError(
        message: 'VeriLens is optimised for English text. '
            'Results for other languages may not be reliable.',
        errorType: ScanErrorType.input,
      ));
      return;
    }

    emit(ScanLoading());
    try {
      final result = await modelService.predict(trimmed);
      await _databaseService.insertScan(result);
      emit(ScanSuccess(result: result));
    } on ApiException catch (e) {
      emit(ScanError(message: e.message, errorType: e.type));
    } catch (e, stackTrace) {
      debugPrint("🔥 Unexpected error: $e\n$stackTrace");
      emit(const ScanError(
        message: 'Something went wrong. Please try again.',
        errorType: ScanErrorType.server,
      ));
    }
  }

  // ── URL analysis — fetches & extracts article, then predicts ──────────
  Future<void> analyzeUrl(String url) async {
    final trimmed = url.trim();

    if (trimmed.isEmpty) {
      emit(const ScanError(
        message: 'Please enter a URL to analyze.',
        errorType: ScanErrorType.input,
      ));
      return;
    }

    emit(ScanLoading());
    try {
      final result = await modelService.scanUrl(trimmed);
      await _databaseService.insertScan(result);
      emit(ScanSuccess(result: result));
    } on ApiException catch (e) {
      emit(ScanError(message: e.message, errorType: e.type));
    } catch (e, stackTrace) {
      debugPrint("🔥 Unexpected URL scan error: $e\n$stackTrace");
      emit(const ScanError(
        message: 'Could not analyze that URL. Please check the link and try again.',
        errorType: ScanErrorType.server,
      ));
    }
  }

  bool _likelyNonEnglish(String text) {
    final chars = text.replaceAll(RegExp(r'\s'), '');
    if (chars.isEmpty) return false;
    final nonAscii = chars.codeUnits.where((c) => c > 0x7E || c < 0x20).length;
    return (nonAscii / chars.length) > 0.40;
  }

  void reset() => emit(ScanInitial());

  Future<void> retryAndAnalyze(String input) async {
    emit(ScanLoading());
    await modelService.loadModel();
    if (modelService.isLoaded) {
      await analyzeInput(input);
    } else {
      emit(ScanError(
        message: modelService.errorMessage ?? 'Still unreachable. Please try again.',
        errorType: modelService.errorType ?? ScanErrorType.offline,
      ));
    }
  }
}