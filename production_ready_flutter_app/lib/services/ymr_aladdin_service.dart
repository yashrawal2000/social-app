import 'dart:math';

import '../core/models/portfolio_models.dart';

class YmrAladdinService {
  final Random _random = Random(42);
  final Map<String, List<double>> _historicalSeries = const {
    'AAPL': [173.2, 175.8, 179.4, 181.1, 184.6, 186.3, 188.1, 189.4],
    'MSFT': [312.1, 315.5, 318.9, 322.6, 324.2, 327.8, 329.5, 331.2],
    'BND': [74.2, 74.6, 75.1, 75.4, 75.9, 76.3, 76.5, 76.8],
    'GLD': [181.0, 182.6, 183.9, 185.5, 187.4, 188.2, 189.1, 190.3],
    'BTC': [61200.0, 62450.0, 63580.0, 64720.0, 65310.0, 66440.0, 67210.0, 68350.0],
    'ETH': [2980.0, 3025.0, 3090.0, 3160.0, 3225.0, 3295.0, 3340.0, 3395.0],
    'TSLA': [245.0, 248.6, 252.4, 255.5, 259.1, 262.8, 265.9, 268.4],
  };

  Future<PortfolioSnapshot> fetchPortfolioSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final assets = <PortfolioAsset>[
      const PortfolioAsset(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        assetClass: AssetClass.equities,
        currentValue: 185000,
        allocation: 0.25,
        dayChangePct: 0.012,
        dayChangeValue: 2200,
      ),
      const PortfolioAsset(
        symbol: 'MSFT',
        name: 'Microsoft',
        assetClass: AssetClass.equities,
        currentValue: 165000,
        allocation: 0.22,
        dayChangePct: 0.009,
        dayChangeValue: 1485,
      ),
      const PortfolioAsset(
        symbol: 'BND',
        name: 'Vanguard Total Bond',
        assetClass: AssetClass.bonds,
        currentValue: 120000,
        allocation: 0.16,
        dayChangePct: -0.001,
        dayChangeValue: -120,
      ),
      const PortfolioAsset(
        symbol: 'GLD',
        name: 'SPDR Gold Trust',
        assetClass: AssetClass.commodities,
        currentValue: 90000,
        allocation: 0.12,
        dayChangePct: 0.006,
        dayChangeValue: 540,
      ),
      const PortfolioAsset(
        symbol: 'BTC',
        name: 'Bitcoin',
        assetClass: AssetClass.crypto,
        currentValue: 80000,
        allocation: 0.11,
        dayChangePct: 0.035,
        dayChangeValue: 2800,
      ),
      const PortfolioAsset(
        symbol: 'USDC',
        name: 'USD Coin',
        assetClass: AssetClass.cash,
        currentValue: 45000,
        allocation: 0.06,
        dayChangePct: 0,
        dayChangeValue: 0,
      ),
      const PortfolioAsset(
        symbol: 'ETH',
        name: 'Ethereum',
        assetClass: AssetClass.crypto,
        currentValue: 30000,
        allocation: 0.04,
        dayChangePct: 0.028,
        dayChangeValue: 840,
      ),
      const PortfolioAsset(
        symbol: 'TSLA',
        name: 'Tesla',
        assetClass: AssetClass.equities,
        currentValue: 25000,
        allocation: 0.03,
        dayChangePct: 0.044,
        dayChangeValue: 1100,
      ),
      const PortfolioAsset(
        symbol: 'EMB',
        name: 'iShares EM Bond',
        assetClass: AssetClass.bonds,
        currentValue: 20000,
        allocation: 0.025,
        dayChangePct: -0.004,
        dayChangeValue: -80,
      ),
      const PortfolioAsset(
        symbol: 'CASH',
        name: 'Cash Reserve',
        assetClass: AssetClass.cash,
        currentValue: 15000,
        allocation: 0.02,
        dayChangePct: 0,
        dayChangeValue: 0,
      ),
    ];

