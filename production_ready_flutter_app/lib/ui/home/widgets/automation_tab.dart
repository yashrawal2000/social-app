import 'package:flutter/material.dart';

import '../../../core/models/portfolio_models.dart';
import '../../shared/section_card.dart';

class AutomationTab extends StatelessWidget {
  const AutomationTab({
    super.key,
    required this.integrations,
    required this.tradeIdeas,
    required this.onToggleIntegration,
  });

  final List<AutomationIntegration> integrations;
  final List<TradeIdea> tradeIdeas;
  final void Function(String id, bool value) onToggleIntegration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SectionCard(
            title: 'Broker Automations',
            subtitle: 'API health monitoring with one-click execution toggles',
            child: Column(
              children: integrations
                  .map(
                    (integration) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(integration.brokerName.substring(0, 2).toUpperCase()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${integration.brokerName} · ${integration.accountType}', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('Latency ${integration.apiLatencyMs} ms · Last sync ${_formatTimeAgo(integration.lastSync)}'),
                              ],
                            ),
                          ),
                          Switch(
                            value: integration.isConnected,
                            onChanged: (value) => onToggleIntegration(integration.id, value),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SectionCard(
            title: 'Automation Queue',
            subtitle: 'LLM-curated trades ready for approval and execution',
            child: Column(
              children: tradeIdeas
                  .map(
                    (idea) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _TradeAutomationTile(idea: idea),
                    ),
                  )
                  .toList(),
            ),
          ),
          SectionCard(
            title: 'Execution Safeguards',
            subtitle: 'Policy controls and audit trail for compliant automation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SafeguardPoint('Multi-factor approvals before orders leave the private cloud.'),
                _SafeguardPoint('Per-broker throttling and anomaly detection on fills.'),
                _SafeguardPoint('Immutable audit log mirrored to secure cold storage.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TradeAutomationTile extends StatelessWidget {
  const _TradeAutomationTile({required this.idea});

  final TradeIdea idea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
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
                    Text('Size ${idea.positionSizePct.toStringAsFixed(1)}% · Entry ${idea.entryPrice} · Stop ${idea.stopLoss}'),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Trade ticket for ${idea.asset.symbol} queued to connected brokers.'),
                    ),
                  );
                },
                child: const Text('Queue trade'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(idea.rationale),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: idea.supportingEvidence
                .map(
                  (evidence) => Chip(
                    avatar: const Icon(Icons.description_outlined, size: 16),
                    label: Text(evidence),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SafeguardPoint extends StatelessWidget {
  const _SafeguardPoint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.verified_user, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
