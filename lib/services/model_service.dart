// lib/services/model_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';
import '../cubits/scan/scan_state.dart';
import 'package:uuid/uuid.dart';

class ApiException implements Exception {
  final String message;
  final ScanErrorType type;
  const ApiException(this.message, this.type);

  @override
  String toString() => message;
}

class ModelService extends ChangeNotifier {
  static const String _baseUrl = "https://maddane-verilens-ai.hf.space";
  static const int maxChars = 5000;
  static const int minChars = 10;

  bool _isLoaded = false;
  bool _hasError = false;
  String? _errorMessage;
  ScanErrorType? _errorType;

  bool get isLoaded        => _isLoaded;
  bool get hasError        => _hasError;
  String? get errorMessage => _errorMessage;
  ScanErrorType? get errorType => _errorType;

  // ── Initialize ────────────────────────────────────────────────────────
  Future<void> loadModel() async {
    debugPrint("📦 Checking API health...");
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/health"))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint("✅ API ready — device: ${body['device']}");
        _isLoaded     = true;
        _hasError     = false;
        _errorMessage = null;
        _errorType    = null;
      } else {
        throw ApiException(
            "Server returned status ${response.statusCode}",
            ScanErrorType.server);
      }
    } on SocketException {
      _setError("No internet connection. Please check your network.",
          ScanErrorType.offline);
    } on TimeoutException {
      _setError("Connection timed out. The server may be unavailable.",
          ScanErrorType.timeout);
    } on ApiException catch (e) {
      _setError(e.message, e.type);
    } catch (e) {
      _setError("Could not reach the server. Please try again.",
          ScanErrorType.server);
    }
    notifyListeners();
  }

  Future<void> retry() => loadModel();

  // ── Parse highlights helper ───────────────────────────────────────────
  List<TextHighlight> _parseHighlights(dynamic raw) {
    if (raw == null || raw is! List) return [];
    try {
      return (raw as List)
          .map((h) => TextHighlight.fromJson(h as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("⚠️ Failed to parse highlights: $e");
      return [];
    }
  }

  // ── Predict (text) ────────────────────────────────────────────────────
  Future<ScanResult> predict(String rawText) async {
    debugPrint("🔥 predict() called, isLoaded=$_isLoaded");

    if (!_isLoaded) {
      throw ApiException(
          'Server not reachable — please check your connection.',
          ScanErrorType.offline);
    }

    final trimmed = rawText.trim();
    if (trimmed.length > maxChars) {
      throw ApiException(
          'Text is too long (${trimmed.length} chars). '
          'Please shorten to $maxChars characters or fewer.',
          ScanErrorType.input);
    }

    final t0 = DateTime.now();

    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/predict"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": rawText}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        String errorMsg = "Server error (${response.statusCode})";
        try {
          final body = jsonDecode(response.body);
          errorMsg = body["error"] ?? errorMsg;
        } catch (_) {}
        throw ApiException(errorMsg, ScanErrorType.server);
      }

      final data         = jsonDecode(response.body);
      final isFake       = data["is_fake"]    as bool;
      final fakeScore    = (data["fake_score"] as num).toDouble();
      final realScore    = (data["real_score"] as num).toDouble();
      final confidence   = (data["confidence"] as num).toDouble();
      final elapsedMs    = data["elapsed_ms"] as int;
      final verdictLabel = data["label"] as String? ??
          (isFake ? 'FAKE' : 'REAL');           // fallback for old backend
      final highlights   = _parseHighlights(data["highlights"]);

      debugPrint(
        "✅ Prediction: $verdictLabel "
        "(fake=$fakeScore, real=$realScore) "
        "highlights=${highlights.length} "
        "in ${DateTime.now().difference(t0).inMilliseconds}ms "
        "(server: ${elapsedMs}ms)",
      );

      return ScanResult(
        id:           const Uuid().v4(),
        text:         rawText,
        isFake:       isFake,
        confidence:   confidence,
        timestamp:    DateTime.now(),
        fakeProb:     fakeScore,
        realProb:     realScore,
        analyzedAt:   DateTime.now(),
        highlights:   highlights,
        verdictLabel: verdictLabel,
      );

    } on SocketException {
      throw ApiException(
          'No internet connection. Please check your network and try again.',
          ScanErrorType.offline);
    } on TimeoutException {
      throw ApiException(
          'The request timed out. The server may be overloaded — please try again shortly.',
          ScanErrorType.timeout);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint("❌ predict() unexpected error: $e");
      throw ApiException(
          'Something went wrong. Please try again.', ScanErrorType.server);
    }
  }

  // ── Scan URL ──────────────────────────────────────────────────────────
  Future<ScanResult> scanUrl(String url) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/predict_url'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'url': url}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw ApiException(
          err['error'] ?? 'URL scan failed', ScanErrorType.server);
    }

    final data         = jsonDecode(response.body);
    final isFake       = data["is_fake"]    as bool;
    final fakeScore    = (data["fake_score"] as num).toDouble();
    final realScore    = (data["real_score"] as num).toDouble();
    final confidence   = (data["confidence"] as num).toDouble();
    final verdictLabel = data["label"] as String? ??
        (isFake ? 'FAKE' : 'REAL');
    final highlights   = _parseHighlights(data["highlights"]);

    final displayText = _firstNonEmpty([
      data["article_text_for_model"] as String?,
      data["article_snippet"]        as String?,
      url,
    ]);

    debugPrint(
      "✅ URL Prediction: $verdictLabel "
      "(fake=$fakeScore, real=$realScore) "
      "highlights=${highlights.length} "
      "displayText=${displayText.length} chars",
    );

    return ScanResult(
      id:           const Uuid().v4(),
      text:         displayText,
      isFake:       isFake,
      confidence:   confidence,
      timestamp:    DateTime.now(),
      fakeProb:     fakeScore,
      realProb:     realScore,
      analyzedAt:   DateTime.now(),
      highlights:   highlights,
      verdictLabel: verdictLabel,
    );
  }

  String _firstNonEmpty(List<String?> candidates) {
    for (final s in candidates) {
      if (s != null && s.trim().isNotEmpty) return s;
    }
    return '';
  }

  void _setError(String message, ScanErrorType type) {
    _hasError     = true;
    _errorMessage = message;
    _errorType    = type;
    _isLoaded     = false;
  }

  @override
  void dispose() => super.dispose();
}