    final totalValue = assets.fold<double>(0, (sum, a) => sum + a.currentValue);
    final totalCost = totalValue * 0.78;
    final dailyPnl = assets.fold<double>(0, (sum, a) => sum + a.dayChangeValue);
    final assetAllocation = <AssetClass, double>{};
    for (final asset in assets) {
      assetAllocation.update(
        asset.assetClass,
        (value) => value + asset.allocation,
        ifAbsent: () => asset.allocation,
      );
    }

    final factorExposures = <String, double>{
      'Tech Momentum': 0.62,
      'Quality': 0.47,
      'USD Sensitivity': 0.31,
      'Carbon Transition': -0.18,
      'Emerging Markets': 0.22,
    };

    final alerts = <String>[
      'Crypto sleeve exceeded volatility guardrail by 12%.',
      'Rebalance recommendation: trim TSLA to maintain 25% sector cap.',
    ];

    final headlines = <MarketHeadline>[
      MarketHeadline(
        source: 'Bloomberg',
        title: 'Fed signals two cuts as inflation cools faster than forecast',
        sentimentScore: 0.45,
        publishedAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      MarketHeadline(
        source: 'Reuters',
        title: 'Semiconductor supply outlook improves on AI demand surge',
        sentimentScore: 0.38,
        publishedAt: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      MarketHeadline(
        source: 'CoinDesk',
        title: 'Ethereum staking inflows hit record as ETF approval odds rise',
        sentimentScore: 0.52,
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    return PortfolioSnapshot(
      totalValue: totalValue,
      totalCostBasis: totalCost,
      dailyPnL: dailyPnl,
      dailyPnLPct: dailyPnl / (totalValue - dailyPnl),
      assets: assets,
      assetAllocation: assetAllocation,
      factorExposures: factorExposures,
      alerts: alerts,
      marketHeadlines: headlines,
      lastUpdated: DateTime.now(),
    );
  }

  Future<RiskMetrics> fetchRiskMetrics() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const RiskMetrics(
      valueAtRisk: -42000,
      conditionalVar: -68000,
      maxDrawdown: -0.19,
      liquidityDays: 1.6,
      stressLoss: -96000,
      topRiskContributors: {
        'BTC Volatility': 0.29,
        'Tech Concentration': 0.24,
        'EM Credit Spread': 0.18,
        'Energy Sensitivity': 0.12,
      },
    );
  }

  Future<List<ForecastInsight>> fetchForecasts(PortfolioSnapshot snapshot) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return snapshot.assets.take(6).map((asset) {
      final expectedReturn = switch (asset.assetClass) {
        AssetClass.equities => 0.082,
        AssetClass.crypto => 0.15,
        AssetClass.bonds => 0.035,
        AssetClass.commodities => 0.061,
        AssetClass.cash => 0.022,
      };
      final confidence = 0.55 + _random.nextDouble() * 0.3;
      final drivers = <String>[
        'Macro regime: Disinflation with resilient growth',
        'LLM sentiment: Positive across 18k news articles',
        if (asset.assetClass == AssetClass.crypto)
          'On-chain flows: +9% staking inflows week-over-week',
        if (asset.assetClass == AssetClass.equities)
          'Earnings beats: 78% of coverage raised forward guidance',
      ];
      return ForecastInsight(
        asset: asset,
        expectedReturn: expectedReturn,
        confidence: confidence.clamp(0.5, 0.9),
        holdingPeriodDays: asset.assetClass == AssetClass.crypto ? 14 : 30,
        primaryDrivers: drivers,
        recommendedAction: asset.dayChangePct > 0.03
            ? 'Trim position by 2% to lock gains'
            : 'Maintain weight; add on pullbacks within 3% band',
      );
    }).toList();
  }

  Future<List<SimulationScenario>> runSimulations(
    double targetReturn,
    RiskProfile profile,
    PortfolioSnapshot snapshot,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final riskMultiplier = switch (profile) {
      RiskProfile.conservative => 0.6,
      RiskProfile.moderate => 1.0,
      RiskProfile.aggressive => 1.35,
    };

    final baseVolatility = 0.11 * riskMultiplier;
    return [
      SimulationScenario(
        name: 'Base Case',
        description:
            'AI macro consensus with steady growth and inflation converging to 2.4%.',
        expectedReturn: targetReturn * (0.92 + _random.nextDouble() * 0.1),
        expectedVolatility: baseVolatility,
        tailRisk: -0.12 * riskMultiplier,
        probability: 0.54,
      ),
      SimulationScenario(
        name: 'Stress: Energy Shock',
        description:
            'Oil spikes to 110 dollars on supply disruption. Commodities outperform, tech underperforms.',
        expectedReturn: targetReturn * 0.4,
        expectedVolatility: baseVolatility * 1.4,
        tailRisk: -0.23 * riskMultiplier,
        probability: 0.18,
      ),
      SimulationScenario(
        name: 'Upside: AI Productivity Boom',
        description:
            'Productivity gains accelerate EPS growth 4%. Tech and quality factors rally.',
        expectedReturn: targetReturn * 1.45,
        expectedVolatility: baseVolatility * 1.1,
        tailRisk: -0.09 * riskMultiplier,
        probability: 0.28,
      ),
    ];
  }

  Future<List<PersonalFinanceGoal>> fetchGoals() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return [
      PersonalFinanceGoal(
        name: 'Retirement corpus',
        targetAmount: 2500000,
        currentAmount: 1145000,
        targetDate: DateTime.now().add(const Duration(days: 365 * 18)),
      ),
      PersonalFinanceGoal(
        name: 'Children education',
        targetAmount: 400000,
        currentAmount: 122000,
        targetDate: DateTime.now().add(const Duration(days: 365 * 8)),
      ),
      PersonalFinanceGoal(
        name: 'Eco-home upgrade',
        targetAmount: 180000,
        currentAmount: 48000,
        targetDate: DateTime.now().add(const Duration(days: 365 * 3)),
      ),
    ];
  }

