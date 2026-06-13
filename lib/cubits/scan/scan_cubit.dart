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

  Future<void> analyzeText(String text) async {
    // ── Input validation ──────────────────────────────────────────────
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

    // Non-English detection: flag if fewer than 30% of characters are
    // ASCII letters/digits/punctuation. This catches CJK, Arabic, Cyrillic,
    // etc. without pulling in a language detection library.
    if (_likelyNonEnglish(trimmed)) {
      emit(const ScanError(
        message: 'ScamShield is optimised for English text. '
            'Results for other languages may not be reliable.',
        errorType: ScanErrorType.input,
      ));
      return;
    }

    // ── Network call ──────────────────────────────────────────────────
    emit(ScanLoading());
    try {
      final result = await modelService.predict(text);
      await _databaseService.insertScan(result);
      emit(ScanSuccess(result: result));
    } on ApiException catch (e) {
      emit(ScanError(message: e.message, errorType: e.type));
    } catch (e, stackTrace) {
      debugPrint("🔥 Unexpected error: $e\n$stackTrace");
      emit(ScanError(
        message: 'Something went wrong. Please try again.',
        errorType: ScanErrorType.server,
      ));
    }
  }

  // Returns true if the text appears to be predominantly non-English.
  // Heuristic: if over 40% of non-whitespace chars are outside the
  // printable ASCII range (0x20–0x7E), it's likely non-Latin script.
  bool _likelyNonEnglish(String text) {
    final chars = text.replaceAll(RegExp(r'\s'), '');
    if (chars.isEmpty) return false;

    final nonAscii = chars.codeUnits
        .where((c) => c > 0x7E || c < 0x20)
        .length;

    return (nonAscii / chars.length) > 0.40;
  }

  void reset() => emit(ScanInitial());

 Future<void> retryAndAnalyze(String text) async {
  emit(ScanLoading());
  await modelService.loadModel();
  if (modelService.isLoaded) {
    await analyzeText(text);
  } else {
    emit(ScanError(
      message: modelService.errorMessage ?? 'Still unreachable. Please try again.',
      errorType: modelService.errorType ?? ScanErrorType.offline,
    ));
  }
}
}