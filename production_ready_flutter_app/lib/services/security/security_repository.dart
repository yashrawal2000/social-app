import 'dart:async';

import 'security_models.dart';

class SecurityFindingRepository {
  const SecurityFindingRepository();

  Future<List<SecurityFinding>> fetchFindings(ScanRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    switch (request.platform) {
      case SecurityPlatform.backend:
        return _backendFindings;
      case SecurityPlatform.android:
        return _androidFindings;
      case SecurityPlatform.ios:
        return _iosFindings;
    }
  }
}

final List<SecurityFinding> _backendFindings = [
  SecurityFinding(
    id: 'WEB-001',
    title: 'SQL injection in profile search endpoint',
    description:
        'The profile search API concatenates user input directly into SQL queries, enabling Boolean and time-based injection.',
    impact:
        'An attacker can extract credential hashes and session data for every customer, leading to full account compromise.',
    recommendation:
        'Migrate all search queries to parameterised statements, enforce least privilege on the database user, and deploy anomaly detection on slow queries.',
    reproductionSteps: const [
      'Authenticate with reviewer credentials or supplied test account.',
      'Send crafted payload GET /api/profile/search?query=admin%27%3BWAITFOR+DELAY+%270:0:05%27--.',
      'Observe the 5 second delay and the extracted table output in the response.',
    ],
    exploitTechniques: const [
      'Boolean-based SQL injection',
      'Time-based blind SQL injection',
      'WAF bypass using case manipulation',
    ],
    severity: Severity.critical,
    scannerScore: 0.92,
    exploitMaturity: ExploitMaturity.weaponized,
    platform: SecurityPlatform.backend,
    evidences: const [
      Evidence(
        type: EvidenceType.requestSample,
        description: 'Time-based injection producing a 5s delay.',
        verified: true,
        credibility: 0.9,
      ),
      Evidence(
        type: EvidenceType.exploitProof,
        description: 'curl payload extracting user table data.',
        verified: true,
        credibility: 0.95,
      ),
    ],
    hasManualValidation: true,
    isExternallyExploitable: true,
    customerDataRisk: true,
    affectedAssets: 4,
    affectedUsers: 2500,
    tags: const {'payments', 'bug-bounty'},
    lastObserved: DateTime.now().subtract(const Duration(days: 1)),
    metadata: const {
      'internetFacing': true,
      'hasWaf': false,
      'privilegedAccess': true,
      'penTestMatch': true,
      'requiresAuth': true,
      'deepParameterCoverage': true,
      'wafBypassReady': true,
      'modernTechniqueScore': 0.9,
      'parameterPollution': true,
      'noiseLevel': 0.2,
    },
  ),
  SecurityFinding(
    id: 'API-077',
    title: 'Verbose error handling reveals stack traces',
    description:
        'Malformed JSON triggers verbose exception handling that returns framework stack traces with file paths and secrets.',
    impact:
        'Disclosed stack traces accelerate exploit development and expose internal service topology for lateral movement.',
    recommendation:
        'Return generic error objects for unhandled exceptions, centralise logging, and mask secrets before responses are emitted.',
    reproductionSteps: const [
      'POST malformed JSON payload to /api/payments/report using provided analyst credentials.',
      'Capture HTTP 500 response including stack trace data.',
    ],
    exploitTechniques: const [
      'Verbose error disclosure',
      'Stack trace enumeration',
    ],
    severity: Severity.medium,
    scannerScore: 0.48,
    exploitMaturity: ExploitMaturity.proofOfConcept,
    platform: SecurityPlatform.backend,
    evidences: const [
      Evidence(
        type: EvidenceType.stackTrace,
        description: 'Stack trace returned when injecting malformed JSON.',
        verified: true,
        credibility: 0.6,
      ),
      Evidence(
        type: EvidenceType.logSnippet,
        description: 'Unhandled exception logged in production traces.',
        verified: false,
        credibility: 0.45,
      ),
    ],
    isExternallyExploitable: true,
    falsePositiveHistory: false,
    customerDataRisk: false,
    affectedAssets: 2,
    affectedUsers: 80,
    tags: const {'observability'},
    lastObserved: DateTime.now().subtract(const Duration(days: 16)),
    metadata: const {
      'internetFacing': true,
      'hasWaf': true,
      'missingMonitoring': true,
      'runtimeProtection': false,
      'requiresAuth': true,
      'deepParameterCoverage': true,
      'wafBypassReady': false,
      'modernTechniqueScore': 0.55,
      'noiseLevel': 0.35,
    },
  ),
  SecurityFinding(
    id: 'WEB-099',
    title: 'Reflected XSS flagged in marketing microsite',
    description:
        'Marketing microsite reflects unsanitised query parameters into the DOM without proper encoding, enabling script injection.',
    impact:
        'Attackers can steal session cookies of marketing administrators and deface public content.',
    recommendation:
        'Introduce strict output encoding, enable Content-Security-Policy, and standardise parameter validation across microsites.',
    reproductionSteps: const [
      'Browse to /promo?code=<script>alert(document.domain)</script>.',
      'Observe payload reflection in the DOM inspector.',
    ],
    exploitTechniques: const [
      'Reflected cross-site scripting',
      'CSP bypass enumeration',
    ],
    severity: Severity.medium,
    scannerScore: 0.32,
    exploitMaturity: ExploitMaturity.unknown,
    platform: SecurityPlatform.backend,
    evidences: const [
      Evidence(
        type: EvidenceType.requestSample,
        description: 'Encoded payload reflected in DOM without execution proof.',
        verified: false,
        credibility: 0.4,
      ),
    ],
    isExternallyExploitable: true,
    falsePositiveHistory: true,
    tags: const {'marketing'},
    lastObserved: DateTime.now().subtract(const Duration(days: 3)),
    metadata: const {
      'internetFacing': true,
      'hasWaf': true,
      'previouslyRemediated': true,
      'requiresAuth': false,
      'wafBypassReady': false,
      'modernTechniqueScore': 0.45,
      'noiseLevel': 0.4,
    },
  ),
  SecurityFinding(
    id: 'WEB-120',
    title: 'Server banner reveals outdated framework version',
    description:
        'HTTP response headers expose Express/4.17.1, which contains publicly documented remote code execution issues.',
    impact:
        'An attacker can chain known CVEs to escalate from banner disclosure to full server compromise.',
    recommendation:
        'Upgrade to the latest LTS build, strip banner headers at the load balancer, and monitor for known exploit signatures.',
    reproductionSteps: const [
      'Send GET request to /status endpoint.',
      'Review Server header showing Express/4.17.1.',
      'Launch provided PoC script to confirm vulnerable module presence.',
    ],
    exploitTechniques: const [
      'Fingerprinting outdated frameworks',
      'Chained CVE exploitation',
    ],
    severity: Severity.informational,
    scannerScore: 0.28,
    exploitMaturity: ExploitMaturity.proofOfConcept,
    platform: SecurityPlatform.backend,
    evidences: const [
      Evidence(
        type: EvidenceType.requestSample,
        description: 'curl response shows Express/4.17.1 header.',
        verified: true,
        credibility: 0.6,
      ),
      Evidence(
        type: EvidenceType.exploitProof,
        description: 'Proof-of-concept script enumerates vulnerable modules.',
        verified: false,
        credibility: 0.55,
      ),
    ],
    hasManualValidation: false,
    isExternallyExploitable: true,
    falsePositiveHistory: false,
    tags: const {'observability'},
    lastObserved: DateTime.now().subtract(const Duration(days: 5)),
    metadata: const {
      'internetFacing': true,
      'missingMonitoring': true,
      'runtimeProtection': false,
      'requiresAuth': false,
      'wafBypassReady': true,
      'modernTechniqueScore': 0.62,
      'noiseLevel': 0.25,
    },
  ),
  SecurityFinding(
    id: 'WEB-130',
    title: 'Clickjacking protection missing on support portal',
    description:
        'Support portal responses lack frame busting headers, allowing attackers to overlay UI and harvest credentials.',
    impact:
        'Successful attacks lead to credential theft for 4,500 support agents with access to customer data.',
    recommendation:
        'Set X-Frame-Options to DENY, implement CSP frame-ancestors, and roll out CSRF protections to sensitive forms.',
    reproductionSteps: const [
      'Host malicious page embedding support portal within an iframe.',
      'Lure victim to interact with overlaid buttons.',
    ],
    exploitTechniques: const [
      'Clickjacking',
      'Frame overlay attack',
    ],
    severity: Severity.low,
    scannerScore: 0.36,
    exploitMaturity: ExploitMaturity.proofOfConcept,
    platform: SecurityPlatform.backend,
    evidences: const [
      Evidence(
        type: EvidenceType.requestSample,
        description: 'X-Frame-Options header absent from response.',
        verified: true,
        credibility: 0.65,
      ),
      Evidence(
        type: EvidenceType.configuration,
        description: 'Load balancer policy missing frame-busting rules.',
        verified: false,
        credibility: 0.5,
      ),
    ],
    hasManualValidation: false,
    isExternallyExploitable: true,
    falsePositiveHistory: false,
    customerDataRisk: false,
    affectedAssets: 1,
    affectedUsers: 4500,
    tags: const {'support'},
    lastObserved: DateTime.now().subtract(const Duration(days: 7)),
    metadata: const {
      'internetFacing': true,
      'hasWaf': false,
      'previouslyRemediated': false,
      'requiresAuth': true,
      'deepParameterCoverage': false,
      'wafBypassReady': true,
      'modernTechniqueScore': 0.5,
      'noiseLevel': 0.3,
    },
  ),
];

