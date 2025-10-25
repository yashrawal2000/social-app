import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/portfolio_models.dart';
import '../../l10n/app_localizations.dart';
import '../shared/locale_selector.dart';
import '../shared/section_card.dart';
import 'widgets/assistant_tab.dart';
import 'widgets/automation_tab.dart';
import 'widgets/finance_tab.dart';
import 'widgets/forecast_tab.dart';
import 'widgets/overview_tab.dart';
import 'ymr_aladdin_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<YmrAladdinProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<YmrAladdinProvider>();
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), label: 'Overview'),
      const NavigationDestination(icon: Icon(Icons.auto_awesome_motion), label: 'Forecasts'),
      const NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Assistant'),
      const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Finance'),
      const NavigationDestination(icon: Icon(Icons.api_outlined), label: 'Automation'),
    ];

    final body = _buildBody(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${loc.appTitle} · YMR Aladdin+'),
        actions: [
          if (provider.isRefreshing || provider.isProcessingCommand)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          IconButton(
            tooltip: 'Refresh data fabric',
            onPressed: provider.isRefreshing ? null : provider.refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: LocaleSelector(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? _ErrorState(message: provider.error!, onRetry: provider.initialize)
                : body,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: destinations,
      ),
    );
  }

  Widget _buildBody(YmrAladdinProvider provider) {
    switch (_selectedIndex) {
      case 0:
        final snapshot = provider.snapshot;
        final risk = provider.riskMetrics;
        if (snapshot == null || risk == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return OverviewTab(
          snapshot: snapshot,
          riskMetrics: risk,
          simulations: provider.simulations,
          onTargetReturnChanged: (value) => provider.runWhatIf(targetReturn: value),
          onRiskProfileChanged: (profile) => provider.runWhatIf(profile: profile),
          targetReturn: provider.targetReturn,
          selectedRiskProfile: provider.selectedRiskProfile,
        );
      case 1:
        return ForecastTab(
          forecasts: provider.forecasts,
          tradeIdeas: provider.tradeIdeas,
        );
      case 2:
        return AssistantTab(
          messages: provider.conversation,
          onSend: provider.sendCommand,
          isProcessing: provider.isProcessingCommand,
        );
      case 3:
        return FinanceTab(
          goals: provider.goals,
          budget: provider.budget,
        );
      case 4:
        return AutomationTab(
          integrations: provider.integrations,
          tradeIdeas: provider.tradeIdeas,
          onToggleIntegration: provider.toggleIntegration,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SectionCard(
        title: 'We could not reach your wealth brain',
        subtitle: 'Check connectivity or reload to continue.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
