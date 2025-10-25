import 'package:flutter/material.dart';

import '../../../core/models/portfolio_models.dart';
import '../../shared/section_card.dart';

class ForecastTab extends StatelessWidget {
  const ForecastTab({
    super.key,
    required this.forecasts,
    required this.tradeIdeas,
    this.precisionForecasts = const [],
    this.researchInsights = const [],
    this.strategyPlaybooks = const [],
  });

  final List<ForecastInsight> forecasts;
  final List<TradeIdea> tradeIdeas;
  final List<PrecisionForecast> precisionForecasts;
  final List<ResearchInsight> researchInsights;
  final List<StrategyPlaybook> strategyPlaybooks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 900;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SectionCard(
            title: 'Predictive AI Outlook',
            subtitle: 'Hybrid ensembles forecasting equities, bonds, commodities, crypto, and cash',
            child: Column(
              children: forecasts
                  .map(
                    (forecast) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _ForecastRow(forecast: forecast),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (precisionForecasts.isNotEmpty)
            SectionCard(
              title: 'Deterministic Price Targets',
              subtitle: 'Exact path projections calibrated from stacked models with explainable drivers',
              child: Column(
                children: precisionForecasts
                    .map(
                      (forecast) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _PrecisionTile(forecast: forecast),
                      ),
                    )
                    .toList(),
              ),
            ),
          SectionCard(
            title: 'Explainable Recommendations',
            subtitle: 'Every action links to data drivers and model confidence',
            child: Column(
              children: tradeIdeas
                  .map(
                    (idea) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _TradeIdeaTile(idea: idea),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (researchInsights.isNotEmpty)
            SectionCard(
              title: 'Deep Research Radar',
              subtitle: 'Quant + AI diligence synthesised from multi-source intelligence',
              child: Column(
                children: researchInsights
                    .map(
                      (insight) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _ResearchTile(insight: insight),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (strategyPlaybooks.isNotEmpty)
            SectionCard(
              title: 'Strategy Playbooks',
              subtitle: 'Ready-to-execute asset allocation modules with quantified targets',
              child: Column(
                children: strategyPlaybooks
                    .map(
                      (playbook) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _PlaybookTile(playbook: playbook),
                      ),
                    )
                    .toList(),
              ),
            ),
          SectionCard(
            title: 'Signal Coverage',
            subtitle: 'Cross-check model consensus and alternative data alignment',
            child: isWide
                ? Row(
                    children: [
                      Expanded(child: _ConfidenceColumn(theme)),
                      const SizedBox(width: 24),
                      Expanded(child: _DriversColumn(theme, forecasts)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConfidenceColumn(theme),
                      const SizedBox(height: 24),
                      _DriversColumn(theme, forecasts),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ConfidenceColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Model Confidence', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ...forecasts.take(4).map(
          (forecast) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('${forecast.asset.symbol} · ${(forecast.expectedReturn * 100).toStringAsFixed(1)}% exp. return')),
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    value: forecast.confidence,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(forecast.confidence * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _DriversColumn(ThemeData theme, List<ForecastInsight> forecasts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Drivers', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        for (final driver in _collectDrivers(forecasts).entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.bolt, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(driver.key)),
                Text('${driver.value} assets'),
              ],
            ),
          ),
      ],
    );
  }

  Map<String, int> _collectDrivers(List<ForecastInsight> forecasts) {
    final counts = <String, int>{};
    for (final forecast in forecasts) {
      for (final driver in forecast.primaryDrivers) {
        counts.update(driver, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.forecast});

  final ForecastInsight forecast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          child: Text(forecast.asset.symbol.substring(0, 2)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                forecast.asset.name,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${forecast.asset.assetClass.label} · ${(forecast.expectedReturn * 100).toStringAsFixed(1)}% expected · ${(forecast.confidence * 100).toStringAsFixed(0)}% confidence',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: forecast.primaryDrivers
                    .map(
                      (driver) => Chip(
                        avatar: const Icon(Icons.analytics, size: 16),
                        label: Text(driver),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                forecast.recommendedAction,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 6),
              Text('Horizon ${forecast.holdingPeriodDays} days', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrecisionTile extends StatelessWidget {
  const _PrecisionTile({required this.forecast});

  final PrecisionForecast forecast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(forecast.asset.symbol.substring(0, 2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(forecast.asset.name, style: theme.textTheme.titleMedium),
                    Text(
                      'Now ${forecast.currentPrice.toStringAsFixed(2)} → Target ${forecast.projectedPrice.toStringAsFixed(2)} by ${_formatDate(forecast.horizon)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.trending_up, size: 16),
                          label: Text('${(forecast.relativeDelta * 100).toStringAsFixed(2)}% delta'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.rule, size: 16),
                          label: Text('Error ±${forecast.expectedError.toStringAsFixed(2)}'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.shield_outlined, size: 16),
                          label: Text('Confidence ${(forecast.confidence * 100).toStringAsFixed(0)}%'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Model stack: ${forecast.modelStack}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: forecast.rationales
                .map(
                  (rationale) => Chip(
                    avatar: const Icon(Icons.fact_check, size: 16),
                    label: Text(rationale),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TradeIdeaTile extends StatelessWidget {
  const _TradeIdeaTile({required this.idea});

  final TradeIdea idea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(idea.asset.symbol)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${idea.action} ${idea.asset.name}', style: theme.textTheme.titleMedium),
                    Text(
                      'Size ${idea.positionSizePct.toStringAsFixed(1)}% · Entry ${idea.entryPrice} · Stop ${idea.stopLoss}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: const Icon(Icons.verified_outlined, size: 16),
                label: Text('Confidence ${(idea.confidence * 100).toStringAsFixed(0)}%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(idea.rationale),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: idea.supportingEvidence
                .map((evidence) => Chip(
                      avatar: const Icon(Icons.data_exploration, size: 16),
                      label: Text(evidence),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ResearchTile extends StatelessWidget {
  const _ResearchTile({required this.insight});

  final ResearchInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(insight.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: insight.supportingSources
                .map(
                  (source) => Chip(
                    avatar: const Icon(Icons.analytics_outlined, size: 16),
                    label: Text(source),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Chip(
              avatar: const Icon(Icons.insights, size: 16),
              label: Text('Confidence ${(insight.confidence * 100).toStringAsFixed(0)}%'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybookTile extends StatelessWidget {
  const _PlaybookTile({required this.playbook});

  final StrategyPlaybook playbook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(playbook.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(playbook.objective, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.trending_up, size: 16),
                label: Text('Exp. return ${(playbook.expectedReturn * 100).toStringAsFixed(1)}%'),
              ),
              Chip(
                avatar: const Icon(Icons.security_outlined, size: 16),
                label: Text('Risk budget ${(playbook.riskBudget * 100).toStringAsFixed(1)}%'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: playbook.tactics
                .map(
                  (tactic) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tactic)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
