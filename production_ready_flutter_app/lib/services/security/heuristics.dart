import 'security_models.dart';

/// Represents the outcome of running a heuristic rule against a finding.
class HeuristicResult {
  const HeuristicResult({
    required this.score,
    required this.rationale,
  }) : assert(score >= 0 && score <= 1, 'score must be clamped between 0 and 1');

  final double score;
  final String rationale;
}

/// Heuristics generate a confidence score for a given finding.
abstract class HeuristicRule {
  const HeuristicRule();

  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request);
}

class EvidenceStrengthRule extends HeuristicRule {
  const EvidenceStrengthRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    if (finding.evidences.isEmpty) {
      return const HeuristicResult(
        score: 0.1,
        rationale: 'No supporting evidence attached to the finding.',
      );
    }
    final verified = finding.evidences.where((e) => e.verified).toList();
    final averageConfidence = finding.evidences
            .map((e) => e.weightedConfidence())
            .fold<double>(0, (sum, value) => sum + value) /
        finding.evidences.length;
    final double score;
    if (verified.length >= 2) {
      score = 0.95;
    } else if (verified.length == 1) {
      score = 0.8;
    } else if (finding.hasMultipleEvidenceTypes) {
      score = 0.65;
    } else {
      score = averageConfidence.clamp(0.1, 0.6);
    }
    return HeuristicResult(
      score: score,
      rationale:
          'Evidence strength evaluated with ${verified.length} verified artefacts (avg confidence ${(averageConfidence * 100).toStringAsFixed(0)}%).',
    );
  }
}

class ExploitabilityRule extends HeuristicRule {
  const ExploitabilityRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    double score = switch (finding.exploitMaturity) {
      ExploitMaturity.weaponized => 0.95,
      ExploitMaturity.proofOfConcept => 0.8,
      ExploitMaturity.theoretical => 0.55,
      ExploitMaturity.unknown => 0.4,
    };
    if (finding.isExternallyExploitable) {
      score += 0.05;
    }
    if (finding.hasManualValidation) {
      score += 0.05;
    }
    if (finding.metadata['compensatingControls'] == true) {
      score -= 0.1;
    }
    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale: 'Exploitability assessed as ${finding.exploitMaturity.name} with${finding.isExternallyExploitable ? '' : 'out'} external exposure.',
    );
  }
}

class ImpactRule extends HeuristicRule {
  const ImpactRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    final severityBoost = switch (finding.effectiveSeverity) {
      Severity.critical => 1.0,
      Severity.high => 0.85,
      Severity.medium => 0.6,
      Severity.low => 0.35,
      Severity.informational => 0.2,
    };
    double impact = severityBoost;
    if (finding.customerDataRisk) {
      impact += 0.1;
    }
    if (finding.affectedAssets > 10 || finding.affectedUsers > 1000) {
      impact += 0.05;
    }
    if (finding.tags.contains('crown-jewel')) {
      impact += 0.05;
    }
    return HeuristicResult(
      score: impact.clamp(0, 1),
      rationale:
          'Impact weighted by severity ${finding.effectiveSeverity.name} affecting ${finding.affectedAssets} assets and ${finding.affectedUsers} users.',
    );
  }
}

class NoiseReductionRule extends HeuristicRule {
  const NoiseReductionRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    double score = finding.scannerScore;
    if (finding.falsePositiveHistory) {
      score *= 0.5;
    }
    if (finding.hasManualValidation) {
      score += 0.25;
    }
    if (finding.metadata['previouslyRemediated'] == true) {
      score *= 0.7;
    }
    if (finding.isRecent) {
      score += 0.05;
    }
    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale:
          'Historical noise adjustment applied (manual validation: ${finding.hasManualValidation}, past false positive: ${finding.falsePositiveHistory}).',
    );
  }
}

class ContextualAssuranceRule extends HeuristicRule {
  const ContextualAssuranceRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    final bool hasSecurityControlGaps = finding.metadata['missingMonitoring'] == true;
    final bool businessCritical = finding.tags.contains('payments') || finding.tags.contains('auth');
    double score = 0.5;
    if (hasSecurityControlGaps) {
      score += 0.1;
    }
    if (businessCritical) {
      score += 0.15;
    }
    if (finding.metadata['runtimeProtection'] == true) {
      score -= 0.1;
    }
    if (finding.metadata['penTestMatch'] == true) {
      score += 0.2;
    }
    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale:
          'Contextual assurance adjusted for business tags ${finding.tags.join(', ')} and control coverage.',
    );
  }
}

class MobileHardeningRule extends HeuristicRule {
  const MobileHardeningRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    if (finding.platform != SecurityPlatform.android) {
      return const HeuristicResult(
        score: 0.5,
        rationale: 'Non-Android finding – neutral mobile hardening weighting applied.',
      );
    }

    double score = 0.45;
    final bool signedBuild = finding.metadata['signedBuild'] == true;
    final bool playIntegrity = finding.metadata['playIntegrity'] == true;
    final bool runtimeChecks = finding.metadata['runtimeSecurity'] == true;
    final bool debuggable = finding.metadata['debuggable'] == true;
    final bool allowsBackup = finding.metadata['allowsBackup'] == true;

