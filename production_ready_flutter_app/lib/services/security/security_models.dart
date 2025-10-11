import 'package:flutter/foundation.dart';

/// Represents the severity of a vulnerability reported by an upstream scanner.
enum Severity {
  informational,
  low,
  medium,
  high,
  critical,
}

/// The runtime surface where a vulnerability was identified.
enum SecurityPlatform {
  backend,
  android,
  ios,
}

/// Captures the maturity of an exploit that supports a finding.
enum ExploitMaturity {
  unknown,
  theoretical,
  proofOfConcept,
  weaponized,
}

/// Describes how the automated tooling should approach a scan.
class ScanRequest {
  const ScanRequest({
    required this.platform,
    required this.targetInput,
    this.credentialsProvided = false,
    this.enableStealthMode = true,
    this.enableAdvancedBypasses = true,
  });

  final SecurityPlatform platform;
  final String targetInput;
  final bool credentialsProvided;
  final bool enableStealthMode;
  final bool enableAdvancedBypasses;

  bool get targetsMobile => platform == SecurityPlatform.android || platform == SecurityPlatform.ios;
}

/// Describes a single piece of evidence provided for a vulnerability.
class Evidence {
  const Evidence({
    required this.type,
    required this.description,
    this.verified = false,
    this.credibility = 0.5,
  }) : assert(credibility >= 0 && credibility <= 1, 'credibility must be between 0 and 1');

  final EvidenceType type;
  final String description;
  final bool verified;
  final double credibility;

  /// Returns a weighted score that captures how trustworthy the evidence is.
  double weightedConfidence() {
    final base = credibility;
    return verified ? (0.6 + (base * 0.4)) : (base * 0.6);
  }
}

/// Categorises the type of evidence that was supplied.
enum EvidenceType {
  packetCapture,
  requestSample,
  stackTrace,
  logSnippet,
  exploitProof,
  configuration,
}

/// Structured representation of a scanner finding enriched with manual signals.
class SecurityFinding {
  const SecurityFinding({
    required this.id,
    required this.title,
    required this.description,
    required this.impact,
    required this.recommendation,
    required this.reproductionSteps,
    required this.exploitTechniques,
    required this.severity,
    required this.scannerScore,
    required this.evidences,
    required this.exploitMaturity,
    required this.platform,
    this.tags = const <String>{},
    this.falsePositiveHistory = false,
    this.hasManualValidation = false,
    this.isExternallyExploitable = false,
    this.customerDataRisk = false,
    this.affectedAssets = 0,
    this.affectedUsers = 0,
    this.lastObserved,
    this.metadata = const <String, Object?>{},
  })  : assert(scannerScore >= 0 && scannerScore <= 1, 'scannerScore must be between 0 and 1'),
        assert(reproductionSteps.isNotEmpty, 'reproductionSteps must contain at least one step'),
        assert(exploitTechniques.isNotEmpty, 'exploitTechniques must contain at least one technique'),
        assert(affectedAssets >= 0, 'affectedAssets cannot be negative'),
        assert(affectedUsers >= 0, 'affectedUsers cannot be negative');

  final String id;
  final String title;
  final String description;
  final String impact;
  final String recommendation;
  final List<String> reproductionSteps;
  final List<String> exploitTechniques;
  final Severity severity;
  final double scannerScore;
  final List<Evidence> evidences;
  final ExploitMaturity exploitMaturity;
  final SecurityPlatform platform;
  final Set<String> tags;
  final bool falsePositiveHistory;
  final bool hasManualValidation;
  final bool isExternallyExploitable;
  final bool customerDataRisk;
  final int affectedAssets;
  final int affectedUsers;
  final DateTime? lastObserved;
  final Map<String, Object?> metadata;

  bool get hasStrongEvidence => evidences.any((e) => e.verified && e.credibility >= 0.6);

  bool get hasMultipleEvidenceTypes {
    final types = evidences.map((e) => e.type).toSet();
    return types.length >= 2;
  }

  bool get isBackend => platform == SecurityPlatform.backend;

  bool get isAndroid => platform == SecurityPlatform.android;

  bool get isIos => platform == SecurityPlatform.ios;

  bool get isRecent {
    if (lastObserved == null) {
      return false;
    }
    final difference = DateTime.now().difference(lastObserved!);
    return difference.inDays <= 14;
  }

  Severity get effectiveSeverity {
    if (customerDataRisk && severity == Severity.high) {
      return Severity.critical;
    }
    return severity;
  }

  /// Provides a short machine friendly snapshot of core signals.
  @override
  String toString() {
    return 'SecurityFinding(id: $id, platform: $platform, severity: $severity, '
        'score: $scannerScore, evidence: ${evidences.length}, '
        'exploitTechniques: ${exploitTechniques.length})';
  }
}

/// Wraps a finding with the derived confidence and a textual explanation.
@immutable
class EvaluatedFinding {
  const EvaluatedFinding({
    required this.finding,
    required this.confidence,
    required this.rationales,
  }) : assert(confidence >= 0 && confidence <= 1, 'confidence must be between 0 and 1');

  final SecurityFinding finding;
  final double confidence;
  final List<String> rationales;

  EvaluatedFinding copyWith({
    double? confidence,
    List<String>? rationales,
  }) {
    return EvaluatedFinding(
      finding: finding,
      confidence: confidence ?? this.confidence,
      rationales: rationales ?? this.rationales,
    );
  }
}

/// Aggregated result produced by the security analyser.
@immutable
class AnalysisReport {
  const AnalysisReport({
    required this.truePositives,
    required this.reviewCandidates,
    required this.averageTruePositiveConfidence,
    required this.estimatedFalsePositiveRate,
  });

  final List<EvaluatedFinding> truePositives;
  final List<EvaluatedFinding> reviewCandidates;
  final double averageTruePositiveConfidence;
  final double estimatedFalsePositiveRate;

  bool get hasFindings => truePositives.isNotEmpty || reviewCandidates.isNotEmpty;
}
