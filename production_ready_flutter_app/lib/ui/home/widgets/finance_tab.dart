import 'package:flutter/material.dart';

import '../../../core/models/portfolio_models.dart';
import '../../shared/section_card.dart';

class FinanceTab extends StatelessWidget {
  const FinanceTab({
    super.key,
    required this.goals,
    required this.budget,
  });

  final List<PersonalFinanceGoal> goals;
  final List<BudgetCategory> budget;

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