final List<SecurityFinding> _androidFindings = [
  SecurityFinding(
    id: 'AND-201',
    title: 'WebView allows arbitrary file access',
    description:
        'Production WebView instance enables file access and JavaScript bridge invocation without origin validation.',
    impact:
        'Attackers can exfiltrate cached session tokens and escalate to remote code execution on rooted devices.',
    recommendation:
        'Disable file access, restrict JavaScript interfaces, and gate sensitive APIs behind device attestation checks.',
    reproductionSteps: const [
      'Install release APK on test device.',
      'Browse to attacker controlled page hosting exploit HTML.',
      'Trigger local file read through JavaScript interface.',
    ],
    exploitTechniques: const [
      'WebView file protocol abuse',
      'JavaScript interface exploitation',
      'Runtime instrumentation bypass',
    ],
    severity: Severity.high,
    scannerScore: 0.75,
    exploitMaturity: ExploitMaturity.proofOfConcept,
    platform: SecurityPlatform.android,
    evidences: const [
      Evidence(
        type: EvidenceType.configuration,
        description: 'setAllowFileAccess(true) detected in released build.',
        verified: true,
        credibility: 0.8,
      ),
      Evidence(
        type: EvidenceType.exploitProof,
        description: 'PoC demonstrates local file exfiltration.',
        verified: true,
        credibility: 0.85,
      ),
    ],
    hasManualValidation: true,
    customerDataRisk: true,
    affectedAssets: 1,
    affectedUsers: 52000,
    tags: const {'crown-jewel', 'mobile'},
    lastObserved: DateTime.now().subtract(const Duration(days: 6)),
    metadata: const {
      'signedBuild': true,
      'playIntegrity': true,
      'runtimeSecurity': true,
      'debuggable': false,
      'allowsBackup': false,
      'requiresAuth': true,
      'deepParameterCoverage': true,
      'wafBypassReady': true,
      'modernTechniqueScore': 0.8,
      'noiseLevel': 0.25,
    },
  ),
  SecurityFinding(
    id: 'AND-310',
    title: 'Debuggable flag enabled in production build',
    description:
        'Release manifest ships with android:debuggable="true", enabling runtime tampering and certificate pinning bypass.',
    impact:
        'Adversaries can attach debuggers to live sessions, inspect network traffic, and extract encryption keys.',
    recommendation:
        'Disable debuggable flag for production variants, enforce Play Integrity attestation, and obfuscate sensitive libraries.',
    reproductionSteps: const [
      'Install production APK.',
      'Use adb to attach debugger without rooting.',
      'Capture decrypted network payloads.',
    ],
    exploitTechniques: const [
      'Runtime debugging',
      'TLS interception',
    ],
    severity: Severity.high,
    scannerScore: 0.58,
    exploitMaturity: ExploitMaturity.proofOfConcept,
    platform: SecurityPlatform.android,
    evidences: const [
      Evidence(
        type: EvidenceType.configuration,
        description: 'AndroidManifest.xml contains android:debuggable="true".',
        verified: true,
        credibility: 0.7,
      ),
    ],
    hasManualValidation: false,
    isExternallyExploitable: true,
    customerDataRisk: true,
    affectedAssets: 1,
    affectedUsers: 52000,
    tags: const {'mobile', 'release'},
    lastObserved: DateTime.now().subtract(const Duration(days: 2)),
    metadata: const {
      'signedBuild': false,
      'playIntegrity': false,
      'runtimeSecurity': false,
      'debuggable': true,
      'allowsBackup': true,
      'requiresAuth': true,
      'deepParameterCoverage': false,
      'wafBypassReady': false,
      'modernTechniqueScore': 0.5,
      'noiseLevel': 0.45,
    },
  ),
  SecurityFinding(
    id: 'AND-145',
    title: 'Weak cryptography for credential storage',
    description:
        'User credentials are encrypted using AES/ECB with a static key packaged inside the APK assets.',
    impact:
        'Compromise results in offline credential recovery and potential reuse against backend services.',
    recommendation:
        'Adopt AES/GCM with per-device keys stored in hardware backed keystore and rotate credentials regularly.',
    reproductionSteps: const [
      'Decompile APK and extract static key.',
      'Use instrumentation script to dump encrypted preferences.',
      'Decrypt using static key to recover plaintext credentials.',
    ],
    exploitTechniques: const [
      'Static key extraction',
      'AES/ECB cryptanalysis',
    ],
    severity: Severity.medium,
    scannerScore: 0.4,
    exploitMaturity: ExploitMaturity.theoretical,
    platform: SecurityPlatform.android,
    evidences: const [
      Evidence(
        type: EvidenceType.logSnippet,
        description: 'AES/ECB identified in authentication module logs.',
        verified: true,
        credibility: 0.55,
      ),
      Evidence(
        type: EvidenceType.configuration,
        description: 'Static encryption key bundled with app assets.',
        verified: false,
        credibility: 0.5,
      ),
    ],
    hasManualValidation: false,
    isExternallyExploitable: false,
    customerDataRisk: true,
    affectedAssets: 1,
    affectedUsers: 52000,
    tags: const {'mobile', 'auth'},
    lastObserved: DateTime.now().subtract(const Duration(days: 11)),
    metadata: const {
      'signedBuild': true,
      'playIntegrity': true,
      'runtimeSecurity': false,
      'debuggable': false,
      'allowsBackup': true,
      'requiresAuth': true,
      'deepParameterCoverage': true,
      'wafBypassReady': false,
      'modernTechniqueScore': 0.48,
      'noiseLevel': 0.38,
    },
  ),
];

