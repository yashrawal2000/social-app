import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/services/security/application_security_tool.dart';
import 'package:my_app/services/security/security_models.dart';
import 'package:my_app/services/security/security_repository.dart';

void main() {
  group('ApplicationSecurityTool', () {
    const repository = SecurityFindingRepository();
    const tool = ApplicationSecurityTool();

    const backendRequest = ScanRequest(
      platform: SecurityPlatform.backend,
      targetInput: 'https://app.example.com',
      credentialsProvided: true,
      enableStealthMode: true,
      enableAdvancedBypasses: true,
    );

    test('prioritises weaponised backend findings as true positives', () async {
      final backendFindings = await repository.fetchFindings(backendRequest);
      final report = tool.analyze(backendFindings, backendRequest);

      expect(report.truePositives, isNotEmpty);
      expect(report.truePositives.first.finding.id, equals('WEB-001'));
      expect(report.averageTruePositiveConfidence, greaterThan(0.7));
      expect(report.estimatedFalsePositiveRate, lessThan(0.5));
    });

    test('penalises weakly hardened Android findings for manual review', () async {
      const androidRequest = ScanRequest(
        platform: SecurityPlatform.android,
        targetInput: 'builds/app-release.apk',
        credentialsProvided: true,
        enableStealthMode: true,
        enableAdvancedBypasses: true,
      );
      final androidFindings = await repository.fetchFindings(androidRequest);
      final report = tool.analyze(androidFindings, androidRequest);

      final reviewIds = report.reviewCandidates.map((finding) => finding.finding.id).toSet();
      expect(reviewIds, contains('AND-310'));
      final debuggableFinding = report.reviewCandidates
          .firstWhere((finding) => finding.finding.id == 'AND-310');
      expect(debuggableFinding.confidence, lessThan(0.7));
    });

    test('surfaces exploited informational through critical findings for visibility', () async {
      final backendFindings = await repository.fetchFindings(backendRequest);
      final report = tool.analyze(backendFindings, backendRequest);

      final analysedIds = {
        ...report.truePositives.map((finding) => finding.finding.id),
        ...report.reviewCandidates.map((finding) => finding.finding.id),
      };

      expect(
        analysedIds,
        containsAll(<String>['WEB-001', 'API-077', 'WEB-120', 'WEB-130']),
      );

      final informationalFinding = (report.truePositives + report.reviewCandidates)
          .firstWhere((finding) => finding.finding.id == 'WEB-120');
      final lowSeverityFinding = (report.truePositives + report.reviewCandidates)
          .firstWhere((finding) => finding.finding.id == 'WEB-130');

      expect(
        informationalFinding.rationales.any(
          (rationale) => rationale.contains('Exploitability assessed as'),
        ),
        isTrue,
      );
      expect(
        lowSeverityFinding.rationales.any(
          (rationale) => rationale.contains('Exploitability assessed as'),
        ),
        isTrue,
      );

      const androidRequest = ScanRequest(
        platform: SecurityPlatform.android,
        targetInput: 'builds/app-release.apk',
        credentialsProvided: true,
        enableStealthMode: true,
        enableAdvancedBypasses: true,
      );
      final androidFindings = await repository.fetchFindings(androidRequest);
      final androidReport = tool.analyze(androidFindings, androidRequest);
      final androidAnalysedIds = {
        ...androidReport.truePositives.map((finding) => finding.finding.id),
        ...androidReport.reviewCandidates.map((finding) => finding.finding.id),
      };

      expect(androidAnalysedIds, contains('AND-201'));
      final highSeverityFinding = (androidReport.truePositives + androidReport.reviewCandidates)
          .firstWhere((finding) => finding.finding.id == 'AND-201');
      expect(
        highSeverityFinding.rationales.any(
          (rationale) => rationale.contains('Exploitability assessed as'),
        ),
        isTrue,
      );
    });

    test('reduces confidence when advanced bypasses and credentials are disabled', () async {
      const restrictedRequest = ScanRequest(
        platform: SecurityPlatform.backend,
        targetInput: 'https://app.example.com',
        credentialsProvided: false,
        enableStealthMode: true,
        enableAdvancedBypasses: false,
      );
      final restrictedFindings = await repository.fetchFindings(restrictedRequest);
      final restrictedReport = tool.analyze(restrictedFindings, restrictedRequest);

      final fullFindings = await repository.fetchFindings(backendRequest);
      final fullReport = tool.analyze(fullFindings, backendRequest);

      final restrictedSql = (restrictedReport.truePositives + restrictedReport.reviewCandidates)
          .firstWhere((finding) => finding.finding.id == 'WEB-001');
      final fullSql = (fullReport.truePositives + fullReport.reviewCandidates)
          .firstWhere((finding) => finding.finding.id == 'WEB-001');

      expect(restrictedSql.confidence, lessThan(fullSql.confidence));
    });

    test('evaluates ios hardening signals for ipa scans', () async {
      const iosRequest = ScanRequest(
        platform: SecurityPlatform.ios,
        targetInput: 'artifacts/app-store.ipa',
        credentialsProvided: true,
        enableStealthMode: true,
        enableAdvancedBypasses: true,
      );
      final iosFindings = await repository.fetchFindings(iosRequest);
      final iosReport = tool.analyze(iosFindings, iosRequest);

      expect(iosReport.truePositives.map((finding) => finding.finding.id), contains('IOS-420'));
      final keychainFinding = iosReport.truePositives.firstWhere((finding) => finding.finding.id == 'IOS-420');
      expect(keychainFinding.rationales.join(' '), contains('iOS hardening evaluated'));
    });
  });
}