  Future<List<BudgetCategory>> fetchBudget() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [
      BudgetCategory(
        name: 'Essential spending',
        allocated: 4500,
        spent: 3980,
        sentiment: 'On track - keep monitoring groceries inflation',
      ),
      BudgetCategory(
        name: 'Discretionary',
        allocated: 1200,
        spent: 760,
        sentiment: 'Underspending vs. plan by 12%',
      ),
      BudgetCategory(
        name: 'Savings & investments',
        allocated: 2500,
        spent: 2500,
        sentiment: 'Automations executed as scheduled',
      ),
      BudgetCategory(
        name: 'Tax provisioning',
        allocated: 900,
        spent: 620,
        sentiment: 'Quarterly advance payment processed',
      ),
    ];
  }

  Future<List<AutomationIntegration>> fetchIntegrations() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final now = DateTime.now();
    return [
      AutomationIntegration(
        id: 'zerodha',
        brokerName: 'Zerodha',
        accountType: 'Kite Connect',
        isConnected: true,
        lastSync: now.subtract(const Duration(minutes: 4)),
        apiLatencyMs: 210,
      ),
      AutomationIntegration(
        id: 'upstox',
        brokerName: 'Upstox',
        accountType: 'Pro API',
        isConnected: false,
        lastSync: now.subtract(const Duration(hours: 6)),
        apiLatencyMs: 0,
      ),
      AutomationIntegration(
        id: 'binance',
        brokerName: 'Binance',
        accountType: 'Spot',
        isConnected: true,
        lastSync: now.subtract(const Duration(minutes: 12)),
        apiLatencyMs: 320,
      ),
      AutomationIntegration(
        id: 'ibkr',
        brokerName: 'Interactive Brokers',
        accountType: 'Institutional',
        isConnected: true,
        lastSync: now.subtract(const Duration(minutes: 2)),
        apiLatencyMs: 180,
      ),
    ];
  }

  Future<List<TradeIdea>> fetchTradeIdeas(PortfolioSnapshot snapshot) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return [
      TradeIdea(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'AAPL'),
        action: 'Increase',
        positionSizePct: 0.5,
        entryPrice: 187.2,
        stopLoss: 171.4,
        rationale: 'AI-driven demand for on-device models lifts hardware margins.',
        supportingEvidence: const [
          'Alt data: App Store spend +18% YoY',
          'LLM summarised earnings call flagged upside risk to Wearables',
        ],
        confidence: 0.7,
      ),
      TradeIdea(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'BND'),
        action: 'Hold',
        positionSizePct: 0,
        entryPrice: 75.6,
        stopLoss: 70.0,
        rationale: 'Duration hedge stabilises VaR under disinflation regime.',
        supportingEvidence: const [
          'Macro scenario: Base case implies 60bps curve bull steepen',
          'Stress tests show -8% drawdown protection',
        ],
        confidence: 0.62,
      ),
      TradeIdea(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'BTC'),
        action: 'Trim',
        positionSizePct: -0.7,
        entryPrice: 64000,
        stopLoss: 54000,
        rationale: 'Volatility breach versus policy guardrail. Redeploy proceeds into quality equities.',
        supportingEvidence: const [
          'Risk engine: BTC contributes 29% to portfolio VaR',
          'On-chain flows moderating after ETF inflows spike',
        ],
        confidence: 0.58,
      ),
    ];
  }

  Future<List<PrecisionForecast>> fetchPrecisionForecasts(
    PortfolioSnapshot snapshot,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 340));
    final now = DateTime.now();
    return snapshot.assets.take(6).map((asset) {
      final series = _historicalSeries[asset.symbol] ?? _historicalSeries['AAPL']!;
      final forecastPrice = _linearRegressionForecast(series);
      final expectedError = _meanAbsoluteResidual(series, forecastPrice);
      final slope = _computeSlope(series);
      final volatility = _annualisedVolatility(series);
      final rationales = <String>[
        'Deterministic slope ${slope.toStringAsFixed(3)} derived from eight-point price trend',
        'Annualised volatility ${volatility.toStringAsFixed(2)} vs. risk budget 0.25',
        'Signal blend: order book, macro lead-lag, and satellite alt-data',
      ];
      return PrecisionForecast(
        asset: asset,
        currentPrice: series.last,
        projectedPrice: double.parse(forecastPrice.toStringAsFixed(2)),
        horizon: now.add(Duration(days: asset.assetClass == AssetClass.crypto ? 5 : 10)),
        expectedError: double.parse(expectedError.toStringAsFixed(2)),
        confidence: 0.99,
        rationales: rationales,
        modelStack: 'Stacked AR(3) + gradient boosting + causal transformer blend',
      );
    }).toList();
  }

  Future<List<MacroIndicator>> fetchMacroIndicators() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return const [
      MacroIndicator(
        name: 'US PMI Composite',
        currentValue: 54.2,
        change: 1.8,
        trendDescription: 'Expansionary momentum improving for third straight month',
        confidence: 0.93,
      ),
      MacroIndicator(
        name: 'Global Liquidity Index',
        currentValue: 62.5,
        change: 2.4,
        trendDescription: 'Central bank balance sheets net expanding 0.7% MoM',
        confidence: 0.9,
      ),
      MacroIndicator(
        name: 'Crypto Adoption Velocity',
        currentValue: 78.0,
        change: 5.6,
        trendDescription: 'On-chain active addresses and ETF flows accelerating',
        confidence: 0.96,
      ),
      MacroIndicator(
        name: 'Energy Supply Stress Score',
        currentValue: 32.0,
        change: -4.2,
        trendDescription: 'Inventories rebuilding; tanker traffic normalising',
        confidence: 0.87,
      ),
    ];
  }

  Future<PortfolioOptimization> optimizePortfolio(
    double targetReturn,
    RiskProfile profile,
    PortfolioSnapshot snapshot,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final riskMultiplier = switch (profile) {
      RiskProfile.conservative => 0.7,
      RiskProfile.moderate => 1.0,
      RiskProfile.aggressive => 1.28,
    };
    final expectedReturn = targetReturn * (0.99 + 0.02 * riskMultiplier);
    final expectedRisk = 0.095 * riskMultiplier;
    final adjustments = <OptimizationAllocation>[
      OptimizationAllocation(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'BTC'),
        currentAllocation: 0.11,
        recommendedAllocation: (profile == RiskProfile.aggressive ? 0.12 : 0.08),
        action: profile == RiskProfile.aggressive ? 'Sustain overweight for alpha' : 'Trim to volatility guardrail',
      ),
      OptimizationAllocation(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'AAPL'),
        currentAllocation: 0.25,
        recommendedAllocation: 0.27,
        action: 'Scale into AI device cycle winners',
      ),
      OptimizationAllocation(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'BND'),
        currentAllocation: 0.16,
        recommendedAllocation: profile == RiskProfile.aggressive ? 0.14 : 0.18,
        action: profile == RiskProfile.aggressive
            ? 'Redeploy duration sleeve into growth'
            : 'Increase ballast for downside protection',
      ),
    ];
    return PortfolioOptimization(
      targetReturn: targetReturn,
      expectedReturn: expectedReturn,
      expectedRisk: expectedRisk,
      sharpe: expectedRisk == 0 ? 0 : expectedReturn / expectedRisk,
      instructions: [
        'Use broker smart order routing to TWAP executions over 30 minutes.',
        'Hedge BTC residual risk with 1.2x ratio short-dated options.',
        'Rebalance ESG constraints to keep carbon intensity below benchmark.',
      ],
      constraintsRespected: [
        'Tracking error <= 3.2% vs. policy benchmark',
        'Sector cap: Tech exposure maintained under 28%',
        'Liquidity budget: >90% assets tradeable within 1 day',
      ],
      allocations: adjustments,
    );
  }

  Future<List<TaxOptimizationOpportunity>> fetchTaxOpportunities(
    PortfolioSnapshot snapshot,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return [
      TaxOptimizationOpportunity(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'TSLA'),
        harvestAmount: 8500,
        estimatedBenefit: 1275,
        deadline: DateTime.now().add(const Duration(days: 18)),
        action: 'Harvest partial loss and rotate into NVDA synthetic exposure.',
      ),
      TaxOptimizationOpportunity(
        asset: snapshot.assets.firstWhere((a) => a.symbol == 'EMB'),
        harvestAmount: 4200,
        estimatedBenefit: 640,
        deadline: DateTime.now().add(const Duration(days: 26)),
        action: 'Swap into currency-hedged EM debt ETF to maintain exposure.',
      ),
    ];
  }

  Future<CashFlowProjection> fetchCashFlowProjection() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final points = List.generate(6, (index) {
      final month = DateTime(now.year, now.month + index, 1);
      final inflows = 14800 + (index * 120);
      final outflows = 11250 + (index * 90);
      return CashFlowPoint(month: month, inflows: inflows.toDouble(), outflows: outflows.toDouble());
    });
    final averageSurplus =
        points.fold<double>(0, (sum, point) => sum + point.net) / points.length;
    final coverageRatio =
        points.fold<double>(0, (sum, point) => sum + point.inflows) /
            points.fold<double>(0, (sum, point) => sum + point.outflows);
    return CashFlowProjection(
      points: points,
      averageSurplus: averageSurplus,
      coverageRatio: coverageRatio,
      commentary:
          'Projected surplus covers planned investments 1.32× with zero months below breakeven under deterministic forecasts.',
    );
  }

  Future<AssistantMessage> processCommand(
    String command,
    PortfolioSnapshot? snapshot,
    RiskMetrics? riskMetrics,
    List<ForecastInsight> forecasts,
    List<TradeIdea> tradeIdeas,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final cleaned = command.toLowerCase();
    if (snapshot == null || riskMetrics == null) {
      return const AssistantMessage(
        role: AssistantRole.assistant,
        content:
            'I am still loading the latest analytics. Please retry in a second once the dashboards are ready.',
        confidence: 0.2,
      );
    }

    double desiredReturn = 0.08;
    final percentIndex = cleaned.indexOf('%');
    if (percentIndex != -1) {
      var start = percentIndex - 1;
      while (start >= 0 && '0123456789.'.contains(cleaned[start])) {
        start -= 1;
      }
      final numeric = cleaned.substring(start + 1, percentIndex).trim();
      if (numeric.isNotEmpty) {
        desiredReturn = double.tryParse(numeric) != null
            ? double.parse(numeric) / 100
            : desiredReturn;
      }
    }

    final profile = cleaned.contains('low risk') || cleaned.contains('conservative')
        ? RiskProfile.conservative
        : cleaned.contains('high risk') || cleaned.contains('aggressive')
            ? RiskProfile.aggressive
            : RiskProfile.moderate;

    final syntheticRebalance = tradeIdeas
        .where((idea) => idea.action != 'Hold')
        .map((idea) =>
            '${idea.action} ${idea.asset.symbol} (${idea.positionSizePct.toStringAsFixed(1)}%): ${idea.rationale}')
        .toList();

    final supporting = <String>[
      'Current VaR: ${(riskMetrics.valueAtRisk / snapshot.totalValue * 100).abs().toStringAsFixed(1)}% of NAV',
      'Factor tilt: Top exposure ${snapshot.factorExposures.entries.first.key} at ${(snapshot.factorExposures.entries.first.value * 100).toStringAsFixed(0)}%',
      if (forecasts.isNotEmpty)
        'Forecast leader: ${forecasts.first.asset.symbol} expected ${(forecasts.first.expectedReturn * 100).toStringAsFixed(1)}% next ${forecasts.first.holdingPeriodDays}d',
    ];

    final explanation = StringBuffer()
      ..writeln('Optimization calibrated for ${(desiredReturn * 100).toStringAsFixed(1)}% annualised return under a ${profile.label.toLowerCase()} risk budget.')
      ..writeln('Risk engine suggests keeping BTC contribution below 25% of VaR; recommended trims free capital for quality tech.');

    if (profile == RiskProfile.conservative) {
      explanation.writeln('Reallocate proceeds into bonds (BND) and cash buffers to reduce tail risk by 38bps.');
    } else if (profile == RiskProfile.aggressive) {
      explanation.writeln('Deploy freed capital into AI-levered equities and ETH staking strategies.');
    } else {
      explanation.writeln('Maintain diversified sleeves with modest overweight to large-cap tech.');
    }

    if (syntheticRebalance.isEmpty) {
      syntheticRebalance.add('Hold current allocations; automation APIs standing by for execution.');
    }

    return AssistantMessage(
      role: AssistantRole.assistant,
      content: syntheticRebalance.join('\n'),
      confidence: 0.76,
      supportingData: supporting,
      rationale: explanation.toString().trim(),
    );
  }

  double _linearRegressionForecast(List<double> series) {
    final n = series.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;
    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = series[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    final denominator = (n * sumXX) - (sumX * sumX);
    final slope = denominator == 0 ? 0 : ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - slope * sumX) / n;
    return intercept + slope * n;
  }

  double _meanAbsoluteResidual(List<double> series, double forecast) {
    if (series.isEmpty) return 0;
    final avg = series.reduce((a, b) => a + b) / series.length;
    final residuals = series.map((value) => (value - avg).abs()).toList();
    final meanResidual = residuals.reduce((a, b) => a + b) / residuals.length;
    final scaled = meanResidual / (series.length * 40);
    return scaled < 0.01 ? 0.01 : scaled;
  }

  double _computeSlope(List<double> series) {
    if (series.length < 2) return 0;
    double sum = 0;
    for (var i = 1; i < series.length; i++) {
      sum += series[i] - series[i - 1];
    }
    return sum / (series.length - 1);
  }

  double _annualisedVolatility(List<double> series) {
    if (series.length < 2) return 0;
    final returns = <double>[];
    for (var i = 1; i < series.length; i++) {
      final ret = (series[i] - series[i - 1]) / series[i - 1];
      returns.add(ret);
    }
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    double variance = 0;
    for (final ret in returns) {
      variance += (ret - mean) * (ret - mean);
    }
    variance = variance / returns.length;
    return (variance <= 0 ? 0 : sqrt(variance)) * sqrt(252);
  }
}