final List<SecurityFinding> _iosFindings = [
  SecurityFinding(
    id: 'IOS-420',
    title: 'Keychain items exposed to backup extraction',
    description:
        'The iOS build stores session tokens in a keychain access group marked as kSecAttrAccessibleAfterFirstUnlock, permitting iTunes backups to recover credentials.',
    impact:
        'Compromised backups allow attackers to hijack accounts and replay sessions across devices.',
    recommendation:
        'Move secrets to kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, enable Secure Enclave protection, and invalidate sessions on device restore.',
    reproductionSteps: const [
      'Install production IPA on test device.',
      'Perform encrypted iTunes backup.',
      'Use keychain dumper to extract session token from backup.',
    ],
    exploitTechniques: const [
      'Keychain backup extraction',
      'Session replay',
    ],
    severity: Severity.high,
    scannerScore: 0.7,
    exploitMaturity: ExploitMaturity.proofOfConcept,
    platform: SecurityPlatform.ios,
    evidences: const [
      Evidence(
        type: EvidenceType.configuration,
        description: 'Keychain access level flagged as after-first-unlock.',
        verified: true,
        credibility: 0.8,
      ),
      Evidence(
        type: EvidenceType.exploitProof,
        description: 'Backup dump reveals reusable session token.',
        verified: true,
        credibility: 0.85,
      ),
    ],
    hasManualValidation: true,
    isExternallyExploitable: false,
    customerDataRisk: true,
    affectedAssets: 1,
    affectedUsers: 26000,
    tags: const {'mobile', 'ios'},
    lastObserved: DateTime.now().subtract(const Duration(days: 4)),
    metadata: const {
      'jailbreakDetection': true,
      'secureEnclave': false,
      'deviceAttestation': false,
      'allowsHttpTraffic': false,
      'requiresAuth': true,
      'deepParameterCoverage': true,
      'wafBypassReady': false,
      'modernTechniqueScore': 0.65,
      'noiseLevel': 0.28,
    },
  ),
  SecurityFinding(
    id: 'IOS-515',
    title: 'ATS downgraded for legacy hosts',
    description:
        'App Transport Security exceptions permit HTTP traffic to legacy.example.com without TLS validation.',
    impact:
        'Network attackers can intercept credentials and serve malicious updates.',
    recommendation:
        'Remove ATS exceptions, enforce TLS 1.2+, and pin certificates for update channels.',
    reproductionSteps: const [
      'Proxy device traffic using provided credentials.',
      'Observe plain HTTP requests to legacy.example.com.',
      'Inject malicious response to demonstrate tampering.',
    ],
    exploitTechniques: const [
      'Man-in-the-middle interception',
      'TLS downgrade',
    ],
    severity: Severity.medium,
    scannerScore: 0.46,
    exploitMaturity: ExploitMaturity.proofOfConcept,
    platform: SecurityPlatform.ios,
    evidences: const [
      Evidence(
        type: EvidenceType.configuration,
        description: 'Info.plist allows arbitrary loads for legacy.example.com.',
        verified: true,
        credibility: 0.7,
      ),
      Evidence(
        type: EvidenceType.requestSample,
        description: 'Captured HTTP request reveals credentials in transit.',
        verified: true,
        credibility: 0.75,
      ),
    ],
    hasManualValidation: false,
    isExternallyExploitable: true,
    customerDataRisk: true,
    affectedAssets: 1,
    affectedUsers: 18000,
    tags: const {'ios', 'network'},
    lastObserved: DateTime.now().subtract(const Duration(days: 9)),
    metadata: const {
      'jailbreakDetection': false,
      'secureEnclave': true,
      'deviceAttestation': true,
      'allowsHttpTraffic': true,
      'requiresAuth': true,
      'deepParameterCoverage': true,
      'wafBypassReady': true,
      'modernTechniqueScore': 0.6,
      'noiseLevel': 0.33,
    },
  ),
  SecurityFinding(
    id: 'IOS-318',
    title: 'Insufficient jailbreak detection in sensitive module',
    description:
        'Security critical flows only check for jailbreak once at startup, allowing attackers to hook sensitive APIs afterwards.',
    impact:
        'Enables runtime instrumentation to bypass biometric gates and modify payment requests.',
    recommendation:
        'Perform continuous jailbreak detection, validate device integrity with attestation, and harden critical modules.',
    reproductionSteps: const [
      'Launch app on jailbroken device after bypassing initial detection.',
      'Attach Frida script to payment module.',
      'Modify transaction parameters and submit request.',
    ],
    exploitTechniques: const [
      'Jailbreak detection bypass',
      'Runtime instrumentation',
    ],
    severity: Severity.high,
    scannerScore: 0.62,
    exploitMaturity: ExploitMaturity.theoretical,
    platform: SecurityPlatform.ios,
    evidences: const [
      Evidence(
        type: EvidenceType.logSnippet,
        description: 'Runtime logs show detection only on launch.',
        verified: true,
        credibility: 0.6,
      ),
      Evidence(
        type: EvidenceType.exploitProof,
        description: 'Frida script demonstrates bypass after initial check.',
        verified: false,
        credibility: 0.55,
      ),
    ],
    hasManualValidation: false,
    isExternallyExploitable: false,
    customerDataRisk: true,
    affectedAssets: 1,
    affectedUsers: 18000,
    tags: const {'ios', 'auth'},
    lastObserved: DateTime.now().subtract(const Duration(days: 3)),
    metadata: const {
      'jailbreakDetection': false,
      'secureEnclave': true,
      'deviceAttestation': false,
      'allowsHttpTraffic': false,
      'requiresAuth': true,
      'deepParameterCoverage': false,
      'wafBypassReady': false,
      'modernTechniqueScore': 0.52,
      'noiseLevel': 0.29,
    },
  ),
];
