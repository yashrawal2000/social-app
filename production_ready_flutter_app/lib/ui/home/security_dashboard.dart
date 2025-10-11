import 'package:flutter/material.dart';

import '../../services/security/security_analysis_service.dart';
import '../../services/security/security_models.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  final SecurityAnalysisService _service = const SecurityAnalysisService();
  late SecurityPlatform _selectedPlatform;
  late TextEditingController _targetController;
  late ScanRequest _currentRequest;
  late Future<AnalysisReport> _analysisFuture;
  bool _credentialsProvided = true;
  bool _stealthMode = true;
  bool _advancedBypasses = true;

  @override
  void initState() {
    super.initState();
    _selectedPlatform = SecurityPlatform.backend;
    _targetController = TextEditingController(text: _defaultTargetInput(_selectedPlatform));
    _currentRequest = _buildScanRequest();
    _analysisFuture = _service.analyse(_currentRequest);
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<AnalysisReport> _loadReport(ScanRequest request) {
    return _service.analyse(request);
  }

  ScanRequest _buildScanRequest() {
    return ScanRequest(
      platform: _selectedPlatform,
      targetInput: _targetController.text.trim(),
      credentialsProvided: _credentialsProvided,
      enableStealthMode: _stealthMode,
      enableAdvancedBypasses: _advancedBypasses,
    );
  }

  void _updatePlatform(SecurityPlatform platform) {
    if (_selectedPlatform == platform) {
      return;
    }
    final previousPlatform = _selectedPlatform;
    setState(() {
      _selectedPlatform = platform;
      if (_targetController.text.trim().isEmpty ||
          _targetController.text == _defaultTargetInput(previousPlatform)) {
        _targetController.text = _defaultTargetInput(platform);
      } else if (platform == SecurityPlatform.backend && !_targetController.text.startsWith('http')) {
        _targetController.text = _defaultTargetInput(platform);
      }
      _runScan();
    });
  }

  void _toggleCredentials(bool value) {
    setState(() {
      _credentialsProvided = value;
      _runScan();
    });
  }

  void _toggleStealth(bool value) {
    setState(() {
      _stealthMode = value;
      _runScan();
    });
  }

  void _toggleAdvanced(bool value) {
    setState(() {
      _advancedBypasses = value;
      _runScan();
    });
  }

  void _runScan() {
    _currentRequest = _buildScanRequest();
    _analysisFuture = _loadReport(_currentRequest);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnalysisReport>(
      future: _analysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load security posture: ${snapshot.error}'),
          );
        }

        final report = snapshot.data;
        if (report == null || !report.hasFindings) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final truePositives = report.truePositives;
        final reviewCandidates = report.reviewCandidates;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security analysis summary',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Automated heuristics promote verified, high-impact vulnerabilities and push noisy results for manual validation.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    _PlatformDropdown(
                      value: _selectedPlatform,
                      onChanged: _updatePlatform,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetController,
                  decoration: InputDecoration(
                    labelText: _selectedPlatform == SecurityPlatform.backend
                        ? 'Target URL'
                        : 'Binary path or bundle identifier',
                    hintText: _defaultTargetInput(_selectedPlatform),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Run deep scan',
                      onPressed: () {
                        setState(_runScan);
                      },
                    ),
                  ),
                  onSubmitted: (_) => setState(_runScan),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ScanToggleChip(
                      label: 'Use credentials',
                      selected: _credentialsProvided,
                      icon: Icons.vpn_key,
                      onSelected: (value) => _toggleCredentials(value),
                    ),
                    _ScanToggleChip(
                      label: 'Stealth mode',
                      selected: _stealthMode,
                      icon: Icons.nightlight_round,
                      onSelected: (value) => _toggleStealth(value),
                    ),
                    _ScanToggleChip(
                      label: 'Advanced bypasses',
                      selected: _advancedBypasses,
                      icon: Icons.shield,
                      onSelected: (value) => _toggleAdvanced(value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SummaryChip(
                      label: 'Platform',
                      value: _platformLabel(_selectedPlatform),
                      color: theme.colorScheme.primary,
                    ),
                    _SummaryChip(
                      label: 'Target',
                      value: _currentRequest.targetInput.isEmpty
                          ? 'Not provided'
                          : _currentRequest.targetInput,
                      color: theme.colorScheme.primary,
                    ),
                    _SummaryChip(
                      label: 'True positives',
                      value: truePositives.length.toString(),
                      color: theme.colorScheme.primary,
                    ),
                    _SummaryChip(
                      label: 'Needs triage',
                      value: reviewCandidates.length.toString(),
                      color: theme.colorScheme.tertiary,
                    ),
                    _SummaryChip(
                      label: 'Avg. confidence',
                      value: '${(report.averageTruePositiveConfidence * 100).toStringAsFixed(0)}%',
                      color: theme.colorScheme.secondary,
                    ),
                    _SummaryChip(
                      label: 'Est. false positive rate',
                      value: '${(report.estimatedFalsePositiveRate * 100).toStringAsFixed(0)}%',
                      color: theme.colorScheme.error,
                    ),
                    _SummaryChip(
                      label: 'Credentials',
                      value: _credentialsProvided ? 'Provided' : 'None',
                      color: theme.colorScheme.secondary,
                    ),
                    _SummaryChip(
                      label: 'Advanced bypasses',
                      value: _advancedBypasses ? 'On' : 'Off',
                      color: theme.colorScheme.tertiary,
                    ),
                    _SummaryChip(
                      label: 'Stealth',
                      value: _stealthMode ? 'Low noise' : 'Standard',
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
                if (truePositives.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Highest confidence vulnerabilities',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...truePositives.take(3).map(
                    (finding) => _FindingTile(
                      finding: finding,
                      subdued: false,
                    ),
                  ),
                ],
                if (reviewCandidates.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Findings held for analyst review',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...reviewCandidates.take(3).map(
                    (finding) => _FindingTile(
                      finding: finding,
                      subdued: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _platformLabel(SecurityPlatform platform) {
    switch (platform) {
      case SecurityPlatform.backend:
        return 'System';
      case SecurityPlatform.android:
        return 'Android';
      case SecurityPlatform.ios:
        return 'iOS';
    }
  }

  String _defaultTargetInput(SecurityPlatform platform) {
    switch (platform) {
      case SecurityPlatform.backend:
        return 'https://app.example.com';
      case SecurityPlatform.android:
        return 'builds/app-release.apk';
      case SecurityPlatform.ios:
        return 'artifacts/app-store.ipa';
    }
  }
}

class _PlatformDropdown extends StatelessWidget {
  const _PlatformDropdown({
    required this.value,
    required this.onChanged,
  });

  final SecurityPlatform value;
  final ValueChanged<SecurityPlatform> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SecurityPlatform>(
      value: value,
      onChanged: (platform) {
        if (platform != null) {
          onChanged(platform);
        }
      },
      items: SecurityPlatform.values
          .map(
            (platform) => DropdownMenuItem<SecurityPlatform>(
              value: platform,
              child: Text(_label(platform)),
            ),
          )
          .toList(),
    );
  }

  String _label(SecurityPlatform platform) {
    switch (platform) {
      case SecurityPlatform.backend:
        return 'System';
      case SecurityPlatform.android:
        return 'Android';
      case SecurityPlatform.ios:
        return 'iOS';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({
    required this.finding,
    required this.subdued,
  });

  final EvaluatedFinding finding;
  final bool subdued;

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _FindingDetailSheet(finding: finding);
      },
    );
  }

  Color _severityColor(BuildContext context, Severity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case Severity.critical:
        return colorScheme.error;
      case Severity.high:
        return colorScheme.error.withOpacity(0.8);
      case Severity.medium:
        return colorScheme.tertiary;
      case Severity.low:
        return colorScheme.secondary;
      case Severity.informational:
        return colorScheme.outline;
    }
  }

  String _severityLabel(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return 'Critical';
      case Severity.high:
        return 'High';
      case Severity.medium:
        return 'Medium';
      case Severity.low:
        return 'Low';
      case Severity.informational:
        return 'Informational';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityFinding = finding.finding;
    final color = _severityColor(context, securityFinding.effectiveSeverity);
    final cardColor = subdued
        ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
        : theme.colorScheme.surfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(securityFinding.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${securityFinding.id} · Severity: ${_severityLabel(securityFinding.effectiveSeverity)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surface: ${_platformName(securityFinding.platform)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(finding.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: theme.textTheme.labelLarge?.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${securityFinding.evidences.length} evidence signal(s)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...finding.rationales.take(2).map(
              (rationale) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user, size: 16, color: color.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rationale,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: color.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  'Tap for exploit, impact, and remediation details',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _platformName(SecurityPlatform platform) {
    switch (platform) {
      case SecurityPlatform.backend:
        return 'System';
      case SecurityPlatform.android:
        return 'Android';
      case SecurityPlatform.ios:
        return 'iOS';
    }
  }
}

class _ScanToggleChip extends StatelessWidget {
  const _ScanToggleChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _FindingDetailSheet extends StatelessWidget {
  const _FindingDetailSheet({required this.finding});

  final EvaluatedFinding finding;

  Color _severityColor(BuildContext context, Severity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case Severity.critical:
        return colorScheme.error;
      case Severity.high:
        return colorScheme.error.withOpacity(0.85);
      case Severity.medium:
        return colorScheme.tertiary;
      case Severity.low:
        return colorScheme.secondary;
      case Severity.informational:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = finding.finding;
    final severityColor = _severityColor(context, record.effectiveSeverity);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('ID ${record.id} · ${record.platform.name.toUpperCase()}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: severityColor.withOpacity(0.1),
                  label: Text(
                    record.effectiveSeverity.name.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(color: severityColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(record.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Impact',
              body: record.impact,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Recommendation',
              body: record.recommendation,
              icon: Icons.build_circle,
            ),
            const SizedBox(height: 12),
            _DetailListSection(
              title: 'Steps to reproduce',
              items: record.reproductionSteps,
              icon: Icons.format_list_numbered,
            ),
            const SizedBox(height: 12),
            _DetailListSection(
              title: 'Exploit techniques observed',
              items: record.exploitTechniques,
              icon: Icons.bug_report,
            ),
            const SizedBox(height: 16),
            Text('Why it was prioritised', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...finding.rationales.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified, size: 18, color: severityColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(reason, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(body, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailListSection extends StatelessWidget {
  const _DetailListSection({
    required this.title,
    required this.items,
    required this.icon,
  });

  final String title;
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(item, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
