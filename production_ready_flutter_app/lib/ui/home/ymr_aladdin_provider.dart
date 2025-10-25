import 'package:flutter/foundation.dart';

import '../../core/models/portfolio_models.dart';
import '../../services/ymr_aladdin_service.dart';

class YmrAladdinProvider extends ChangeNotifier {
  YmrAladdinProvider(this._service);

  final YmrAladdinService _service;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isProcessingCommand = false;
  String? _error;

  PortfolioSnapshot? _snapshot;
  RiskMetrics? _riskMetrics;
  List<ForecastInsight> _forecasts = const [];
  List<SimulationScenario> _simulations = const [];
  List<PersonalFinanceGoal> _goals = const [];
  List<BudgetCategory> _budget = const [];
  List<AutomationIntegration> _integrations = const [];
  List<TradeIdea> _tradeIdeas = const [];
  final List<AssistantMessage> _conversation = [
    const AssistantMessage(
      role: AssistantRole.assistant,
      content:
          'Welcome to YMR Aladdin+. Your portfolios, risk guardrails, and automation APIs are synced. Ask for optimizations, what-if scenarios, or broker executions anytime.',
      confidence: 0.9,
      supportingData: [
        'Data fabric: real-time feeds from market, news, and alternative sources',
        'Privacy: zero-trust encryption with local-first preferences',
      ],
    ),
  ];

  double _targetReturn = 0.08;
  RiskProfile _selectedRiskProfile = RiskProfile.moderate;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isProcessingCommand => _isProcessingCommand;
  String? get error => _error;
  PortfolioSnapshot? get snapshot => _snapshot;
  RiskMetrics? get riskMetrics => _riskMetrics;
  List<ForecastInsight> get forecasts => _forecasts;
  List<SimulationScenario> get simulations => _simulations;
  List<PersonalFinanceGoal> get goals => _goals;
  List<BudgetCategory> get budget => _budget;
  List<AutomationIntegration> get integrations => _integrations;
  List<TradeIdea> get tradeIdeas => _tradeIdeas;
  List<AssistantMessage> get conversation => List.unmodifiable(_conversation);
  double get targetReturn => _targetReturn;
  RiskProfile get selectedRiskProfile => _selectedRiskProfile;

  Future<void> initialize() async {
    final hasExistingData = _snapshot != null;
    if (!hasExistingData) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      _error = null;
      notifyListeners();
    }
    try {
      final snapshot = await _service.fetchPortfolioSnapshot();
      final risk = await _service.fetchRiskMetrics();
      final forecasts = await _service.fetchForecasts(snapshot);
      final goals = await _service.fetchGoals();
      final budget = await _service.fetchBudget();
      final integrations = await _service.fetchIntegrations();
      final ideas = await _service.fetchTradeIdeas(snapshot);
      final simulations = await _service.runSimulations(
        _targetReturn,
        _selectedRiskProfile,
        snapshot,
      );

      _snapshot = snapshot;
      _riskMetrics = risk;
      _forecasts = forecasts;
      _goals = goals;
      _budget = budget;
      _integrations = integrations;
      _tradeIdeas = ideas;
      _simulations = simulations;
    } catch (error, stack) {
      debugPrint('Failed to initialize dashboard: $error\n$stack');
      _error = 'Unable to load data. Please check your connection and retry.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      await initialize();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> runWhatIf({double? targetReturn, RiskProfile? profile}) async {
    if (_snapshot == null) return;
    _targetReturn = targetReturn ?? _targetReturn;
    _selectedRiskProfile = profile ?? _selectedRiskProfile;
    notifyListeners();
    final sims = await _service.runSimulations(
      _targetReturn,
      _selectedRiskProfile,
      _snapshot!,
    );
    _simulations = sims;
    notifyListeners();
  }

  Future<void> sendCommand(String command) async {
    if (command.trim().isEmpty) return;
    _conversation.add(AssistantMessage(role: AssistantRole.user, content: command.trim()));
    _isProcessingCommand = true;
    notifyListeners();
    try {
      final response = await _service.processCommand(
        command,
        _snapshot,
        _riskMetrics,
        _forecasts,
        _tradeIdeas,
      );
      _conversation.add(response);
    } catch (error, stack) {
      debugPrint('Command processing failed: $error\n$stack');
      _conversation.add(
        const AssistantMessage(
          role: AssistantRole.assistant,
          content: 'Something went wrong while processing that command. Please try again shortly.',
          confidence: 0.1,
        ),
      );
    } finally {
      _isProcessingCommand = false;
      notifyListeners();
    }
  }

  Future<void> toggleIntegration(String id, bool value) async {
    _integrations = _integrations
        .map(
          (integration) => integration.id == id
              ? integration.copyWith(
                  isConnected: value,
                  lastSync: DateTime.now(),
                  apiLatencyMs: value ? (integration.apiLatencyMs == 0 ? 250 : integration.apiLatencyMs) : 0,
                )
              : integration,
        )
        .toList();
    notifyListeners();
  }
}
