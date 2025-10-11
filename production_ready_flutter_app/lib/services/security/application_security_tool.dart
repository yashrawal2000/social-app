import 'dart:math' as math;

import 'heuristics.dart';
import 'security_models.dart';

/// High level orchestrator that runs a battery of heuristics to find true positives.
class ApplicationSecurityTool {
  const ApplicationSecurityTool({
    List<HeuristicRule>? heuristics,
    this.truePositiveThreshold = 0.7,
    this.highConfidenceThreshold = 0.85,
  }) : _heuristics = heuristics ?? const [
          EvidenceStrengthRule(),
          ExploitabilityRule(),
          ImpactRule(),
          NoiseReductionRule(),
          ContextualAssuranceRule(),
          MobileHardeningRule(),
          IosHardeningRule(),
          BackendExposureRule(),
          CredentialCoverageRule(),
          AdvancedExploitationRule(),
          StealthinessRule(),
        ];

  final List<HeuristicRule> _heuristics;
  final double truePositiveThreshold;
  final double highConfidenceThreshold;

  AnalysisReport analyze(List<SecurityFinding> findings, ScanRequest request) {
    if (findings.isEmpty) {
      return const AnalysisReport(
        truePositives: <EvaluatedFinding>[],
        reviewCandidates: <EvaluatedFinding>[],
        averageTruePositiveConfidence: 0,
        estimatedFalsePositiveRate: 0,
      );
    }

    final List<EvaluatedFinding> truePositives = [];
    final List<EvaluatedFinding> reviewCandidates = [];
    int suspectedFalsePositives = 0;

    for (final finding in findings) {
      final evaluation = _evaluateFinding(finding, request);
      if (evaluation.confidence >= truePositiveThreshold) {
        truePositives.add(evaluation);
      } else {
        reviewCandidates.add(evaluation);
        if (finding.falsePositiveHistory || finding.scannerScore < 0.35) {
          suspectedFalsePositives += 1;
        }
      }
    }

    final double averageConfidence;
    if (truePositives.isEmpty) {
      averageConfidence = 0;
    } else {
      averageConfidence = truePositives
              .map((finding) => finding.confidence)
              .fold<double>(0, (sum, value) => sum + value) /
          truePositives.length;
    }

    final estimatedFalsePositiveRate = suspectedFalsePositives / findings.length;

    truePositives.sort(_confidenceComparator);
    reviewCandidates.sort(_confidenceComparator);

    return AnalysisReport(
      truePositives: truePositives,
      reviewCandidates: reviewCandidates,
      averageTruePositiveConfidence: averageConfidence,
      estimatedFalsePositiveRate: estimatedFalsePositiveRate,
    );
  }

  EvaluatedFinding _evaluateFinding(SecurityFinding finding, ScanRequest request) {
    final List<String> rationales = [];
    double cumulativeScore = 0;

    for (final heuristic in _heuristics) {
      final result = heuristic.evaluate(finding, request);
      cumulativeScore += result.score;
      rationales.add(result.rationale);
    }

    final normalizedScore = cumulativeScore / _heuristics.length;
    final adjustedScore = math.min(1, normalizedScore + _bonusForHighSignal(finding, request));
    if (adjustedScore >= highConfidenceThreshold) {
      rationales.add(
        'Confidence surpasses ${(highConfidenceThreshold * 100).toStringAsFixed(0)}% automation threshold.',
      );
    }

    return EvaluatedFinding(
      finding: finding,
      confidence: adjustedScore,
      rationales: rationales,
    );
  }

  double _bonusForHighSignal(SecurityFinding finding, ScanRequest request) {
    double bonus = 0;
    if (finding.hasManualValidation && finding.hasStrongEvidence) {
      bonus += 0.05;
    }
    if (finding.customerDataRisk && finding.isExternallyExploitable) {
      bonus += 0.05;
    }
    if (finding.tags.contains('bug-bounty')) {
      bonus += 0.02;
    }
    if (finding.platform == SecurityPlatform.android &&
        finding.metadata['runtimeSecurity'] == true) {
      bonus += 0.03;
    }
    if (finding.platform == SecurityPlatform.backend &&
        finding.metadata['internetFacing'] == true &&
        finding.metadata['hasWaf'] != true) {
      bonus += 0.02;
    }
    if (finding.platform == SecurityPlatform.ios && finding.metadata['secureEnclave'] == true) {
      bonus += 0.03;
    }
    if (request.credentialsProvided && finding.metadata['requiresAuth'] == true) {
      bonus += 0.04;
    }
    if (request.enableAdvancedBypasses && finding.metadata['wafBypassReady'] == true) {
      bonus += 0.03;
    }
    if (request.enableStealthMode && ((finding.metadata['noiseLevel'] as double?) ?? 0.5) <= 0.3) {
      bonus += 0.02;
    }
    return bonus;
  }

  int _confidenceComparator(EvaluatedFinding a, EvaluatedFinding b) {
    final scoreComparison = b.confidence.compareTo(a.confidence);
    if (scoreComparison != 0) {
      return scoreComparison;
    }
    return b.finding.effectiveSeverity.index.compareTo(a.finding.effectiveSeverity.index);
  }
}
