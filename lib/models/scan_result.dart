import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TextHighlight — one token/phrase with its fake-score from the backend
// ---------------------------------------------------------------------------
class TextHighlight extends Equatable {
  final String text;
  final double score; // 0.0 = strongly real, 1.0 = strongly fake
  final String label; // "fake" | "real" | "neutral"

  const TextHighlight({
    required this.text,
    required this.score,
    required this.label,
  });

  factory TextHighlight.fromJson(Map<String, dynamic> json) => TextHighlight(
        text: json['text'] as String,
        score: (json['score'] as num).toDouble(),
        label: json['label'] as String,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'score': score,
        'label': label,
      };

  @override
  List<Object?> get props => [text, score, label];
}

// ---------------------------------------------------------------------------
// ScanResult — extended with highlight + probability fields
// ---------------------------------------------------------------------------
class ScanResult extends Equatable {
  final String id;
  final String text;
  final bool isFake;
  final double confidence;
  final DateTime timestamp;

  // ── New fields ────────────────────────────────────────────────────────────
  /// Probability that the content is fake (0.0–1.0).
  /// Derived from [isFake] + [confidence] when not supplied directly.
  final double fakeProb;

  /// Probability that the content is real (0.0–1.0).
  final double realProb;

  /// When the analysis was performed (defaults to [timestamp]).
  final DateTime analyzedAt;

  /// Per-token highlight data returned by the backend LIME/SHAP step.
  /// Empty list = backend did not return highlights (graceful fallback).
  final List<TextHighlight> highlights;

  // ── Constructor ───────────────────────────────────────────────────────────
  ScanResult({
    required this.id,
    required this.text,
    required this.isFake,
    required this.confidence,
    required this.timestamp,
    List<TextHighlight>? highlights,
    double? fakeProb,
    double? realProb,
    DateTime? analyzedAt,
  })  : highlights = highlights ?? const [],
        // If fakeProb/realProb not supplied, derive from existing fields
        fakeProb = fakeProb ?? (isFake ? confidence : 1.0 - confidence),
        realProb = realProb ?? (isFake ? 1.0 - confidence : confidence),
        analyzedAt = analyzedAt ?? timestamp;

  // ── Existing getters (unchanged) ──────────────────────────────────────────
  String get label => isFake ? 'FAKE NEWS' : 'REAL NEWS';

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  String get confidenceLevel {
    if (confidence >= 0.85) return 'High Confidence';
    if (confidence >= 0.65) return 'Moderate Confidence';
    return 'Low Confidence';
  }

  String get preview =>
      text.length > 100 ? '${text.substring(0, 100)}...' : text;

  // ── New getters (used by ResultScreen) ────────────────────────────────────
  String get confidenceLabel {
    final score = fakeProb * 100;
    if (score < 35) return 'High Confidence (Real)';
    if (score < 55) return 'Low Confidence';
    if (score < 75) return 'Moderate Confidence (Fake)';
    return 'High Confidence (Fake)';
  }

  Color confidenceLabelColor(BuildContext context) {
    final score = fakeProb * 100;
    if (score < 35) return const Color(0xFF2E7D32);
    if (score < 55) return const Color(0xFFB57B00);
    return const Color(0xFFC62828);
  }

  // ── SQLite serialisation ──────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isFake': isFake ? 1 : 0,
        'confidence': confidence,
        'timestamp': timestamp.millisecondsSinceEpoch,
        // New columns — store highlights as a JSON string
        'fakeProb': fakeProb,
        'realProb': realProb,
        'analyzedAt': analyzedAt.millisecondsSinceEpoch,
        'highlights': jsonEncode(highlights.map((h) => h.toJson()).toList()),
      };

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    // Parse highlights — gracefully handles missing column (older DB rows)
    List<TextHighlight> highlights = [];
    final rawHighlights = map['highlights'];
    if (rawHighlights != null && rawHighlights is String && rawHighlights.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawHighlights) as List<dynamic>;
        highlights = decoded
            .map((e) => TextHighlight.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        highlights = [];
      }
    }

    final isFake = map['isFake'] == 1;
    final confidence = map['confidence'] as double;

    return ScanResult(
      id: map['id'] as String,
      text: map['text'] as String,
      isFake: isFake,
      confidence: confidence,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      highlights: highlights,
      fakeProb: map['fakeProb'] != null
          ? (map['fakeProb'] as num).toDouble()
          : (isFake ? confidence : 1.0 - confidence),
      realProb: map['realProb'] != null
          ? (map['realProb'] as num).toDouble()
          : (isFake ? 1.0 - confidence : confidence),
      analyzedAt: map['analyzedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['analyzedAt'] as int)
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  // ── CopyWith ──────────────────────────────────────────────────────────────
  ScanResult copyWith({
    String? id,
    String? text,
    bool? isFake,
    double? confidence,
    DateTime? timestamp,
    List<TextHighlight>? highlights,
    double? fakeProb,
    double? realProb,
    DateTime? analyzedAt,
  }) =>
      ScanResult(
        id: id ?? this.id,
        text: text ?? this.text,
        isFake: isFake ?? this.isFake,
        confidence: confidence ?? this.confidence,
        timestamp: timestamp ?? this.timestamp,
        highlights: highlights ?? this.highlights,
        fakeProb: fakeProb ?? this.fakeProb,
        realProb: realProb ?? this.realProb,
        analyzedAt: analyzedAt ?? this.analyzedAt,
      );

  @override
  List<Object?> get props =>
      [id, text, isFake, confidence, timestamp, fakeProb, realProb, analyzedAt, highlights];

  @override
  String toString() =>
      'ScanResult(id: $id, isFake: $isFake, fakeProb: $fakeProb, highlights: ${highlights.length})';
}