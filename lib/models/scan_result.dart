// lib/models/scan_result.dart
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TextHighlight
// ---------------------------------------------------------------------------
class TextHighlight extends Equatable {
  final String text;
  final double score;
  final String label; // "fake" | "real" | "neutral"

  const TextHighlight({
    required this.text,
    required this.score,
    required this.label,
  });

  factory TextHighlight.fromJson(Map<String, dynamic> json) => TextHighlight(
        text:  json['text']  as String,
        score: (json['score'] as num).toDouble(),
        label: json['label'] as String,
      );

  Map<String, dynamic> toJson() => {
        'text':  text,
        'score': score,
        'label': label,
      };

  @override
  List<Object?> get props => [text, score, label];
}

// ---------------------------------------------------------------------------
// Verdict enum — three-tier system
// ---------------------------------------------------------------------------
enum Verdict { fake, real, uncertain }

// ---------------------------------------------------------------------------
// ScanResult
// ---------------------------------------------------------------------------
class ScanResult extends Equatable {
  final String id;
  final String text;
  final bool isFake;
  final double confidence;
  final DateTime timestamp;
  final double fakeProb;
  final double realProb;
  final DateTime analyzedAt;
  final List<TextHighlight> highlights;

  /// "FAKE" | "REAL" | "UNCERTAIN" — comes directly from backend label field
  final String verdictLabel;

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
    String? verdictLabel,
  })  : highlights   = highlights ?? const [],
        fakeProb     = fakeProb   ?? (isFake ? confidence : 1.0 - confidence),
        realProb     = realProb   ?? (isFake ? 1.0 - confidence : confidence),
        analyzedAt   = analyzedAt ?? timestamp,
        // Default: derive from isFake if no explicit label supplied
        verdictLabel = verdictLabel ?? (isFake ? 'FAKE' : 'REAL');

  // ── Verdict enum ──────────────────────────────────────────────────────
  Verdict get verdict {
    switch (verdictLabel.toUpperCase()) {
      case 'FAKE':
        return Verdict.fake;
      case 'REAL':
        return Verdict.real;
      default:
        return Verdict.uncertain;
    }
  }

  // ── Display helpers ───────────────────────────────────────────────────
  String get label {
    switch (verdict) {
      case Verdict.fake:      return 'FAKE NEWS';
      case Verdict.real:      return 'REAL NEWS';
      case Verdict.uncertain: return 'UNCERTAIN';
    }
  }

  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  String get confidenceLevel {
    final pct = confidence * 100;
    if (pct >= 85) return 'High Confidence';
    if (pct >= 65) return 'Moderate Confidence';
    return 'Low Confidence';
  }

  String get preview =>
      text.length > 100 ? '${text.substring(0, 100)}...' : text;

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

  // ── SQLite ────────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id':           id,
        'text':         text,
        'isFake':       isFake ? 1 : 0,
        'confidence':   confidence,
        'timestamp':    timestamp.millisecondsSinceEpoch,
        'fakeProb':     fakeProb,
        'realProb':     realProb,
        'analyzedAt':   analyzedAt.millisecondsSinceEpoch,
        'highlights':   jsonEncode(highlights.map((h) => h.toJson()).toList()),
        'verdictLabel': verdictLabel,
      };

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    List<TextHighlight> highlights = [];
    final rawHighlights = map['highlights'];
    if (rawHighlights != null &&
        rawHighlights is String &&
        rawHighlights.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawHighlights) as List<dynamic>;
        highlights = decoded
            .map((e) => TextHighlight.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        highlights = [];
      }
    }

    final isFake     = map['isFake'] == 1;
    final confidence = (map['confidence'] as num).toDouble();

    return ScanResult(
      id:           map['id'] as String,
      text:         map['text'] as String,
      isFake:       isFake,
      confidence:   confidence,
      timestamp:    DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      highlights:   highlights,
      fakeProb:     map['fakeProb'] != null
          ? (map['fakeProb'] as num).toDouble()
          : (isFake ? confidence : 1.0 - confidence),
      realProb:     map['realProb'] != null
          ? (map['realProb'] as num).toDouble()
          : (isFake ? 1.0 - confidence : confidence),
      analyzedAt:   map['analyzedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['analyzedAt'] as int)
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      verdictLabel: map['verdictLabel'] as String? ??
          (isFake ? 'FAKE' : 'REAL'),
    );
  }

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
    String? verdictLabel,
  }) =>
      ScanResult(
        id:           id           ?? this.id,
        text:         text         ?? this.text,
        isFake:       isFake       ?? this.isFake,
        confidence:   confidence   ?? this.confidence,
        timestamp:    timestamp    ?? this.timestamp,
        highlights:   highlights   ?? this.highlights,
        fakeProb:     fakeProb     ?? this.fakeProb,
        realProb:     realProb     ?? this.realProb,
        analyzedAt:   analyzedAt   ?? this.analyzedAt,
        verdictLabel: verdictLabel ?? this.verdictLabel,
      );

  @override
  List<Object?> get props => [
        id, text, isFake, confidence, timestamp,
        fakeProb, realProb, analyzedAt, highlights, verdictLabel,
      ];

  @override
  String toString() =>
      'ScanResult(id: $id, verdict: $verdictLabel, fakeProb: $fakeProb)';
}