    if (signedBuild) {
      score += 0.1;
    }
    if (playIntegrity) {
      score += 0.1;
    }
    if (runtimeChecks) {
      score += 0.05;
    }
    if (debuggable) {
      score -= 0.25;
    }
    if (allowsBackup) {
      score -= 0.1;
    } else {
      score += 0.05;
    }

    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale:
          'Android hardening evaluated (signed: $signedBuild, Play Integrity: $playIntegrity, debuggable: $debuggable).',
    );
  }
}

class IosHardeningRule extends HeuristicRule {
  const IosHardeningRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    if (finding.platform != SecurityPlatform.ios) {
      return const HeuristicResult(
        score: 0.5,
        rationale: 'Non-iOS finding – neutral mobile hardening weighting applied.',
      );
    }

    double score = 0.55;
    final bool jailbreakDetection = finding.metadata['jailbreakDetection'] == true;
    final bool secureEnclave = finding.metadata['secureEnclave'] == true;
    final bool deviceAttestation = finding.metadata['deviceAttestation'] == true;
    final bool allowsHttp = finding.metadata['allowsHttpTraffic'] == true;

    if (jailbreakDetection) {
      score += 0.1;
    }
    if (secureEnclave) {
      score += 0.1;
    }
    if (deviceAttestation) {
      score += 0.05;
    }
    if (allowsHttp) {
      score -= 0.2;
    }

    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale: 'iOS hardening evaluated (jailbreak detection: $jailbreakDetection, secure enclave: $secureEnclave).',
    );
  }
}

class BackendExposureRule extends HeuristicRule {
  const BackendExposureRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    if (finding.platform != SecurityPlatform.backend) {
      return const HeuristicResult(
        score: 0.5,
        rationale: 'Non-backend finding – neutral infrastructure exposure weighting applied.',
      );
    }

    double score = 0.6;
    final bool internetFacing = finding.metadata['internetFacing'] == true;
    final bool hasWaf = finding.metadata['hasWaf'] == true;
    final bool privilegedAccess = finding.metadata['privilegedAccess'] == true;
    final bool zeroTrust = finding.metadata['zeroTrustEnforced'] == true;

    if (internetFacing) {
      score += 0.15;
    }
    if (privilegedAccess) {
      score += 0.1;
    }
    if (hasWaf) {
      score -= 0.05;
    }
    if (zeroTrust) {
      score -= 0.05;
    }

    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale:
          'Backend exposure analysed (internet-facing: $internetFacing, privileged access: $privilegedAccess).',
    );
  }
}

class CredentialCoverageRule extends HeuristicRule {
  const CredentialCoverageRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    final bool requiresAuth = finding.metadata['requiresAuth'] == true;
    double score = requiresAuth ? 0.45 : 0.6;

    if (request.credentialsProvided && requiresAuth) {
      score += 0.3;
    }
    if (request.credentialsProvided && finding.metadata['deepParameterCoverage'] == true) {
      score += 0.1;
    }
    if (!request.credentialsProvided && requiresAuth) {
      score -= 0.15;
    }

    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale:
          'Credential coverage ${request.credentialsProvided ? 'enabled' : 'disabled'} for ${requiresAuth ? 'auth-required' : 'public'} endpoint.',
    );
  }
}

class AdvancedExploitationRule extends HeuristicRule {
  const AdvancedExploitationRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    double score = 0.55;
    final double modernTechniqueScore = (finding.metadata['modernTechniqueScore'] as double?) ?? 0.5;
    final bool wafBypassReady = finding.metadata['wafBypassReady'] == true;
    final bool parameterPollution = finding.metadata['parameterPollution'] == true;

    if (request.enableAdvancedBypasses && wafBypassReady) {
      score += 0.25;
    }
    if (request.enableAdvancedBypasses && parameterPollution) {
      score += 0.1;
    }
    if (!request.enableAdvancedBypasses && wafBypassReady) {
      score -= 0.1;
    }
    score += (modernTechniqueScore - 0.5);

    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale:
          'Advanced exploitation signals (WAF bypass: $wafBypassReady, modern score ${(modernTechniqueScore * 100).toStringAsFixed(0)}%).',
    );
  }
}

class StealthinessRule extends HeuristicRule {
  const StealthinessRule();

  @override
  HeuristicResult evaluate(SecurityFinding finding, ScanRequest request) {
    final double noiseLevel = (finding.metadata['noiseLevel'] as double?) ?? 0.5;
    double score = 0.6;

    if (request.enableStealthMode) {
      score += (0.5 - noiseLevel);
    } else {
      score += 0.05;
    }

    if (noiseLevel > 0.7 && request.enableStealthMode) {
      score -= 0.15;
    }

    return HeuristicResult(
      score: score.clamp(0, 1),
      rationale: 'Stealth profile ${(request.enableStealthMode ? 'low noise' : 'standard')} with observed noise ${(noiseLevel * 100).toStringAsFixed(0)}%.',
    );
  }
}
