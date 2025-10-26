import 'package:flutter/material.dart';

import '../../../core/models/portfolio_models.dart';
import '../../shared/section_card.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.snapshot,
    required this.riskMetrics,
    required this.simulations,
    required this.onTargetReturnChanged,
    required this.onRiskProfileChanged,
    required this.targetReturn,
    required this.selectedRiskProfile,
    this.optimization,
    this.macroIndicators = const [],
    this.platformCapabilities = const [],
  });

  final PortfolioSnapshot snapshot;
  final RiskMetrics riskMetrics;
  final List<SimulationScenario> simulations;
  final ValueChanged<double> onTargetReturnChanged;
  final ValueChanged<RiskProfile> onRiskProfileChanged;
  final double targetReturn;
  final RiskProfile selectedRiskProfile;
  final PortfolioOptimization? optimization;
  final List<MacroIndicator> macroIndicators;
  final List<PlatformCapability> platformCapabilities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MetricTile(
                    title: 'Net Asset Value',
                    value: _formatCurrency(snapshot.totalValue),
                    trend: '${(snapshot.dailyPnLPct * 100).toStringAsFixed(2)}% today',
                    icon: Icons.pie_chart_outline,
                    color: theme.colorScheme.primary,
                  ),
                  _MetricTile(
                    title: 'Net Profit',
                    value: _formatCurrency(snapshot.netProfit),
                    trend: '${(snapshot.netProfitPct * 100).toStringAsFixed(1)}% since inception',
                    icon: Icons.trending_up,
                    color: theme.colorScheme.secondary,
                  ),
                  _MetricTile(
                    title: 'Daily P&L',
                    value: _formatCurrency(snapshot.dailyPnL),
                    trend: snapshot.dailyPnL >= 0 ? 'In the green today' : 'Monitor downside',
                    icon: Icons.auto_graph,
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (snapshot.alerts.isNotEmpty)
                SectionCard(
                  title: 'Intelligent Alerts',
                  subtitle: 'Explainable guardrails across portfolios and automation rules',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.alerts
                        .map(
                          (alert) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.shield, color: theme.colorScheme.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    alert,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
              SectionCard(
                title: 'Asset Allocation',
                subtitle: 'Unified exposures across market, crypto, fixed income, and cash sleeves',
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildAllocationList(theme)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildFactorExposure(theme)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAllocationList(theme),
                          const SizedBox(height: 16),
                          _buildFactorExposure(theme),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              SectionCard(
                title: 'Risk Dashboard',
                subtitle: 'Real-time VaR, CVaR, stress losses, and liquidity metrics',
                child: _buildRiskMetrics(theme),
              ),
              const SizedBox(height: 8),
              if (optimization != null)
                SectionCard(
                  title: 'Deterministic Portfolio Optimization',
                  subtitle: 'Precise allocations matching target return with guardrails satisfied',
                  child: _buildOptimization(theme, optimization!),
                ),
              if (optimization != null) const SizedBox(height: 8),
              SectionCard(
                title: 'What-if Simulations',
                subtitle: 'Explore strategy paths with explainable Monte Carlo ensembles',
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Target return ${(targetReturn * 100).toStringAsFixed(1)}%'),
                    SizedBox(
                      width: isWide ? 260 : 200,
                      child: Slider(
                        value: targetReturn,
                        min: 0.04,
                        max: 0.16,
                        divisions: 12,
                        label: '${(targetReturn * 100).toStringAsFixed(1)}%',
                        onChanged: onTargetReturnChanged,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: RiskProfile.values
                          .map(
                            (profile) => ChoiceChip(
                              label: Text(profile.label),
                              selected: selectedRiskProfile == profile,
                              onSelected: (_) => onRiskProfileChanged(profile),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                child: _buildSimulations(theme),
              ),
              if (platformCapabilities.isNotEmpty) const SizedBox(height: 8),
              if (platformCapabilities.isNotEmpty)
                SectionCard(
                  title: 'Cross-platform Delivery',
                  subtitle: 'Mobile, web, and Windows builds share the same secure intelligence core',
                  child: Column(
                    children: platformCapabilities
                        .map(
                          (capability) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  capability.status.toLowerCase().contains('ready')
                                      ? Icons.check_circle_outline
                                      : Icons.devices_other,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(capability.platform, style: theme.textTheme.titleMedium),
                                      Text(
                                        capability.status,
                                        style: theme.textTheme.labelMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        capability.notes,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
              if (macroIndicators.isNotEmpty)
                SectionCard(
                  title: 'Macro Intelligence Matrix',
                  subtitle: 'Cross-asset signals calibrated from the global data fabric',
                  child: _buildMacroIndicators(theme),
                ),
              if (macroIndicators.isNotEmpty) const SizedBox(height: 8),
              SectionCard(
                title: 'Market Intelligence',
                subtitle: 'Streaming macro, alternative data, and sentiment narratives',
                child: Column(
                  children: snapshot.marketHeadlines
                      .map(
                        (headline) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              headline.source.substring(0, 2).toUpperCase(),
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          title: Text(headline.title),
                          subtitle: Text(
                            'Sentiment ${(headline.sentimentScore * 100).toStringAsFixed(0)}% · ${_formatTimeAgo(headline.publishedAt)}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptimization(ThemeData theme, PortfolioOptimization optimization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricTile(
              title: 'Expected return',
              value: '${(optimization.expectedReturn * 100).toStringAsFixed(2)}%',
              trend: 'Target ${(optimization.targetReturn * 100).toStringAsFixed(1)}%',
              icon: Icons.trending_up,
              color: theme.colorScheme.primary,
            ),
            _MetricTile(
              title: 'Expected risk',
              value: '${(optimization.expectedRisk * 100).toStringAsFixed(2)}%',
              trend: 'Sharpe ${(optimization.sharpe).toStringAsFixed(2)}',
              icon: Icons.stacked_line_chart,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Execution playbook', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...optimization.instructions.map(
          (instruction) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(instruction)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Constraints satisfied', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...optimization.constraintsRespected.map(
          (constraint) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(child: Text(constraint)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Allocation adjustments', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...optimization.allocations.map(
          (allocation) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CircleAvatar(child: Text(allocation.asset.symbol.substring(0, 2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(allocation.asset.name, style: theme.textTheme.titleMedium),
                      Text(
                        'Current ${(allocation.currentAllocation * 100).toStringAsFixed(1)}% → Target ${(allocation.recommendedAllocation * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(allocation.action),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  allocation.delta >= 0
                      ? '+${(allocation.delta * 100).toStringAsFixed(1)}%'
                      : '${(allocation.delta * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroIndicators(ThemeData theme) {
    return Column(
      children: macroIndicators
          .map(
            (indicator) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.public, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(indicator.name, style: theme.textTheme.titleMedium),
                        Text(
                          'Value ${indicator.currentValue.toStringAsFixed(1)} (${indicator.change >= 0 ? '+' : ''}${indicator.change.toStringAsFixed(1)})',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(indicator.trendDescription),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Confidence ${(indicator.confidence * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAllocationList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: snapshot.assetAllocation.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15 + entry.value * 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text('${entry.key.label} · ${(entry.value * 100).toStringAsFixed(1)}%'),
                  ),
                  Text(_formatCurrency(snapshot.totalValue * entry.value)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFactorExposure(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: snapshot.factorExposures.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: entry.value.abs().clamp(0, 1),
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(
                        entry.value >= 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value >= 0
                        ? '+${(entry.value * 100).toStringAsFixed(1)}% tilt'
                        : '-${(entry.value.abs() * 100).toStringAsFixed(1)}% tilt',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRiskMetrics(ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _RiskTile(
          label: 'Value at Risk (95%)',
          value: _formatCurrency(riskMetrics.valueAtRisk),
          caption: 'Daily 95% confidence loss',
          icon: Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
        ),
        _RiskTile(
          label: 'Conditional VaR',
          value: _formatCurrency(riskMetrics.conditionalVar),
          caption: 'Expected loss beyond VaR',
          icon: Icons.crisis_alert,
          color: theme.colorScheme.errorContainer,
        ),
        _RiskTile(
          label: 'Max Drawdown',
          value: '${(riskMetrics.maxDrawdown * 100).toStringAsFixed(1)}%',
          caption: 'From peak to trough',
          icon: Icons.ssid_chart,
          color: theme.colorScheme.tertiaryContainer,
        ),
        _RiskTile(
          label: 'Liquidity runway',
          value: '${riskMetrics.liquidityDays.toStringAsFixed(1)} days',
          caption: 'To exit 95% of NAV',
          icon: Icons.timelapse,
          color: theme.colorScheme.primaryContainer,
        ),
      ],
    );
  }

  Widget _buildSimulations(ThemeData theme) {
    return Column(
      children: simulations
          .map(
            (scenario) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text('${(scenario.probability * 100).round()}%'),
                ),
                title: Text(scenario.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.description),
                    const SizedBox(height: 4),
                    Text(
                      'Return ${(scenario.expectedReturn * 100).toStringAsFixed(1)}% · Vol ${(scenario.expectedVolatility * 100).toStringAsFixed(1)}% · Tail ${(scenario.tailRisk * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatCurrency(double value) {
    const symbol = r'$';
    final sign = value < 0 ? '-' : '';
    final amount = value.abs();
    if (amount >= 1000000) {
      return '$sign$symbol${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '$sign$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$sign$symbol${amount.toStringAsFixed(0)}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(trend, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  const _RiskTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
