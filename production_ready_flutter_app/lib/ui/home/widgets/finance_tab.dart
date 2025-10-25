import 'package:flutter/material.dart';

import '../../../core/models/portfolio_models.dart';
import '../../shared/section_card.dart';

class FinanceTab extends StatelessWidget {
  const FinanceTab({
    super.key,
    required this.goals,
    required this.budget,
    this.taxOpportunities = const [],
    this.cashFlowProjection,
  });

  final List<PersonalFinanceGoal> goals;
  final List<BudgetCategory> budget;
  final List<TaxOptimizationOpportunity> taxOpportunities;
  final CashFlowProjection? cashFlowProjection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SectionCard(
            title: 'Goal Tracking',
            subtitle: 'Long-term goals with AI-powered savings milestones',
            child: Column(
              children: goals
                  .map(
                    (goal) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: _GoalTile(goal: goal),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (taxOpportunities.isNotEmpty)
            SectionCard(
              title: 'Tax Optimisation Radar',
              subtitle: 'Exact harvesting opportunities with estimated benefits and execution guidance',
              child: Column(
                children: taxOpportunities
                    .map(
                      (opportunity) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _TaxOpportunityTile(opportunity: opportunity),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (cashFlowProjection != null)
            SectionCard(
              title: 'Cash Flow Projection',
              subtitle: 'Six-month deterministic surplus model covering planned investments',
              child: _CashFlowView(projection: cashFlowProjection!),
            ),
          SectionCard(
            title: 'Budget Pulse',
            subtitle: 'Monthly budgets with sentiment and anomaly detection',
            child: Column(
              children: budget
                  .map(
                  (category) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.name, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (context) {
                                  final progress = category.utilization.clamp(0.0, 1.0);
                                  return LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: theme.colorScheme.surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation(
                                      category.utilization <= 1
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.error,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Spent ${category.spent.toStringAsFixed(0)} of ${category.allocated.toStringAsFixed(0)}${category.utilization > 1 ? ' · ${(category.utilization * 100 - 100).toStringAsFixed(0)}% over plan' : ''}',
                                style: theme.textTheme.bodySmall,
                              ),
                                const SizedBox(height: 4),
                                Text(category.sentiment),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Chip(
                            avatar: Icon(
                              category.utilization <= 1 ? Icons.check_circle : Icons.flag,
                              color: category.utilization <= 1
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                            label: Text(category.utilization <= 1 ? 'On Track' : 'Action Needed'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SectionCard(
            title: 'AI Nudges',
            subtitle: 'Personalised next actions to keep finances aligned',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nudge('Automate an extra 200 into Eco-home upgrade goal to stay on schedule.'),
                _nudge('Switch a portion of discretionary budget into emergency fund this month.'),
                _nudge('Upload recent tax documents to refresh quarterly optimisation.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nudge(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_circle, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final PersonalFinanceGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingYears = goal.targetDate.difference(DateTime.now()).inDays / 365;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Progress ${(goal.progress * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: goal.progress),
          const SizedBox(height: 12),
          Text('Current ${goal.currentAmount.toStringAsFixed(0)} · Target ${goal.targetAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Text('Time horizon ${remainingYears.toStringAsFixed(1)} years'),
        ],
      ),
    );
  }
}

class _TaxOpportunityTile extends StatelessWidget {
  const _TaxOpportunityTile({required this.opportunity});

  final TaxOptimizationOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.errorContainer.withOpacity(0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(opportunity.asset.symbol.substring(0, 2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${opportunity.asset.name}', style: theme.textTheme.titleMedium),
                    Text(
                      'Harvest ${opportunity.harvestAmount.toStringAsFixed(0)} · Benefit ${opportunity.estimatedBenefit.toStringAsFixed(0)} · Deadline ${_formatDate(opportunity.deadline)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(opportunity.action),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _CashFlowView extends StatelessWidget {
  const _CashFlowView({required this.projection});

  final CashFlowProjection projection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            Chip(
              avatar: const Icon(Icons.savings, size: 16),
              label: Text('Avg surplus ${projection.averageSurplus.toStringAsFixed(0)}'),
            ),
            Chip(
              avatar: const Icon(Icons.security, size: 16),
              label: Text('Coverage ${(projection.coverageRatio).toStringAsFixed(2)}×'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(projection.commentary, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Column(
          children: projection.points
              .map(
                (point) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_monthLabel(point.month)}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Expanded(
                        child: Text('Inflows ${point.inflows.toStringAsFixed(0)}'),
                      ),
                      Expanded(
                        child: Text('Outflows ${point.outflows.toStringAsFixed(0)}'),
                      ),
                      Chip(
                        avatar: Icon(
                          point.net >= 0 ? Icons.trending_up : Icons.warning_amber,
                          size: 16,
                          color: point.net >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                        ),
                        label: Text('${point.net >= 0 ? '+' : ''}${point.net.toStringAsFixed(0)}'),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _monthLabel(DateTime month) => '${month.month}/${month.year}';
}
